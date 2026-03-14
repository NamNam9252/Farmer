import { Request } from "express";
import {
  AssetStatus,
  BidStatus,
  PrismaClient,
  RentalStatus,
} from "@prisma/client";
import {
  CreateAssetSchema,
  ListAssetsSchema,
  PlaceBidSchema,
  UpdateAssetSchema,
} from "../../schema/rental.schema";
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from "../../core/errors/custom.error";
import * as NotificationService from "../notifications/notification.service.js";

const prisma = new PrismaClient();

export class RentalService {
  async createAsset(req: Request) {
    const { user, body } = req as any;
    const data = CreateAssetSchema.parse(body);
    return prisma.asset.create({
      data: { ownerId: user!.id, ...data },
    });
  }

  async listAssets(req: Request) {
    const { page, limit, type, status, minPrice, maxPrice } =
      ListAssetsSchema.parse(req.query);
    const skip = (page - 1) * limit;
    const where: Record<string, unknown> = {};
    if (type) where.type = type;
    if (status) where.status = status;
    if (minPrice != null || maxPrice != null) {
      where.basePrice = {
        ...(minPrice != null ? { gte: minPrice } : {}),
        ...(maxPrice != null ? { lte: maxPrice } : {}),
      };
    }

    const [assets, total] = await Promise.all([
      prisma.asset.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          owner: { select: { id: true, email: true } },
          _count: { select: { bids: true } },
        },
      }),
      prisma.asset.count({ where }),
    ]);
    return { assets, total, page, limit };
  }

  async getAsset(req: Request<any>) {
    const asset = await prisma.asset.findUnique({
      where: { id: req.params.assetId },
      include: {
        owner: { select: { id: true, email: true } },
        bids: {
          orderBy: { amount: "desc" },
          include: { bidder: { select: { id: true, email: true } } },
        },
        rental: { include: { tenant: { select: { id: true, email: true } } } },
      },
    });
    if (!asset) throw new NotFoundError("Asset not found");
    return asset;
  }

  async updateAsset(req: Request) {
    const { user, body, params } = req as any;
    const data = UpdateAssetSchema.parse(body);
    const asset = await prisma.asset.findUnique({
      where: { id: params.assetId },
    });
    if (!asset) throw new NotFoundError("Asset not found");
    if (asset.ownerId !== user!.id) throw new ForbiddenError("Forbidden");
    if (asset.status === AssetStatus.LOCKED)
      throw new ConflictError("Cannot edit a locked asset");
    return prisma.asset.update({ where: { id: params.assetId }, data });
  }

  async deleteAsset(req: Request) {
    const { user, params } = req as any;
    const asset = await prisma.asset.findUnique({
      where: { id: params.assetId },
    });
    if (!asset) throw new NotFoundError("Asset not found");
    if (asset.ownerId !== user!.id) throw new ForbiddenError("Forbidden");
    if (asset.status === AssetStatus.LOCKED)
      throw new ConflictError("Cannot delete a locked asset");
    await prisma.bid.updateMany({
      where: { assetId: params.assetId, status: BidStatus.PENDING },
      data: { status: BidStatus.REJECTED },
    });
    return prisma.asset.delete({ where: { id: params.assetId } });
  }

  async placeBid(req: Request) {
    const { user, body, params } = req as any;
    const data = PlaceBidSchema.parse(body);
    const assetId = params.assetId;
    const asset = await prisma.asset.findUnique({ where: { id: assetId } });
    if (!asset) throw new NotFoundError("Asset not found");
    if (asset.status !== AssetStatus.AVAILABLE)
      throw new ConflictError("Asset is not available for bidding");
    if (asset.ownerId === user!.id)
      throw new ConflictError("You cannot bid on your own asset");

    const existing = await prisma.bid.findFirst({
      where: { assetId, bidderId: user!.id, status: BidStatus.PENDING },
    });
    if (existing)
      throw new ConflictError("You already have a pending bid on this asset");

    const bid = await prisma.bid.create({
      data: {
        assetId,
        bidderId: user!.id,
        amount: data.amount,
        startDate: new Date(data.startDate),
        endDate: new Date(data.endDate),
        message: data.message,
      },
      include: { bidder: { select: { id: true, email: true } } },
    });

    // Notify Owner
    try {
      await NotificationService.createNotification({
        userId: asset.ownerId,
        title: 'New Rental Bid',
        body: `You received a bid of ₹${data.amount}/day for "${asset.title}".`,
        actionType: 'RENTAL_BID',
        actionId: bid.id,
      });
    } catch (error) {
      console.error('Notification failed:', error);
    }

    return bid;
  }

  async getBidsForAsset(req: Request) {
    const { user, params } = req as any;
    const asset = await prisma.asset.findUnique({
      where: { id: params.assetId },
    });
    if (!asset) throw new NotFoundError("Asset not found");
    const isOwner = asset.ownerId === user!.id;
    return prisma.bid.findMany({
      where: isOwner
        ? { assetId: params.assetId }
        : { assetId: params.assetId, bidderId: user!.id },
      orderBy: { amount: "desc" },
      include: { bidder: { select: { id: true, email: true } } },
    });
  }

  async getMyBids(req: Request) {
    return prisma.bid.findMany({
      where: { bidderId: (req as any).user.id },
      orderBy: { createdAt: "desc" },
      include: {
        asset: { select: { id: true, title: true, type: true, status: true } },
      },
    });
  }

  async acceptBid(req: Request) {
    const { user, params } = req as any;
    const { assetId, bidId } = params;

    return prisma.$transaction(async (tx) => {
      const asset = await tx.asset.findUnique({ where: { id: assetId } });
      if (!asset) throw new NotFoundError("Asset not found");
      if (asset.ownerId !== user!.id) throw new ForbiddenError("Forbidden");
      if (asset.status !== AssetStatus.AVAILABLE)
        throw new ConflictError(
          "Asset is not available — a bid may already have been accepted",
        );

      const bid = await tx.bid.findUnique({ where: { id: bidId } });
      if (!bid || bid.assetId !== assetId)
        throw new NotFoundError("Bid not found on this asset");
      if (bid.status !== BidStatus.PENDING)
        throw new ConflictError("Bid is no longer pending");

      // 1. Accept this bid
      const acceptedBid = await tx.bid.update({
        where: { id: bidId },
        data: { status: BidStatus.ACCEPTED },
      });

      // 2. Reject other bids for this asset
      await tx.bid.updateMany({
        where: { assetId, id: { not: bidId }, status: BidStatus.PENDING },
        data: { status: BidStatus.REJECTED },
      });

      // 3. Lock asset
      await tx.asset.update({
        where: { id: assetId },
        data: { status: AssetStatus.LOCKED },
      });

      // 4. Create rental order
      const rental = await tx.rental.create({
        data: {
          assetId,
          bidId,
          tenantId: bid.bidderId,
          startDate: bid.startDate,
          endDate: bid.endDate,
          agreedPrice: bid.amount,
          status:
            bid.startDate <= new Date()
              ? RentalStatus.ACTIVE
              : RentalStatus.UPCOMING,
        },
        include: {
          tenant: { select: { id: true, email: true } },
          asset: { select: { id: true, title: true } },
        },
      });

      // Notify Bidder
      try {
        await NotificationService.createNotification({
          userId: bid.bidderId,
          title: 'Bid Accepted!',
          body: `Your bid for "${asset.title}" has been accepted. Rental starts on ${bid.startDate.toLocaleDateString()}.`,
          actionType: 'RENTAL_ACCEPTED',
          actionId: rental.id,
        });
      } catch (error) {
        console.error('Notification failed:', error);
      }

      return rental;
    });
  }

  async withdrawBid(req: Request) {
    const { user, params } = req as any;
    const bid = await prisma.bid.findUnique({ where: { id: params.bidId } });
    if (!bid) throw new NotFoundError("Bid not found");
    if (bid.bidderId !== user!.id) throw new ForbiddenError("Forbidden");
    if (bid.status !== BidStatus.PENDING)
      throw new ConflictError("Only pending bids can be withdrawn");
    return prisma.bid.update({
      where: { id: params.bidId },
      data: { status: BidStatus.WITHDRAWN },
    });
  }

  async getRentalByAsset(req: Request) {
    const rental = await prisma.rental.findUnique({
      where: { assetId: (req as any).params.assetId },
      include: {
        tenant: { select: { id: true, email: true } },
        asset: { include: { owner: { select: { id: true, email: true } } } },
      },
    });
    if (!rental) throw new NotFoundError("No rental found for this asset");
    return rental;
  }

  async getMyRentals(req: Request) {
    return prisma.rental.findMany({
      where: { tenantId: (req as any).user.id },
      orderBy: { startDate: "desc" },
      include: { asset: { select: { id: true, title: true, type: true } } },
    });
  }

  async getMyAssets(req: Request) {
    return prisma.asset.findMany({
      where: { ownerId: (req as any).user.id },
      orderBy: { createdAt: "desc" },
      include: {
        _count: { select: { bids: true } },
      },
    });
  }

  // Call on a cron schedule (e.g. hourly) to advance rental statuses
  async syncRentalStatuses() {
    const now = new Date();
    await prisma.rental.updateMany({
      where: { status: RentalStatus.UPCOMING, startDate: { lte: now } },
      data: { status: RentalStatus.ACTIVE },
    });
    await prisma.rental.updateMany({
      where: { status: RentalStatus.ACTIVE, endDate: { lte: now } },
      data: { status: RentalStatus.COMPLETED },
    });
    const done = await prisma.rental.findMany({
      where: { status: RentalStatus.COMPLETED },
      select: { assetId: true },
    });
    if (done.length) {
      await prisma.asset.updateMany({
        where: { id: { in: done.map((r) => r.assetId) } },
        data: { status: AssetStatus.AVAILABLE },
      });
    }
  }
}

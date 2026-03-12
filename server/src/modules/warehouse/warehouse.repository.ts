import {
  PrismaClient,
  WarehouseInventoryItem,
  WarehouseListing,
  WarehouseListingStatus,
  WarehouseOfferStatus,
  WarehouseRental,
  WarehouseRentalOffer,
} from "@prisma/client";
import {
  CreateListingInput,
  SubmitOfferInput,
  AddInventoryItemInput,
  UpdateInventoryInput,
} from "../../schema/warehouse.schema.js";

const prisma = new PrismaClient();

export class WarehouseRepository {
  // ── Listings ────────────────────────────────────────────

  async createListing(
    ownerId: string,
    data: CreateListingInput,
  ): Promise<WarehouseListing> {
    return prisma.warehouseListing.create({
      data: { ...data, ownerId, status: "OPEN" },
    });
  }

  async findListingById(id: string): Promise<WarehouseListing | null> {
    return prisma.warehouseListing.findFirst({
      where: { id, isDeleted: false },
    });
  }

  async findNearbyListings(
    lat: number,
    lng: number,
    radiusKm: number,
  ): Promise<WarehouseListing[]> {
    return prisma.$runCommandRaw({
      find: "WarehouseListing",
      filter: {
        status: "OPEN",
        isDeleted: false,
        location: {
          $near: {
            $geometry: { type: "Point", coordinates: [lng, lat] },
            $maxDistance: radiusKm * 1000,
          },
        },
      },
    }) as unknown as WarehouseListing[];
  }

  async updateListingStatus(
    id: string,
    status: WarehouseListingStatus,
  ): Promise<WarehouseListing> {
    return prisma.warehouseListing.update({
      where: { id },
      data: { status },
    });
  }

  async softDeleteListing(id: string): Promise<void> {
    await prisma.warehouseListing.update({
      where: { id },
      data: { isDeleted: true, deletedAt: new Date() },
    });
  }

  // ── Offers ──────────────────────────────────────────────

  async createOffer(
    listingId: string,
    offererId: string,
    data: SubmitOfferInput,
  ): Promise<WarehouseRentalOffer> {
    return prisma.warehouseRentalOffer.create({
      data: { ...data, listingId, offererId, status: "PENDING" },
    });
  }

  async findOfferById(id: string): Promise<WarehouseRentalOffer | null> {
    return prisma.warehouseRentalOffer.findUnique({ where: { id } });
  }

  async findExistingPendingOffer(
    listingId: string,
    offererId: string,
  ): Promise<WarehouseRentalOffer | null> {
    return prisma.warehouseRentalOffer.findFirst({
      where: { listingId, offererId, status: "PENDING" },
    });
  }

  async findOffersByListing(
    listingId: string,
  ): Promise<WarehouseRentalOffer[]> {
    return prisma.warehouseRentalOffer.findMany({
      where: { listingId },
      orderBy: { createdAt: "desc" },
    });
  }

  async updateOfferStatus(
    id: string,
    status: WarehouseOfferStatus,
    respondedAt?: Date,
  ): Promise<WarehouseRentalOffer> {
    return prisma.warehouseRentalOffer.update({
      where: { id },
      data: {
        status,
        ...(respondedAt && { respondedAt }),
      },
    });
  }

  // ── Rental (accept = 3 writes + 1 create, all atomic) ───

  async acceptOfferAndCreateRental(
    listingId: string,
    ownerId: string,
    acceptedOffer: WarehouseRentalOffer,
  ): Promise<WarehouseRental> {
    return prisma.$transaction(async (tx) => {
      // 1. accept the winning offer
      await tx.warehouseRentalOffer.update({
        where: { id: acceptedOffer.id },
        data: { status: "ACCEPTED", respondedAt: new Date() },
      });

      // 2. reject every other pending offer on this listing
      await tx.warehouseRentalOffer.updateMany({
        where: { listingId, id: { not: acceptedOffer.id }, status: "PENDING" },
        data: { status: "REJECTED", respondedAt: new Date() },
      });

      // 3. lock the listing
      await tx.warehouseListing.update({
        where: { id: listingId },
        data: { status: "RENTED" },
      });

      // 4. create the rental contract
      return tx.warehouseRental.create({
        data: {
          listingId,
          offerId: acceptedOffer.id,
          ownerId,
          tenantId: acceptedOffer.offererId,
          monthlyRent: acceptedOffer.offeredPricePerMonth,
          startDate: acceptedOffer.requestedFrom,
          endDate: acceptedOffer.requestedUntil,
          status: "ACTIVE",
        },
      });
    });
  }

  async findRentalById(id: string): Promise<WarehouseRental | null> {
    return prisma.warehouseRental.findUnique({ where: { id } });
  }

  async findRentalsByTenant(tenantId: string): Promise<WarehouseRental[]> {
    return prisma.warehouseRental.findMany({
      where: { tenantId, status: "ACTIVE" },
      include: { listing: true },
    });
  }

  async findRentalsByOwner(ownerId: string): Promise<WarehouseRental[]> {
    return prisma.warehouseRental.findMany({
      where: { ownerId, status: "ACTIVE" },
      include: { listing: true },
    });
  }

  // ── Inventory ────────────────────────────────────────────

  async createInventoryItem(
    ownerId: string,
    data: AddInventoryItemInput,
  ): Promise<WarehouseInventoryItem> {
    return prisma.warehouseInventoryItem.create({
      data: { ...data, ownerId },
    });
  }

  async findInventoryByOwner(
    ownerId: string,
  ): Promise<WarehouseInventoryItem[]> {
    return prisma.warehouseInventoryItem.findMany({
      where: { ownerId, isDeleted: false },
    });
  }

  async findInventoryItemById(
    id: string,
  ): Promise<WarehouseInventoryItem | null> {
    return prisma.warehouseInventoryItem.findFirst({
      where: { id, isDeleted: false },
    });
  }

  async updateInventoryItem(
    id: string,
    data: UpdateInventoryInput,
  ): Promise<WarehouseInventoryItem> {
    return prisma.warehouseInventoryItem.update({
      where: { id },
      data,
    });
  }

  async softDeleteInventoryItem(id: string): Promise<void> {
    await prisma.warehouseInventoryItem.update({
      where: { id },
      data: { isDeleted: true, deletedAt: new Date() },
    });
  }
}

import { Request, Response, NextFunction } from "express";
import { WarehouseService } from "./warehouse.service.js";
import { successResponse } from "../../core/utils/response.util.js";

export class WarehouseController {
  private service: WarehouseService;

  constructor() {
    this.service = new WarehouseService();
  }

  // ── Listings ─────────────────────────────────────────────

  public createListing = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.createListing(req.user.id, req.body);
      res
        .status(201)
        .json(successResponse("Listing created successfully", result));
    } catch (e) {
      next(e);
    }
  };

  public getNearbyListings = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const { lat, lng, radiusKm } = req.query as {
        lat: string;
        lng: string;
        radiusKm: string;
      };
      const result = await this.service.getNearbyListings(
        +lat,
        +lng,
        +radiusKm,
      );
      res
        .status(200)
        .json(successResponse("Listings fetched successfully", result));
    } catch (e) {
      next(e);
    }
  };

  // ── Offers ───────────────────────────────────────────────

  public submitOffer = async (
    req: Request<{ listingId: string }>,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.submitOffer(
        req.params.listingId,
        req.user.id,
        req.body,
      );
      res
        .status(201)
        .json(successResponse("Offer submitted successfully", result));
    } catch (e) {
      next(e);
    }
  };

  public getOffersForListing = async (
    req: Request<{ listingId: string }>,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.getOffersForListing(
        req.params.listingId,
        req.user.id,
      );
      res
        .status(200)
        .json(successResponse("Offers fetched successfully", result));
    } catch (e) {
      next(e);
    }
  };

  public acceptOffer = async (
    req: Request<{ listingId: string; offerId: string }>,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.acceptOffer(
        req.params.listingId,
        req.params.offerId,
        req.user.id,
      );
      res
        .status(200)
        .json(successResponse("Offer accepted, rental created", result));
    } catch (e) {
      next(e);
    }
  };

  public withdrawOffer = async (
    req: Request<{ offerId: string }>,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.withdrawOffer(
        req.params.offerId,
        req.user.id,
      );
      res
        .status(200)
        .json(successResponse("Offer withdrawn successfully", result));
    } catch (e) {
      next(e);
    }
  };

  // ── Rentals ──────────────────────────────────────────────

  public getMyRentals = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.getMyRentals(req.user.id);
      res
        .status(200)
        .json(successResponse("Rentals fetched successfully", result));
    } catch (e) {
      next(e);
    }
  };

  // ── Inventory ────────────────────────────────────────────

  public addInventoryItem = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.addInventoryItem(req.user.id, req.body);
      res.status(201).json(successResponse("Item added to inventory", result));
    } catch (e) {
      next(e);
    }
  };

  public getMyInventory = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.getMyInventory(req.user.id);
      res
        .status(200)
        .json(successResponse("Inventory fetched successfully", result));
    } catch (e) {
      next(e);
    }
  };

  public updateInventoryItem = async (
    req: Request<{ itemId: string }>,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      const result = await this.service.updateInventoryItem(
        req.params.itemId,
        req.user.id,
        req.body,
      );
      res
        .status(200)
        .json(successResponse("Item updated successfully", result));
    } catch (e) {
      next(e);
    }
  };

  public deleteInventoryItem = async (
    req: Request<{ itemId: string }>,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      await this.service.deleteInventoryItem(req.params.itemId, req.user.id);
      res.status(204).send();
    } catch (e) {
      next(e);
    }
  };
}

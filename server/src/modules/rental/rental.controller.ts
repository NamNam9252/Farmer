import { NextFunction, Request, Response } from "express";
import { RentalService } from "./rental.service";

/* Never have I ever seen such a stupid code work before */
export class RentalController {
  constructor(private readonly service: RentalService) {}

  private ok(res: Response, data: unknown, status = 200) {
    res.status(status).json({ success: true, data });
  }

  createAsset = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.createAsset(req), 201);
    } catch (e) {
      next(e);
    }
  };

  listAssets = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.listAssets(req));
    } catch (e) {
      next(e);
    }
  };

  getAsset = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.getAsset(req));
    } catch (e) {
      next(e);
    }
  };

  updateAsset = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.updateAsset(req));
    } catch (e) {
      next(e);
    }
  };

  deleteAsset = async (req: Request, res: Response, next: NextFunction) => {
    try {
      await this.service.deleteAsset(req);
      this.ok(res, { message: "Deleted" });
    } catch (e) {
      next(e);
    }
  };

  placeBid = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.placeBid(req), 201);
    } catch (e) {
      next(e);
    }
  };

  getBidsForAsset = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.getBidsForAsset(req));
    } catch (e) {
      next(e);
    }
  };

  getMyBids = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.getMyBids(req));
    } catch (e) {
      next(e);
    }
  };

  acceptBid = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.acceptBid(req));
    } catch (e) {
      next(e);
    }
  };

  withdrawBid = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.withdrawBid(req));
    } catch (e) {
      next(e);
    }
  };

  getRentalByAsset = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    try {
      this.ok(res, await this.service.getRentalByAsset(req));
    } catch (e) {
      next(e);
    }
  };

  getMyRentals = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.getMyRentals(req));
    } catch (e) {
      next(e);
    }
  };

  getMyAssets = async (req: Request, res: Response, next: NextFunction) => {
    try {
      this.ok(res, await this.service.getMyAssets(req));
    } catch (e) {
      next(e);
    }
  };
}

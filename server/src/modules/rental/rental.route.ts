import { Router } from "express";
import { requireAuth } from "../../middleware/auth.middleware";
import { RentalController } from "./rental.controller";
import { RentalService } from "./rental.service";

const service = new RentalService();
const controller = new RentalController(service);
const router = Router();

router.post("/assets", requireAuth, controller.createAsset);
router.get("/assets", controller.listAssets);
router.get("/assets/:assetId", controller.getAsset);
router.patch("/assets/:assetId", requireAuth, controller.updateAsset);
router.delete("/assets/:assetId", requireAuth, controller.deleteAsset);

// Bids
router.post("/assets/:assetId/bids", requireAuth, controller.placeBid);
router.get("/assets/:assetId/bids", requireAuth, controller.getBidsForAsset);
router.post(
  "/assets/:assetId/bids/:bidId/accept",
  requireAuth,
  controller.acceptBid,
);
router.delete("/bids/:bidId/withdraw", requireAuth, controller.withdrawBid);
router.get("/me/bids", requireAuth, controller.getMyBids);

// Rentals
router.get("/assets/:assetId/rental", requireAuth, controller.getRentalByAsset);
router.get("/me/rentals", requireAuth, controller.getMyRentals);
router.get("/me/assets", requireAuth, controller.getMyAssets);

export { RentalService, RentalController };
export default router;

import { Router } from "express";
import { WarehouseController } from "./warehouse.controller.js";
import { validate } from "../../middleware/validate.middleware.js";
import { requireAuth } from "../../middleware/auth.middleware.js";
import {
  createListingSchema,
  submitOfferSchema,
  addInventoryItemSchema,
  updateInventoryItemSchema,
  nearbyListingsSchema,
} from "../../schema/warehouse.schema.js";

const router = Router();
const warehouseController = new WarehouseController();

// Listings
router.post(
  "/",
  requireAuth,
  validate(createListingSchema),
  warehouseController.createListing,
);
router.get(
  "/",
  requireAuth,
  validate(nearbyListingsSchema),
  warehouseController.getNearbyListings,
);

// Offers
router.post(
  "/:listingId/offers",
  requireAuth,
  validate(submitOfferSchema),
  warehouseController.submitOffer,
);
router.get(
  "/:listingId/offers",
  requireAuth,
  warehouseController.getOffersForListing,
);
router.patch(
  "/:listingId/offers/:offerId/accept",
  requireAuth,
  warehouseController.acceptOffer,
);
router.patch(
  "/offers/:offerId/withdraw",
  requireAuth,
  warehouseController.withdrawOffer,
);

// Rentals
router.get("/rentals/mine", requireAuth, warehouseController.getMyRentals);

// Inventory
router.post(
  "/inventory",
  requireAuth,
  validate(addInventoryItemSchema),
  warehouseController.addInventoryItem,
);
router.get("/inventory", requireAuth, warehouseController.getMyInventory);
router.patch(
  "/inventory/:itemId",
  requireAuth,
  validate(updateInventoryItemSchema),
  warehouseController.updateInventoryItem,
);
router.delete(
  "/inventory/:itemId",
  requireAuth,
  warehouseController.deleteInventoryItem,
);

export default router;

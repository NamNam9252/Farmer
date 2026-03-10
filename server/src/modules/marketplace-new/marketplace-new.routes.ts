import { Router } from 'express';
import { MarketplaceController } from './marketplace-new.controller.js';
import { requireAuth } from '../../middleware/auth.middleware.js';
import { validate } from '../../middleware/validate.middleware.js';
import * as schemas from '../../schema/marketplace-new.schema.js';

const router = Router();
const controller = new MarketplaceController();

router.use(requireAuth);

// Items
router.post('/items', validate(schemas.createItemSchema), controller.createItem);
router.get('/items', validate(schemas.browseItemsSchema), controller.getItems);
router.get('/items/user/:userId', controller.getUserItems);
router.put('/items/:itemId', validate(schemas.updateItemSchema), controller.updateItem);
router.delete('/items/:itemId', controller.deleteItem);
router.post('/items/:itemId/report', controller.reportItem);

// Demands
router.post('/demands', validate(schemas.createDemandSchema), controller.createDemand);
router.get('/demands', controller.getDemands);
router.get('/demands/user/:userId', controller.getUserDemands);
router.put('/demands/:demandId', validate(schemas.updateDemandSchema), controller.updateDemand);
router.delete('/demands/:demandId', controller.deleteDemand);
router.post('/demands/:demandId/report', controller.reportDemand);

// Purchase Requests
router.post('/purchase-requests', validate(schemas.createPurchaseRequestSchema), controller.sendPurchaseRequest);
router.get('/purchase-requests/seller', controller.getSellerRequests);
router.get('/purchase-requests/buyer', controller.getBuyerRequests);
router.put('/purchase-requests/:requestId/accept', controller.acceptPurchaseRequest);
router.put('/purchase-requests/:requestId/reject', controller.rejectPurchaseRequest);

// Demand Offers
router.post('/demand-offers', validate(schemas.createDemandOfferSchema), controller.sendDemandOffer);
router.get('/demand-offers/buyer', controller.getBuyerOffers);
router.get('/demand-offers/seller', controller.getSellerOffers);
router.put('/demand-offers/:offerId/accept', controller.acceptDemandOffer);
router.put('/demand-offers/:offerId/reject', controller.rejectDemandOffer);

export default router;

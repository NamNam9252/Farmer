import { Router } from 'express';
import { MarketController } from './market.controller.js';

const router = Router();
const marketController = new MarketController();

router.get('/prices', marketController.getMarketPrices);
router.get('/commodities', marketController.getCommodities);
router.get('/markets', marketController.getMarkets);

export default router;

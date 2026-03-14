import { Router } from 'express';
import { MarketController } from './market.controller.js';

const router = Router();
const marketController = new MarketController();

// ── New smart mandi endpoints ──
router.get('/mandi-prices', marketController.getMandiPrices);
router.get('/states', marketController.getStates);
router.get('/districts', marketController.getDistricts);

// ── Legacy endpoints (backward compatible) ──
router.get('/prices', marketController.getMarketPrices);
router.get('/commodities', marketController.getCommodities);
router.get('/markets', marketController.getMarkets);

export default router;

import { Router } from 'express';
import authRoutes from './modules/auth/auth.routes.js';
import diseaseRoutes from './modules/disease/disease.routes.js';
import marketRoutes from './modules/market/market.routes.js';

const router = Router();

// Mount all feature routes here
router.use('/auth', authRoutes);
router.use('/disease', diseaseRoutes);
router.use('/market', marketRoutes);

export default router;

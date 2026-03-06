import { Router } from 'express';
import authRoutes from './modules/auth/auth.routes.js';
import diseaseRoutes from './modules/disease/disease.routes.js';
import marketRoutes from './modules/market/market.routes.js';
import usersRoutes from './modules/users/users.routes.js';
import advisoryRoutes from './modules/advisory/advisory.routes.js'; // ADD THIS

const router = Router();

// Mount all feature routes here
router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/disease', diseaseRoutes);
router.use('/market', marketRoutes);
router.use('/advisory', advisoryRoutes); // ADD THIS

export default router;
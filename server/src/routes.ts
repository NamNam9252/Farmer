import { Router } from 'express';
import authRoutes from './modules/auth/auth.routes.js';
import diseaseRoutes from './modules/disease/disease.routes.js';
import usersRoutes from './modules/users/users.routes.js';

const router = Router();

// Mount all feature routes here
router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/disease', diseaseRoutes);

export default router;

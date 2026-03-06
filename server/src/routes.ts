import { Router } from 'express';
import authRoutes from './modules/auth/auth.routes.js';
import diseaseRoutes from './modules/disease/disease.routes.js';
<<<<<<< HEAD
import usersRoutes from './modules/users/users.routes.js';
=======
import advisoryRoutes from './modules/advisory/advisory.routes.js'; // ADD THIS
>>>>>>> 40881ffcc3d3fc20689c7bedac7792394f3a72c5

const router = Router();

// Mount all feature routes here
router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/disease', diseaseRoutes);
router.use('/advisory', advisoryRoutes); // ADD THIS

export default router;
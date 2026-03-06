import { Router } from 'express';
import { getRecommendation } from './advisory.controller.js';

const router = Router();

// POST /api/v1/advisory/recommendation
router.post('/recommendation', getRecommendation);

export default router;
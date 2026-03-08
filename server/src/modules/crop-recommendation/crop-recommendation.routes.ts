import { Router } from 'express';
import { getRecommendation } from './crop-recommendation.controller.js';

const router = Router();

// POST /api/v1/crop-recommendation/recommend
router.post('/recommend', getRecommendation);

export default router;

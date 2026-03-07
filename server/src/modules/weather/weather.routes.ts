import { Router } from 'express';
import { getWeather } from './weather.controller.js';

const router = Router();

// GET /api/v1/weather?lat=28.73&lon=77.77
router.get('/', getWeather);

export default router;

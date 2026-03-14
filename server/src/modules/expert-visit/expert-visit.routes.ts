import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware.js';
import {
  requestVisit,
  getMyRequests,
  getAvailableRequests,
  acceptRequest,
  updateVisitStatus
} from './expert-visit.controller.js';

const router = Router();

// Protect all routes
router.use(requireAuth);

// Farmer Routes
router.post('/request', requestVisit);
router.get('/my-requests', getMyRequests);

// Expert Routes
router.get('/available', getAvailableRequests);
router.put('/:id/accept', acceptRequest);
router.put('/:id/status', updateVisitStatus);

export default router;

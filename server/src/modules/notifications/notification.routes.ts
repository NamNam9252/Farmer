import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware.js';
import * as NotificationController from './notification.controller.js';

const router = Router();

router.get('/', requireAuth, NotificationController.getUserNotifications);
router.patch('/:id/read', requireAuth, NotificationController.markAsRead);

export default router;

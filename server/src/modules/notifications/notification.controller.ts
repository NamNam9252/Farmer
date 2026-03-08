import { Request, Response, NextFunction } from 'express';
import * as NotificationService from './notification.service.js';

export const getUserNotifications = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user.id;
        const notifications = await NotificationService.getUserNotifications(userId);
        res.status(200).json({ success: true, data: notifications });
    } catch (error) {
        next(error);
    }
};

export const markAsRead = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const id = req.params.id as string;
        await NotificationService.markAsRead(id);
        res.status(200).json({ success: true, message: 'Notification marked as read' });
    } catch (error) {
        next(error);
    }
};

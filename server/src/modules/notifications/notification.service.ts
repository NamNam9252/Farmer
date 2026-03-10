import { PrismaClient, NotificationChannel, NotificationStatus } from '@prisma/client';

const prisma = new PrismaClient();

import { sendNotificationToUser } from '../../socket.js';

export const createNotification = async (data: {
    userId: string;
    title: string;
    body: string;
    actionType?: string;
    actionId?: string;
}) => {
    const notification = await prisma.notification.create({
        data: {
            userId: data.userId,
            title: data.title,
            body: data.body,
            channel: NotificationChannel.IN_APP,
            status: NotificationStatus.QUEUED,
            actionType: data.actionType,
            actionId: data.actionId,
        }
    });

    // Emit real-time update via socket
    sendNotificationToUser(data.userId, notification);

    return notification;
};

export const getUserNotifications = async (userId: string) => {
    return prisma.notification.findMany({
        where: { userId, isRead: false },
        orderBy: { createdAt: 'desc' }
    });
};

export const markAsRead = async (notificationId: string) => {
    return prisma.notification.update({
        where: { id: notificationId },
        data: { 
            isRead: true,
            readAt: new Date(),
            status: NotificationStatus.READ
        }
    });
};

export const createBulkNotifications = async (data: {
    userIds: string[];
    title: string;
    body: string;
    actionType?: string;
    actionId?: string;
}) => {
    return prisma.notification.createMany({
        data: data.userIds.map(id => ({
            userId: id,
            title: data.title,
            body: data.body,
            channel: NotificationChannel.IN_APP,
            status: NotificationStatus.QUEUED,
            actionType: data.actionType,
            actionId: data.actionId,
        }))
    });
};

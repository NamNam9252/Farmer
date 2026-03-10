import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_temporary_key_for_dev';

interface AuthSocket extends Socket {
    user?: { id: string; role: string };
}

let ioInstance: Server | null = null;

export function setupSocket(server: HttpServer) {
    const io = new Server(server, {
        cors: {
            origin: '*', // Adjust for production
            methods: ['GET', 'POST']
        }
    });

    ioInstance = io;

    // Middleware for Auth
    io.use((socket: AuthSocket, next) => {
        const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];
        if (!token) {
            return next(new Error('Authentication Error'));
        }

        try {
            const decoded = jwt.verify(token, JWT_SECRET) as any;
            socket.user = { id: decoded.id, role: decoded.role };
            next();
        } catch (error) {
            return next(new Error('Authentication Error'));
        }
    });

    io.on('connection', (socket: AuthSocket) => {
        const userId = socket.user?.id;
        console.log(`User connected to socket: ${userId} (${socket.id})`);

        // Join a private room for the user to receive targeted notifications
        if (userId) {
            socket.join(`user_${userId}`);
        }

        socket.on('join_room', async (data: { roomId: string; communityId: string }) => {
            const { roomId } = data;
            socket.join(roomId);
            console.log(`User ${userId} joined room ${roomId}`);
        });

        socket.on('leave_room', (data: { roomId: string }) => {
            const { roomId } = data;
            socket.leave(roomId);
            console.log(`User ${userId} left room ${roomId}`);
        });

        socket.on('send_message', async (data: { roomId: string; communityId: string; content: string; images?: string[]; replyToId?: string }) => {
            try {
                if (!userId) return;
                
                const message = await prisma.communityChatMessage.create({
                    data: {
                        roomId: data.roomId,
                        communityId: data.communityId,
                        senderId: userId,
                        content: data.content,
                        images: data.images || [],
                        replyToId: data.replyToId
                    },
                    include: {
                        sender: {
                            select: { id: true, name: true, profileImageUrl: true }
                        }
                    }
                });

                await prisma.communityChatRoom.update({
                    where: { id: data.roomId },
                    data: { 
                        lastMessageAt: new Date(),
                        messageCount: { increment: 1 }
                    }
                });

                io.to(data.roomId).emit('new_message', message);
            } catch (error) {
                console.error('Socket send_message error:', error);
                socket.emit('error', { message: 'Failed to send message' });
            }
        });

        socket.on('disconnect', () => {
            console.log(`User disconnected: ${userId}`);
        });
    });

    return io;
}

export function sendNotificationToUser(userId: string, notification: any) {
    if (ioInstance) {
        ioInstance.to(`user_${userId}`).emit('new_notification', notification);
    }
}

import { Request, Response, NextFunction } from 'express';
import { handleChat, executeConfirmedAction, ChatMessage } from './agent.service.js';

export const chat = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const userId = (req as any).user.id;
        const { message, conversationHistory, lat, lng } = req.body;
        const file = req.file;
        
        if (!message || typeof message !== 'string' || message.trim().length === 0) {
            res.status(400).json({
                success: false,
                message: 'Message is required',
            });
            return;
        }

        const history: ChatMessage[] = Array.isArray(conversationHistory)
            ? conversationHistory
            : [];

        const result = await handleChat(
            userId, 
            message.trim(), 
            history, 
            lat ? parseFloat(lat) : undefined, 
            lng ? parseFloat(lng) : undefined,
            file?.path
        );

        res.status(200).json({
            success: true,
            message: 'Agent response generated',
            data: result,
        });
    } catch (error) {
        next(error);
    }
};

export const confirmAction = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const userId = (req as any).user.id;
        const { action, payload } = req.body;

        if (!action || !payload) {
            res.status(400).json({
                success: false,
                message: 'Action and payload are required',
            });
            return;
        }

        const result = await executeConfirmedAction(userId, action, payload);

        res.status(201).json({
            success: true,
            message: 'Action completed successfully',
            data: result,
        });
    } catch (error) {
        next(error);
    }
};

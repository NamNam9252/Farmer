import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../core/utils/jwt.util.js';
import { UnauthorizedError } from '../core/errors/custom.error.js';

export const requireAuth = (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return next(new UnauthorizedError('No token provided'));
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);
    
    if (!decoded) {
        return next(new UnauthorizedError('Invalid or expired token'));
    }

    // Attach user info to request
    (req as any).user = decoded;
    next();
};

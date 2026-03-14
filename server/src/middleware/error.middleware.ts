import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../core/errors/custom.error.js';
import { errorResponse } from '../core/utils/response.util.js';

export const errorMiddleware = (
    err: Error | AppError | ZodError,
    req: Request,
    res: Response,
    next: NextFunction
) => {
    let statusCode = 500;
    let message = 'Internal Server Error';
    let errorData: any = {};

    if (err instanceof AppError) {
        statusCode = err.statusCode;
        message = err.message;
    } else if (err instanceof ZodError) {
        statusCode = 400;
        message = 'Validation Error';
        errorData = { details: err.issues.map((issue: any) => ({ path: issue.path, message: issue.message })) };
    } else {
        // For non-operational errors (like unhandled exceptions)
        console.error('Unhandled Exception:', err);
        if (process.env.NODE_ENV !== 'production') {
            message = err.message;
            errorData = { stack: err.stack };
        }
    }

    res.status(statusCode).json(errorResponse(message, errorData));
};

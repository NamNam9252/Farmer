import { Request, Response, NextFunction } from 'express';
import { z, ZodObject } from 'zod';
import { errorResponse } from '../core/utils/response.util.js';

export const validate = (schema: ZodObject<any, any>) => {
    return async (req: Request, res: Response, next: NextFunction) => {
        try {
            await schema.parseAsync({
                body: req.body,
                query: req.query,
                params: req.params,
            });
            next();
        } catch (error) {
            if (error instanceof z.ZodError) {
                return res
                    .status(400)
                    .json(errorResponse('Validation Error', error.format()));
            }
            next(error);
        }
    };
};

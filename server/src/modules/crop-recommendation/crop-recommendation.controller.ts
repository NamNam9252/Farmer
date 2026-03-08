import { Request, Response, NextFunction } from 'express';
import { CropRecommendationService } from './crop-recommendation.service.js';
import { cropRecommendationInputSchema } from '../../schema/crop-recommendation.schema.js';

let service: CropRecommendationService | null = null;

const getService = () => {
    if (!service) service = new CropRecommendationService();
    return service;
};

export const getRecommendation = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const parsed = cropRecommendationInputSchema.safeParse(req.body);

        if (!parsed.success) {
            res.status(400).json({
                success: false,
                message: 'Invalid input. Latitude and longitude are required.',
                error: parsed.error.flatten(),
            });
            return;
        }

        console.log(`[CropRecommendation] Request received: lat=${parsed.data.latitude}, lng=${parsed.data.longitude}`);

        const report = await getService().generateRecommendation(parsed.data);

        res.status(200).json({
            success: true,
            message: 'Crop recommendation report generated',
            data: report,
        });
    } catch (error) {
        console.error('[CropRecommendation] Error:', error);
        next(error);
    }
};

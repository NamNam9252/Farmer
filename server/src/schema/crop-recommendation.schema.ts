import { z } from 'zod';

export const cropRecommendationInputSchema = z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    soil_type: z.string().optional(),           // Override auto-detected soil
    preferred_crops: z.array(z.string()).optional(), // Crops farmer is considering
});

export type CropRecommendationInput = z.infer<typeof cropRecommendationInputSchema>;

export interface CropRecommendation {
    rank: number;
    crop: string;
    cropHindi: string;
    reason: string;
    reasonHindi: string;
    demandLevel: 'Low' | 'Medium' | 'High';
    estimatedCostPerAcre: string;
    estimatedRevenuePerAcre: string;
    estimatedProfitPerAcre: string;
    currentMarketPrice: string;
    bestSeason: string;
    riskLevel: 'Low' | 'Medium' | 'High';
    riskFactors: string[];
    growthDuration: string;
}

export interface CropRecommendationReport {
    location: {
        latitude: number;
        longitude: number;
        state: string;
        district: string;
    };
    soilInfo: {
        type: string;
        typeHindi: string;
        description: string;
        source: 'auto-detected' | 'user-provided';
    };
    weather: {
        temperature: number;
        humidity: number;
        rainfall_probability: number;
    };
    currentSeason: string;
    recommendations: CropRecommendation[];
    summary: string;
    summaryHindi: string;
    generatedAt: string;
}

import { z } from 'zod';

// ─── Legacy schema (kept for backward compat) ───
export const marketPriceQuerySchema = z.object({
    commodity: z.string().optional().default('Wheat'),
    market: z.string().optional().default('Delhi'),
    date: z.string().optional().default(new Date().toISOString().split('T')[0]),
});

export type MarketPriceQuery = z.infer<typeof marketPriceQuerySchema>;

export const marketPriceResponseSchema = z.object({
    commodity: z.string(),
    market: z.string(),
    date: z.string(),
    averagePrice: z.number(),
    lowestPrice: z.number(),
    highestPrice: z.number(),
    unit: z.string().default('quintal'),
});

export type MarketPriceResponse = z.infer<typeof marketPriceResponseSchema>;

// ─── New Mandi Schema ───

export const mandiPriceQuerySchema = z.object({
    commodity: z.string().optional(),
    state: z.string().optional(),
    district: z.string().optional(),
    market: z.string().optional(),
});

export type MandiPriceQuery = z.infer<typeof mandiPriceQuerySchema>;

/** A single mandi record as returned by data.gov.in */
export interface MandiRecord {
    state: string;
    district: string;
    market: string;
    commodity: string;
    variety: string;
    grade: string;
    arrivalDate: string;
    minPrice: number;
    maxPrice: number;
    modalPrice: number;
    unit: string;
}

export type SearchStage =
    | 'exact_match'
    | 'state_level'
    | 'national'
    | 'area_crops'
    | 'state_crops'
    | 'all_india';

export interface MandiPriceResponse {
    success: boolean;
    query: MandiPriceQuery;
    searchStage: SearchStage;
    message: string;
    dataDate: string;
    totalResults: number;
    records: MandiRecord[];
    suggestions: {
        nearestMarkets: string[];
        otherCropsInArea: string[];
    };
}

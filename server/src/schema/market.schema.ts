import { z } from 'zod';

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

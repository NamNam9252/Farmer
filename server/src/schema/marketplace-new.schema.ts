import { z } from 'zod';
import { MarketplaceCategory, MarketplaceItemStatus, MarketplaceDemandStatus, MarketplaceRequestStatus } from '@prisma/client';

export const createItemSchema = z.object({
    body: z.object({
        itemName: z.string().min(1, 'Item name is required'),
        category: z.nativeEnum(MarketplaceCategory),
        quantity: z.string().min(1, 'Quantity is required'),
        pricePerUnit: z.number().positive('Price must be positive'),
        location: z.string().min(1, 'Location is required'),
        description: z.string().optional(),
        imageUrl: z.string().url('Invalid image URL').optional().or(z.literal('')),
    }),
});

export const updateItemSchema = z.object({
    params: z.object({
        itemId: z.string().min(1),
    }),
    body: z.object({
        itemName: z.string().optional(),
        category: z.nativeEnum(MarketplaceCategory).optional(),
        quantity: z.string().optional(),
        pricePerUnit: z.number().positive().optional(),
        location: z.string().optional(),
        description: z.string().optional(),
        imageUrl: z.string().url().optional().or(z.literal('')),
        status: z.nativeEnum(MarketplaceItemStatus).optional(),
    }),
});

export const createDemandSchema = z.object({
    body: z.object({
        itemName: z.string().min(1, 'Item name is required'),
        category: z.nativeEnum(MarketplaceCategory),
        quantityNeeded: z.string().min(1, 'Quantity needed is required'),
        expectedPrice: z.number().positive('Price must be positive'),
        location: z.string().min(1, 'Location is required'),
        description: z.string().optional(),
    }),
});

export const updateDemandSchema = z.object({
    params: z.object({
        demandId: z.string().min(1),
    }),
    body: z.object({
        itemName: z.string().optional(),
        category: z.nativeEnum(MarketplaceCategory).optional(),
        quantityNeeded: z.string().optional(),
        expectedPrice: z.number().positive().optional(),
        location: z.string().optional(),
        description: z.string().optional(),
        status: z.nativeEnum(MarketplaceDemandStatus).optional(),
    }),
});

export const createPurchaseRequestSchema = z.object({
    body: z.object({
        itemId: z.string().min(1, 'Item ID is required'),
        requestedQuantity: z.string().min(1, 'Requested quantity is required'),
        message: z.string().optional(),
    }),
});

export const createDemandOfferSchema = z.object({
    body: z.object({
        demandId: z.string().min(1, 'Demand ID is required'),
        quantityAvailable: z.string().min(1, 'Quantity available is required'),
        offeredPrice: z.number().positive('Price must be positive'),
        message: z.string().optional(),
    }),
});

export const browseItemsSchema = z.object({
    query: z.object({
        category: z.nativeEnum(MarketplaceCategory).optional(),
        location: z.string().optional(),
        minPrice: z.string().optional(),
        maxPrice: z.string().optional(),
    }),
});

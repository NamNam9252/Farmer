import { PrismaClient, MarketplaceItemStatus, MarketplaceDemandStatus, MarketplaceRequestStatus, MarketplaceCategory } from '@prisma/client';

const prisma = new PrismaClient();

export class MarketplaceRepository {
    // Items
    async createItem(userId: string, data: any) {
        return prisma.marketplaceNewItem.create({
            data: {
                ...data,
                sellerId: userId,
            },
        });
    }

    async getItems(filters: { category?: MarketplaceCategory; location?: string; minPrice?: number; maxPrice?: number; excludeUserId?: string }) {
        const where: any = { status: MarketplaceItemStatus.ACTIVE };
        if (filters.excludeUserId) where.sellerId = { not: filters.excludeUserId };
        if (filters.category) where.category = filters.category;
        if (filters.location) where.location = { contains: filters.location, mode: 'insensitive' };
        if (filters.minPrice !== undefined || filters.maxPrice !== undefined) {
            where.pricePerUnit = {};
            if (filters.minPrice !== undefined) where.pricePerUnit.gte = filters.minPrice;
            if (filters.maxPrice !== undefined) where.pricePerUnit.lte = filters.maxPrice;
        }

        return prisma.marketplaceNewItem.findMany({
            where,
            include: { seller: { select: { id: true, name: true, profileImageUrl: true } } },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getUserItems(userId: string) {
        return prisma.marketplaceNewItem.findMany({
            where: { sellerId: userId },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getItemById(itemId: string) {
        return prisma.marketplaceNewItem.findUnique({
            where: { id: itemId },
            include: { seller: { select: { id: true, name: true } } },
        });
    }

    async updateItem(itemId: string, data: any) {
        return prisma.marketplaceNewItem.update({
            where: { id: itemId },
            data,
        });
    }

    async deleteItem(itemId: string) {
        return prisma.marketplaceNewItem.delete({
            where: { id: itemId },
        });
    }

    // Demands
    async createDemand(userId: string, data: any) {
        return prisma.marketplaceNewDemand.create({
            data: {
                ...data,
                buyerId: userId,
            },
        });
    }

    async getDemands(filters: { category?: MarketplaceCategory; excludeUserId?: string } = {}) {
        const where: any = { status: MarketplaceDemandStatus.OPEN };
        if (filters.excludeUserId) where.buyerId = { not: filters.excludeUserId };
        if (filters.category) where.category = filters.category;

        return prisma.marketplaceNewDemand.findMany({
            where,
            include: { buyer: { select: { id: true, name: true, profileImageUrl: true } } },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getUserDemands(userId: string) {
        return prisma.marketplaceNewDemand.findMany({
            where: { buyerId: userId },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getDemandById(demandId: string) {
        return prisma.marketplaceNewDemand.findUnique({
            where: { id: demandId },
            include: { buyer: { select: { id: true, name: true } } },
        });
    }

    async updateDemand(demandId: string, data: any) {
        return prisma.marketplaceNewDemand.update({
            where: { id: demandId },
            data,
        });
    }

    async deleteDemand(demandId: string) {
        return prisma.marketplaceNewDemand.delete({
            where: { id: demandId },
        });
    }

    // Purchase Requests
    async createPurchaseRequest(userId: string, sellerId: string, data: any) {
        return prisma.marketplaceNewPurchaseRequest.create({
            data: {
                ...data,
                buyerId: userId,
                sellerId: sellerId,
            },
        });
    }

    async getSellerPurchaseRequests(sellerId: string) {
        return prisma.marketplaceNewPurchaseRequest.findMany({
            where: { sellerId },
            include: { 
                item: true,
                buyer: { select: { id: true, name: true, phone: true } }
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getBuyerPurchaseRequests(buyerId: string) {
        return prisma.marketplaceNewPurchaseRequest.findMany({
            where: { buyerId },
            include: { 
                item: true,
                seller: { select: { id: true, name: true, phone: true } }
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async updatePurchaseRequestStatus(requestId: string, status: MarketplaceRequestStatus) {
        return prisma.marketplaceNewPurchaseRequest.update({
            where: { id: requestId },
            data: { status },
            include: { item: true }
        });
    }

    async getPurchaseRequestById(requestId: string) {
        return prisma.marketplaceNewPurchaseRequest.findUnique({
            where: { id: requestId },
            include: { item: true }
        });
    }

    // Demand Offers
    async createDemandOffer(userId: string, buyerId: string, data: any) {
        return prisma.marketplaceNewDemandOffer.create({
            data: {
                ...data,
                sellerId: userId,
                buyerId: buyerId,
            },
        });
    }

    async getBuyerDemandOffers(buyerId: string) {
        return prisma.marketplaceNewDemandOffer.findMany({
            where: { buyerId },
            include: { 
                demand: true,
                seller: { select: { id: true, name: true, phone: true } }
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getSellerDemandOffers(sellerId: string) {
        return prisma.marketplaceNewDemandOffer.findMany({
            where: { sellerId },
            include: { 
                demand: true,
                buyer: { select: { id: true, name: true, phone: true } }
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async updateDemandOfferStatus(offerId: string, status: MarketplaceRequestStatus) {
        return prisma.marketplaceNewDemandOffer.update({
            where: { id: offerId },
            data: { status },
            include: { demand: true }
        });
    }

    async getDemandOfferById(offerId: string) {
        return prisma.marketplaceNewDemandOffer.findUnique({
            where: { id: offerId },
            include: { demand: true }
        });
    }

    // Reporting
    async reportItem(userId: string, itemId: string, data: { reason: any; description?: string }) {
        return prisma.contentReport.create({
            data: {
                reporterId: userId,
                newMarketplaceItemId: itemId,
                reason: data.reason,
                description: data.description,
            },
        });
    }

    async reportDemand(userId: string, demandId: string, data: { reason: any; description?: string }) {
        return prisma.contentReport.create({
            data: {
                reporterId: userId,
                newMarketplaceDemandId: demandId,
                reason: data.reason,
                description: data.description,
            },
        });
    }
}

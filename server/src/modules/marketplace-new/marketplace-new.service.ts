import { MarketplaceRepository } from './marketplace-new.repository.js';
import * as NotificationService from '../notifications/notification.service.js';
import { MarketplaceDemandStatus, MarketplaceItemStatus, MarketplaceRequestStatus } from '@prisma/client';

export class MarketplaceService {
    private repository = new MarketplaceRepository();

    // Items
    async createItem(userId: string, data: any) {
        return this.repository.createItem(userId, data);
    }

    async getItems(filters: any) {
        return this.repository.getItems(filters);
    }

    async getDemands(filters: any = {}) {
        return this.repository.getDemands(filters);
    }

    async getUserItems(userId: string) {
        return this.repository.getUserItems(userId);
    }

    async updateItem(userId: string, itemId: string, data: any) {
        const item = await this.repository.getItemById(itemId);
        if (!item || item.sellerId !== userId) {
            throw new Error('Unauthorized or item not found');
        }
        return this.repository.updateItem(itemId, data);
    }

    async deleteItem(userId: string, itemId: string) {
        const item = await this.repository.getItemById(itemId);
        if (!item || item.sellerId !== userId) {
            throw new Error('Unauthorized or item not found');
        }
        return this.repository.deleteItem(itemId);
    }

    // Demands
    async createDemand(userId: string, data: any) {
        return this.repository.createDemand(userId, data);
    }

    async getUserDemands(userId: string) {
        return this.repository.getUserDemands(userId);
    }

    async updateDemand(userId: string, demandId: string, data: any) {
        const demand = await this.repository.getDemandById(demandId);
        if (!demand || demand.buyerId !== userId) {
            throw new Error('Unauthorized or demand not found');
        }
        return this.repository.updateDemand(demandId, data);
    }

    async deleteDemand(userId: string, demandId: string) {
        const demand = await this.repository.getDemandById(demandId);
        if (!demand || demand.buyerId !== userId) {
            throw new Error('Unauthorized or demand not found');
        }
        return this.repository.deleteDemand(demandId);
    }

    // Purchase Requests
    async sendPurchaseRequest(userId: string, data: any) {
        const item = await this.repository.getItemById(data.itemId);
        if (!item) throw new Error('Item not found');
        if (item.sellerId === userId) throw new Error('Cannot buy your own item');

        const request = await this.repository.createPurchaseRequest(userId, item.sellerId, data);

        // Notify Seller
        await NotificationService.createNotification({
            userId: item.sellerId,
            title: 'New Purchase Request',
            body: `You received a request for "${item.itemName}" from a buyer.`,
            actionType: 'PURCHASE_REQUEST',
            actionId: request.id,
        });

        return request;
    }

    async getSellerRequests(userId: string) {
        return this.repository.getSellerPurchaseRequests(userId);
    }

    async getBuyerRequests(userId: string) {
        return this.repository.getBuyerPurchaseRequests(userId);
    }

    async handlePurchaseRequest(userId: string, requestId: string, accept: boolean) {
        const request = await this.repository.getPurchaseRequestById(requestId);
        if (!request || request.sellerId !== userId) {
            throw new Error('Unauthorized or request not found');
        }

        if (request.status !== MarketplaceRequestStatus.PENDING) {
            throw new Error('This purchase request is no longer pending');
        }

        const status = accept ? MarketplaceRequestStatus.ACCEPTED : MarketplaceRequestStatus.REJECTED;
        const updatedRequest = await this.repository.updatePurchaseRequestStatus(requestId, status);

        if (accept) {
            await this.repository.updateItemStatus(request.itemId, MarketplaceItemStatus.SOLD);

            const competingRequests = await this.repository.getPendingPurchaseRequestsForItem(request.itemId, requestId);
            await this.repository.rejectPurchaseRequests(competingRequests.map((r) => r.id));

            for (const competing of competingRequests) {
                await NotificationService.createNotification({
                    userId: competing.buyerId,
                    title: 'Request Closed',
                    body: `Another buyer's request was accepted for "${request.item.itemName}".`,
                    actionType: 'REQUEST_REJECTED',
                    actionId: competing.id,
                });
            }
        }

        // Notify Buyer
        await NotificationService.createNotification({
            userId: request.buyerId,
            title: accept ? 'Request Accepted' : 'Request Rejected',
            body: `The seller has ${accept ? 'accepted' : 'rejected'} your request for "${request.item.itemName}".`,
            actionType: accept ? 'REQUEST_ACCEPTED' : 'REQUEST_REJECTED',
            actionId: requestId,
        });

        return updatedRequest;
    }

    // Demand Offers
    async sendDemandOffer(userId: string, data: any) {
        const demand = await this.repository.getDemandById(data.demandId);
        if (!demand) throw new Error('Demand not found');
        if (demand.buyerId === userId) throw new Error('Cannot offer to your own demand');

        const offer = await this.repository.createDemandOffer(userId, demand.buyerId, data);

        // Notify Buyer
        await NotificationService.createNotification({
            userId: demand.buyerId,
            title: 'New Supply Offer',
            body: `A seller has offered a supply for your demand "${demand.itemName}".`,
            actionType: 'OFFER_RECEIVED',
            actionId: offer.id,
        });

        return offer;
    }

    async getBuyerOffers(userId: string) {
        return this.repository.getBuyerDemandOffers(userId);
    }

    async getSellerOffers(userId: string) {
        return this.repository.getSellerDemandOffers(userId);
    }

    async handleDemandOffer(userId: string, offerId: string, accept: boolean) {
        const offer = await this.repository.getDemandOfferById(offerId);
        if (!offer || offer.buyerId !== userId) {
            throw new Error('Unauthorized or offer not found');
        }

        if (offer.status !== MarketplaceRequestStatus.PENDING) {
            throw new Error('This offer is no longer pending');
        }

        const status = accept ? MarketplaceRequestStatus.ACCEPTED : MarketplaceRequestStatus.REJECTED;
        const updatedOffer = await this.repository.updateDemandOfferStatus(offerId, status);

        if (accept) {
            await this.repository.updateDemandStatus(offer.demandId, MarketplaceDemandStatus.FULFILLED);

            const competingOffers = await this.repository.getPendingDemandOffersForDemand(offer.demandId, offerId);
            await this.repository.rejectDemandOffers(competingOffers.map((o) => o.id));

            for (const competing of competingOffers) {
                await NotificationService.createNotification({
                    userId: competing.sellerId,
                    title: 'Offer Closed',
                    body: `The demand "${offer.demand.itemName}" has been fulfilled by another seller.`,
                    actionType: 'OFFER_REJECTED',
                    actionId: competing.id,
                });
            }
        }

        // Notify Seller
        await NotificationService.createNotification({
            userId: offer.sellerId,
            title: accept ? 'Offer Accepted' : 'Offer Rejected',
            body: `The buyer has ${accept ? 'accepted' : 'rejected'} your offer for "${offer.demand.itemName}".`,
            actionType: accept ? 'OFFER_ACCEPTED' : 'OFFER_REJECTED',
            actionId: offerId,
        });

        return updatedOffer;
    }

    // Reporting
    async reportItem(userId: string, itemId: string, data: any) {
        return this.repository.reportItem(userId, itemId, data);
    }

    async reportDemand(userId: string, demandId: string, data: any) {
        return this.repository.reportDemand(userId, demandId, data);
    }
}

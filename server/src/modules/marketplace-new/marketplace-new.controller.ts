import { Request, Response, NextFunction } from 'express';
import { MarketplaceService } from './marketplace-new.service.js';

export class MarketplaceController {
    private service = new MarketplaceService();

    // Items
    createItem = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const item = await this.service.createItem(userId, req.body);
            res.status(201).json({ success: true, message: 'Item listing created', data: item });
        } catch (error) {
            next(error);
        }
    };

    getItems = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const filters = {
                category: req.query.category as any,
                location: req.query.location as string,
                minPrice: req.query.minPrice ? parseFloat(req.query.minPrice as string) : undefined,
                maxPrice: req.query.maxPrice ? parseFloat(req.query.maxPrice as string) : undefined,
                excludeUserId: (req as any).user.id,
            };
            const items = await this.service.getItems(filters);
            res.status(200).json({ success: true, data: items });
        } catch (error) {
            next(error);
        }
    };

    getUserItems = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req.params.userId as string) || (req as any).user.id;
            const items = await this.service.getUserItems(userId);
            res.status(200).json({ success: true, data: items });
        } catch (error) {
            next(error);
        }
    };

    updateItem = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const itemId = req.params.itemId as string;
            const item = await this.service.updateItem(userId, itemId, req.body);
            res.status(200).json({ success: true, message: 'Item listing updated', data: item });
        } catch (error) {
            next(error);
        }
    };

    deleteItem = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const itemId = req.params.itemId as string;
            await this.service.deleteItem(userId, itemId);
            res.status(200).json({ success: true, message: 'Item listing deleted' });
        } catch (error) {
            next(error);
        }
    };

    // Demands
    createDemand = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const demand = await this.service.createDemand(userId, req.body);
            res.status(201).json({ success: true, message: 'Demand posted', data: demand });
        } catch (error) {
            next(error);
        }
    };

    getDemands = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const filters = {
                category: req.query.category as any,
                excludeUserId: (req as any).user.id,
            };
            const demands = await this.service.getDemands(filters);
            res.status(200).json({ success: true, data: demands });
        } catch (error) {
            next(error);
        }
    };

    getUserDemands = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req.params.userId as string) || (req as any).user.id;
            const demands = await this.service.getUserDemands(userId);
            res.status(200).json({ success: true, data: demands });
        } catch (error) {
            next(error);
        }
    };

    updateDemand = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const demandId = req.params.demandId as string;
            const demand = await this.service.updateDemand(userId, demandId, req.body);
            res.status(200).json({ success: true, message: 'Demand updated', data: demand });
        } catch (error) {
            next(error);
        }
    };

    deleteDemand = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const demandId = req.params.demandId as string;
            await this.service.deleteDemand(userId, demandId);
            res.status(200).json({ success: true, message: 'Demand deleted' });
        } catch (error) {
            next(error);
        }
    };

    // Purchase Requests
    sendPurchaseRequest = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const request = await this.service.sendPurchaseRequest(userId, req.body);
            res.status(201).json({ success: true, message: 'Purchase request sent', data: request });
        } catch (error) {
            next(error);
        }
    };

    getSellerRequests = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const requests = await this.service.getSellerRequests(userId);
            res.status(200).json({ success: true, data: requests });
        } catch (error) {
            next(error);
        }
    };

    getBuyerRequests = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const requests = await this.service.getBuyerRequests(userId);
            res.status(200).json({ success: true, data: requests });
        } catch (error) {
            next(error);
        }
    };

    acceptPurchaseRequest = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const requestId = req.params.requestId as string;
            const request = await this.service.handlePurchaseRequest(userId, requestId, true);
            res.status(200).json({ success: true, message: 'Request accepted', data: request });
        } catch (error) {
            next(error);
        }
    };

    rejectPurchaseRequest = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const requestId = req.params.requestId as string;
            const request = await this.service.handlePurchaseRequest(userId, requestId, false);
            res.status(200).json({ success: true, message: 'Request rejected', data: request });
        } catch (error) {
            next(error);
        }
    };

    // Demand Offers
    sendDemandOffer = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const offer = await this.service.sendDemandOffer(userId, req.body);
            res.status(201).json({ success: true, message: 'Supply offer sent', data: offer });
        } catch (error) {
            next(error);
        }
    };

    getBuyerOffers = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const offers = await this.service.getBuyerOffers(userId);
            res.status(200).json({ success: true, data: offers });
        } catch (error) {
            next(error);
        }
    };

    getSellerOffers = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const offers = await this.service.getSellerOffers(userId);
            res.status(200).json({ success: true, data: offers });
        } catch (error) {
            next(error);
        }
    };

    acceptDemandOffer = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const offerId = req.params.offerId as string;
            const offer = await this.service.handleDemandOffer(userId, offerId, true);
            res.status(200).json({ success: true, message: 'Offer accepted', data: offer });
        } catch (error) {
            next(error);
        }
    };

    rejectDemandOffer = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const offerId = req.params.offerId as string;
            const offer = await this.service.handleDemandOffer(userId, offerId, false);
            res.status(200).json({ success: true, message: 'Offer rejected', data: offer });
        } catch (error) {
            next(error);
        }
    };

    // Reporting
    reportItem = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const itemId = req.params.itemId as string;
            const report = await this.service.reportItem(userId, itemId, req.body);
            res.status(201).json({ success: true, message: 'Item reported', data: report });
        } catch (error) {
            next(error);
        }
    };

    reportDemand = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const userId = (req as any).user.id;
            const demandId = req.params.demandId as string;
            const report = await this.service.reportDemand(userId, demandId, req.body);
            res.status(201).json({ success: true, message: 'Demand reported', data: report });
        } catch (error) {
            next(error);
        }
    };
}

import { Request, Response } from 'express';
import { MarketService } from './market.service.js';
import { marketPriceQuerySchema } from '../../schema/market.schema.js';

export class MarketController {
    private marketService: MarketService;

    constructor() {
        this.marketService = new MarketService();
    }

    getMarketPrices = async (req: Request, res: Response) => {
        try {
            const query = marketPriceQuerySchema.parse(req.query);
            const data = await this.marketService.getMarketPrices(query);

            res.status(200).json({
                success: true,
                message: 'Market prices fetched successfully',
                data,
            });
        } catch (error) {
            res.status(400).json({
                success: false,
                message: 'Failed to fetch market prices',
                error: error instanceof Error ? error.message : 'Unknown error',
            });
        }
    };

    getCommodities = async (_req: Request, res: Response) => {
        try {
            const data = await this.marketService.getCommodities();
            res.status(200).json({
                success: true,
                message: 'Commodities fetched successfully',
                data,
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to fetch commodities',
                error: error instanceof Error ? error.message : 'Unknown error',
            });
        }
    };

    getMarkets = async (_req: Request, res: Response) => {
        try {
            const data = await this.marketService.getMarkets();
            res.status(200).json({
                success: true,
                message: 'Markets fetched successfully',
                data,
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to fetch markets',
                error: error instanceof Error ? error.message : 'Unknown error',
            });
        }
    };
}

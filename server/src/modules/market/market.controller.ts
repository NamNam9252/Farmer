import { Request, Response } from 'express';
import { MarketService } from './market.service.js';
import { marketPriceQuerySchema, mandiPriceQuerySchema } from '../../schema/market.schema.js';

export class MarketController {
    private marketService: MarketService;

    constructor() {
        this.marketService = new MarketService();
    }

    // ── New smart mandi prices endpoint ──
    getMandiPrices = async (req: Request, res: Response) => {
        try {
            const query = mandiPriceQuerySchema.parse(req.query);

            if (!query.commodity && !query.state && !query.district && !query.market) {
                res.status(400).json({
                    success: false,
                    message: 'At least one filter is required: commodity, state, district, or market.',
                });
                return;
            }

            const data = await this.marketService.getMandiPrices(query);

            res.status(200).json(data);
        } catch (error) {
            console.error('[MarketController] getMandiPrices error:', error);
            res.status(400).json({
                success: false,
                message: 'Failed to fetch mandi prices',
                error: error instanceof Error ? error.message : 'Unknown error',
            });
        }
    };

    // ── Live states for the dropdown ──
    getStates = async (_req: Request, res: Response) => {
        try {
            const data = await this.marketService.getStates();
            res.status(200).json({ success: true, data });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to fetch states',
                error: error instanceof Error ? error.message : 'Unknown error',
            });
        }
    };

    // ── Live districts for a given state ──
    getDistricts = async (req: Request, res: Response) => {
        try {
            const state = req.query.state as string;
            if (!state) {
                res.status(400).json({ success: false, message: 'state query param is required' });
                return;
            }
            const data = await this.marketService.getDistrictsByState(state);
            res.status(200).json({ success: true, data });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to fetch districts',
                error: error instanceof Error ? error.message : 'Unknown error',
            });
        }
    };

    // ── Legacy endpoints (backward compatible) ──
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

import {
    MarketPriceQuery,
    MarketPriceResponse,
    MandiPriceQuery,
    MandiPriceResponse,
    MandiRecord,
    SearchStage,
} from '../../schema/market.schema.js';
import axios from 'axios';

interface RawRecord {
    state: string;
    district: string;
    market: string;
    commodity: string;
    variety: string;
    grade: string;
    arrival_date: string;
    min_price: number;
    max_price: number;
    modal_price: number;
}

export class MarketService {
    private readonly apiKey = process.env.DATA_GOV_API_KEY || '';
    private readonly baseUrl =
        'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';

    // ──────────────────────────────────────────────
    //  New Smart Mandi Price Search (6-Stage Waterfall)
    // ──────────────────────────────────────────────

    async getMandiPrices(query: MandiPriceQuery): Promise<MandiPriceResponse> {
        const { commodity, state, district, market } = query;

        if (!this.apiKey) {
            return this.emptyResponse(query, 'exact_match', 'API key not configured. Please set DATA_GOV_API_KEY.');
        }

        // ── Stage 1: EXACT MATCH — Crop + District + State (or Market) ──
        if (commodity && (district || market) && state) {
            console.log(`[Mandi] Stage 1: ${commodity} in ${district || market}, ${state}`);
            const filters: Record<string, string> = { commodity, state };
            if (district) filters.district = district;
            if (market) filters.market = market;

            const records = await this.fetchAllRecords(filters);
            if (records.length > 0) {
                return this.buildResponse(query, 'exact_match', records,
                    `✅ Found ${records.length} record(s) for ${commodity} in ${district || market}, ${state} today.`);
            }
        }

        // ── Stage 2: STATE-LEVEL — Crop + State (drop district/market) ──
        if (commodity && state) {
            console.log(`[Mandi] Stage 2: ${commodity} in ${state} (state-wide)`);
            const records = await this.fetchAllRecords({ commodity, state });
            if (records.length > 0) {
                const locationNote = district ? `${district} district` : (market || state);
                return this.buildResponse(query, 'state_level', records,
                    `⚠️ ${commodity} is not available in ${locationNote} today, but found in ${records.length} other market(s) across ${state}.`);
            }
        }

        // ── Stage 3: NATIONAL — Crop across all India ──
        if (commodity) {
            console.log(`[Mandi] Stage 3: ${commodity} nationally`);
            const records = await this.fetchAllRecords({ commodity });
            if (records.length > 0) {
                const uniqueStates = [...new Set(records.map(r => r.state))];
                return this.buildResponse(query, 'national', records,
                    `⚠️ ${commodity} is not available in ${state || 'your area'} today, but found in ${uniqueStates.length} state(s): ${uniqueStates.slice(0, 5).join(', ')}${uniqueStates.length > 5 ? '…' : ''}.`);
            }
        }

        // ── Stage 4: AREA CROPS — All crops in the district ──
        if (district && state) {
            console.log(`[Mandi] Stage 4: All crops in ${district}, ${state}`);
            const records = await this.fetchAllRecords({ district, state });
            if (records.length > 0) {
                const commodityNote = commodity || 'The requested crop';
                return this.buildResponse(query, 'area_crops', records,
                    `❌ ${commodityNote} is not available anywhere in India today. Here are ${records.length} commodity record(s) available in ${district}, ${state}.`);
            }
        }

        // ── Stage 5: STATE CROPS — All crops in the state ──
        if (state) {
            console.log(`[Mandi] Stage 5: All crops in ${state}`);
            const records = await this.fetchAllRecords({ state });
            if (records.length > 0) {
                const commodityNote = commodity || 'The requested crop';
                return this.buildResponse(query, 'state_crops', records,
                    `❌ ${commodityNote} is not available today and no data from ${district || 'your district'}. Here are ${records.length} commodity record(s) from ${state}.`);
            }
        }

        // ── Stage 6: ALL INDIA — Everything available today ──
        console.log(`[Mandi] Stage 6: All India fallback`);
        const records = await this.fetchAllRecords({}, 100);
        if (records.length > 0) {
            return this.buildResponse(query, 'all_india', records,
                `❌ No data found for your query. Here are the latest available commodity prices across India.`);
        }

        return this.emptyResponse(query, 'all_india', '❌ The Mandi price API returned no records at all today. The data may not be updated yet. Please try again later.');
    }

    // ──────────────────────────────────────────────
    //  API fetcher with pagination
    // ──────────────────────────────────────────────

    private async fetchAllRecords(
        filters: Record<string, string>,
        maxRecords: number = 500,
    ): Promise<MandiRecord[]> {
        const allRecords: MandiRecord[] = [];
        let offset = 0;
        const limit = Math.min(maxRecords, 500);

        try {
            while (offset < maxRecords) {
                const params: Record<string, string | number> = {
                    'api-key': this.apiKey,
                    format: 'json',
                    limit,
                    offset,
                };

                for (const [key, value] of Object.entries(filters)) {
                    if (value) {
                        params[`filters[${key}]`] = value;
                    }
                }

                const response = await axios.get(this.baseUrl, { params, timeout: 10000 });
                const data = response.data;
                const records: RawRecord[] = data.records || [];
                const total: number = data.total || 0;

                if (records.length === 0) break;

                for (const r of records) {
                    allRecords.push({
                        state: r.state,
                        district: r.district,
                        market: r.market,
                        commodity: r.commodity,
                        variety: r.variety,
                        grade: r.grade,
                        arrivalDate: r.arrival_date,
                        minPrice: Number(r.min_price) || 0,
                        maxPrice: Number(r.max_price) || 0,
                        modalPrice: Number(r.modal_price) || 0,
                        unit: 'INR/quintal',
                    });
                }

                offset += limit;
                if (offset >= total || allRecords.length >= maxRecords) break;
            }
        } catch (error: any) {
            const status = error.response?.status;
            const msg = error.response?.data?.message || error.message;
            console.error(`[Mandi] API Error [${status || 'N/A'}]: ${msg}`);
        }

        return allRecords;
    }

    // ──────────────────────────────────────────────
    //  Response builders
    // ──────────────────────────────────────────────

    private buildResponse(
        query: MandiPriceQuery,
        stage: SearchStage,
        records: MandiRecord[],
        message: string,
    ): MandiPriceResponse {
        // Derive suggestions
        const nearestMarkets = [
            ...new Set(records.map((r) => `${r.district} — ${r.market}`)),
        ].slice(0, 10);

        // Gather other crops in user's area (state or district)
        const otherCropsInArea: string[] = [];
        if (stage === 'area_crops' || stage === 'state_crops' || stage === 'all_india') {
            const uniqueCommodities = [...new Set(records.map((r) => r.commodity))];
            otherCropsInArea.push(...uniqueCommodities.slice(0, 20));
        }

        // Pick the date from the first record
        const dataDate = records.length > 0 ? records[0].arrivalDate : 'N/A';

        return {
            success: true,
            query,
            searchStage: stage,
            message,
            dataDate,
            totalResults: records.length,
            records: records.slice(0, 50), // cap at 50 for response size
            suggestions: {
                nearestMarkets,
                otherCropsInArea,
            },
        };
    }

    private emptyResponse(
        query: MandiPriceQuery,
        stage: SearchStage,
        message: string,
    ): MandiPriceResponse {
        return {
            success: false,
            query,
            searchStage: stage,
            message,
            dataDate: 'N/A',
            totalResults: 0,
            records: [],
            suggestions: { nearestMarkets: [], otherCropsInArea: [] },
        };
    }

    // ──────────────────────────────────────────────
    //  Legacy API (backward compatible)
    // ──────────────────────────────────────────────

    async getMarketPrices(query: MarketPriceQuery): Promise<MarketPriceResponse[]> {
        try {
            if (!this.apiKey) {
                return this.getMockData(query);
            }

            // Use the new smart search under the hood
            const result = await this.getMandiPrices({
                commodity: query.commodity,
                state: query.market,
            });

            if (result.records.length > 0) {
                return result.records.map((r) => ({
                    commodity: r.commodity,
                    market: `${r.market}, ${r.district}`,
                    date: r.arrivalDate,
                    averagePrice: r.modalPrice,
                    lowestPrice: r.minPrice,
                    highestPrice: r.maxPrice,
                    unit: 'quintal',
                }));
            }

            return this.getMockData(query);
        } catch {
            return this.getMockData(query);
        }
    }

    // ──────────────────────────────────────────────
    //  Static helpers
    // ──────────────────────────────────────────────

    async getCommodities(): Promise<string[]> {
        // Fetch the unique commodities available today from the live API
        if (this.apiKey) {
            try {
                const response = await axios.get(this.baseUrl, {
                    params: {
                        'api-key': this.apiKey,
                        format: 'json',
                        limit: 500,
                        offset: 0,
                    },
                    timeout: 10000,
                });
                const records: RawRecord[] = response.data.records || [];
                const commodities = [...new Set(records.map((r: RawRecord) => r.commodity))].sort();
                if (commodities.length > 0) return commodities;
            } catch {
                // Fall through to static list
            }
        }

        return this.getStaticCommodities();
    }

    async getMarkets(): Promise<string[]> {
        return [
            'Andaman and Nicobar', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam',
            'Bihar', 'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli',
            'Daman and Diu', 'Delhi', 'Goa', 'Gujarat', 'Haryana',
            'Himachal Pradesh', 'Jammu and Kashmir', 'Jharkhand', 'Karnataka',
            'Kerala', 'Lakshadweep', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
            'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Puducherry', 'Punjab',
            'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
            'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
        ].sort();
    }

    async getStates(): Promise<string[]> {
        // Try to get live states from api
        if (this.apiKey) {
            try {
                const response = await axios.get(this.baseUrl, {
                    params: {
                        'api-key': this.apiKey,
                        format: 'json',
                        limit: 500,
                        offset: 0,
                    },
                    timeout: 10000,
                });
                const records: RawRecord[] = response.data.records || [];
                const states = [...new Set(records.map((r: RawRecord) => r.state))].sort();
                if (states.length > 0) return states;
            } catch {
                // Fall through
            }
        }
        return this.getMarkets(); // reuse the static state list
    }

    async getDistrictsByState(state: string): Promise<string[]> {
        if (!this.apiKey) return [];
        try {
            const response = await axios.get(this.baseUrl, {
                params: {
                    'api-key': this.apiKey,
                    format: 'json',
                    limit: 500,
                    'filters[state]': state,
                },
                timeout: 10000,
            });
            const records: RawRecord[] = response.data.records || [];
            return [...new Set(records.map((r: RawRecord) => r.district))].sort();
        } catch {
            return [];
        }
    }

    private getMockData(query: MarketPriceQuery): MarketPriceResponse[] {
        return [
            {
                commodity: query.commodity || 'Wheat',
                market: query.market || 'Delhi',
                date: query.date || new Date().toISOString().split('T')[0],
                averagePrice: 6500,
                lowestPrice: 2000,
                highestPrice: 9200,
                unit: 'quintal',
            },
        ];
    }

    private getStaticCommodities(): string[] {
        return [
            'Ajwan', 'Almond(Badam)', 'Amaranthus', 'Amla(Nelli Kai)', 'Apple',
            'Arecanut(Betelnut/Supari)', 'Arhar (Toor/Red Gram)(Whole)', 'Bajra(Pearl Millet/Cumbu)',
            'Banana', 'Barley (Jau)', 'Beans', 'Beetroot', 'Bengal Gram(Gram)(Whole)',
            'Bhindi(Ladies Finger)', 'Bitter gourd', 'Black Gram(Urd Beans)(Whole)',
            'Black pepper', 'Bottle gourd', 'Brinjal', 'Cabbage', 'Capsicum',
            'Cardamoms', 'Carrot', 'Cashew Nuts', 'Castor Seed', 'Cauliflower',
            'Chili Red', 'Cloves', 'Cluster beans', 'Coconut', 'Coffee',
            'Coriander(Leaves)', 'Corriander seed', 'Cotton', 'Cowpea (Lobia/Karamani)',
            'Cucumbar(Kheera)', 'Cummin Seed(Jeera)', 'Drumstick', 'Dry Chillies',
            'Garlic', 'Ginger(Green)', 'Grapes', 'Green Chilli', 'Green Gram(Moong)(Whole)',
            'Green Peas', 'Groundnut', 'Guar Seed(Cluster Beans Seed)', 'Guava',
            'Gur(Jaggery)', 'Isabgul (Psyllium)', 'Jowar(Sorghum)', 'Lemon',
            'Lentil (Masur)(Whole)', 'Linseed', 'Maize', 'Mango', 'Mashrooms',
            'Methi Seeds', 'Methi(Leaves)', 'Mint(Pudina)', 'Moth Bean(Matki)',
            'Mousambi(Sweet Lime)', 'Mustard', 'Niger Seed (Ramtil)', 'Nutmeg',
            'Onion', 'Orange', 'Paddy(Basmati)', 'Paddy(Common)', 'Papaya',
            'Peas Wet', 'Pineapple', 'Pomegranate', 'Potato', 'Pumpkin',
            'Raddish', 'Ragi (Finger Millet)', 'Rice', 'Ridgeguard(Tori)',
            'Safflower', 'Sesamum(Sesame,Gingelly,Til)', 'Soyabean', 'Spinach',
            'Sweet Potato', 'Tamarind Fruit', 'Tomato', 'Turmeric', 'Turnip',
            'Walnut', 'Water Melon', 'Wheat', 'Yam',
        ].sort();
    }
}

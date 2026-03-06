import { MarketPriceQuery, MarketPriceResponse } from '../../schema/market.schema.js';
import axios from 'axios';

export class MarketService {
    private readonly apiKey = process.env.DATA_GOV_API_KEY || '';
    private readonly baseUrl = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'; // Current Agmarknet Resource ID (2025-2026)

    async getMarketPrices(query: MarketPriceQuery): Promise<MarketPriceResponse[]> {
        try {
            if (!this.apiKey) {
                return this.getMockData(query);
            }

            // Convert YYYY-MM-DD to DD/MM/YYYY for Agmarknet API
            let formattedDate = query.date;
            if (query.date && query.date.includes('-')) {
                const [year, month, day] = query.date.split('-');
                formattedDate = `${day}/${month}/${year}`;
            }

            const fetchRecords = async (filters: { commodity?: string; market?: string; state?: string; arrival_date?: string }) => {
                const params: any = {
                    'api-key': this.apiKey,
                    'format': 'json',
                    'limit': 50,
                };

                if (filters.commodity) params['filters[commodity]'] = filters.commodity;
                if (filters.market) params['filters[market]'] = filters.market;
                if (filters.state) params['filters[state]'] = filters.state;
                if (filters.arrival_date) params['filters[arrival_date]'] = filters.arrival_date;

                const response = await axios.get(this.baseUrl, { params });
                return response.data.records || [];
            };

            const isMajorRegion = (m: string) => ['Delhi', 'Mumbai', 'Maharashtra', 'Rajasthan', 'Gujarat', 'Punjab', 'Uttar Pradesh'].includes(m);
            const marketKey = isMajorRegion(query.market) ? 'state' : 'market';

            // Stage 1: Specific Search (Commodity + Market + Date)
            console.log(`Stage 1: Searching for ${query.commodity} in ${query.market} on ${formattedDate}`);
            let records = await fetchRecords({ [marketKey]: query.market, commodity: query.commodity, arrival_date: formattedDate });

            // Stage 2: If date available but not in this market, show for OTHER states on THAT date
            if (records.length === 0) {
                console.log(`Stage 2: Searching for ${query.commodity} everywhere on ${formattedDate}`);
                records = await fetchRecords({ commodity: query.commodity, arrival_date: formattedDate });
            }

            // Stage 3: If no data for THAT date anywhere, try the selected Market + Commodity (Any Date)
            if (records.length === 0) {
                console.log(`Stage 3: Searching for ${query.commodity} in ${query.market} (Any Date)`);
                records = await fetchRecords({ [marketKey]: query.market, commodity: query.commodity });
            }

            // Stage 4: Final attempt - find the crop anywhere at any date
            if (records.length === 0) {
                console.log(`Stage 4: Searching for ${query.commodity} everywhere (Any Date)`);
                records = await fetchRecords({ commodity: query.commodity });
            }

            if (records.length === 0) {
                console.log(`Final Fallback: ${query.commodity} not found in any recent API records. Using mock data for development.`);
                return this.getMockData(query);
            }

            return records.map((record: any) => ({
                commodity: record.commodity,
                market: record.market,
                date: record.arrival_date,
                averagePrice: parseFloat(record.modal_price) || 0,
                lowestPrice: parseFloat(record.min_price) || 0,
                highestPrice: parseFloat(record.max_price) || 0,
                unit: 'quintal',
            }));
        } catch (error) {
            console.error('Agmarknet API Error:', error);
            return this.getMockData(query);
        }
    }

    async getCommodities(): Promise<string[]> {
        return [
            'Almonds', 'Amaranthus', 'Apple', 'Banana - Green', 'Beetroot',
            'Bhindi(Ladies Finger)', 'Big Gram', 'Bitter gourd', 'Bottle gourd',
            'Brinjal', 'Cabbage', 'Capsicum', 'Carrot', 'Cashew Nuts',
            'Castor Seed', 'Cauliflower', 'Chili Red', 'Coconut', 'Cotton',
            'Garlic', 'Ginger(Green)', 'Green Gram', 'Groundnut', 'Maize',
            'Mango', 'Mustard', 'Onion', 'Potato', 'Rice', 'Soybean',
            'Sugarcane', 'Tomato', 'Wheat'
        ].sort();
    }

    async getMarkets(): Promise<string[]> {
        return [
            'Delhi', 'Mumbai', 'Bengaluru', 'Ahmedabad', 'Pune',
            'Jaipur', 'Kanpur', 'Nagpur', 'Lucknow', 'Patna',
            'Indore', 'Bhopal', 'Chandigarh', 'Ludhiana', 'Agra',
            'Ajmer', 'Jodhpur', 'Kota', 'Udaipur', 'Surat',
            'Chennai', 'Madurai', 'Coimbatore', 'Pollachi', 'Hosur',
            'Rajasthan', 'Maharashtra', 'Gujarat', 'Uttar Pradesh', 'Punjab'
        ].sort();
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
            }
        ];
    }
}

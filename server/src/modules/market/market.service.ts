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

            const formatToAgmarkDate = (dateStr: string) => {
                if (dateStr && dateStr.includes('-')) {
                    const [year, month, day] = dateStr.split('-');
                    return `${day}/${month}/${year}`;
                }
                return dateStr;
            };

            const subtractDays = (dateStr: string, days: number) => {
                const date = new Date(dateStr);
                date.setDate(date.getDate() - days);
                return date.toISOString().split('T')[0];
            };

            const fetchRecords = async (filters: { commodity?: string; market?: string; state?: string; arrival_date?: string }) => {
                const params: any = {
                    'api-key': this.apiKey,
                    'format': 'json',
                    'limit': 50,
                };

                if (filters.commodity) params['filters[commodity]'] = filters.commodity;

                // Sanitize market/state names to remove non-ASCII characters (prevents 403 errors on some datasets)
                const sanitize = (val: string) => val.replace(/[^\x00-\x7F]/g, '').trim();

                if (filters.market) params['filters[market]'] = sanitize(filters.market);
                if (filters.state) params['filters[state]'] = sanitize(filters.state);
                if (filters.arrival_date) params['filters[arrival_date]'] = filters.arrival_date;

                const response = await axios.get(this.baseUrl, { params });
                return response.data.records || [];
            };

            const isMajorRegion = (m: string) => ['Delhi', 'Mumbai', 'Maharashtra', 'Rajasthan', 'Gujarat', 'Punjab', 'Uttar Pradesh'].includes(m);
            const marketKey = isMajorRegion(query.market) ? 'state' : 'market';
            const requestedDate = query.date;
            const agmarkDate = formatToAgmarkDate(requestedDate);
            let records: any[] = [];

            // Stage 1: Same crop, same place, same date (STRICT)
            console.log(`Stage 1: Searching for ${query.commodity} in ${query.market} on ${agmarkDate}`);
            let fetched = await fetchRecords({ [marketKey]: query.market, commodity: query.commodity, arrival_date: agmarkDate });
            records = fetched.filter((r: any) => r.arrival_date === agmarkDate);

            if (records.length > 0) {
                const avg = records[0].modal_price;
                console.log(`[MarketAPI] SUCCESS - Stage 1 Match: Found ${records.length} records. Modal Price: INR ${avg}/quintal`);
            } else {
                console.log(`[MarketAPI] MISS - Stage 1: No records found for ${query.commodity} in ${query.market}.`);
            }

            // Stage 2: Same crop, different place, same day (STRICT)
            if (records.length === 0) {
                console.log(`Stage 2: Searching for ${query.commodity} everywhere on ${agmarkDate}`);
                fetched = await fetchRecords({ commodity: query.commodity, arrival_date: agmarkDate });
                records = fetched.filter((r: any) => r.arrival_date === agmarkDate);
                if (records.length > 0) {
                    const avg = records[0].modal_price;
                    console.log(`[MarketAPI] SUCCESS - Stage 2 (State-level) Match: Found ${records.length} records. Modal Price: INR ${avg}/quintal`);
                } else {
                    console.log(`[MarketAPI] MISS - Stage 2: No records found for ${query.commodity} in ${query.market} on ${agmarkDate}.`);
                }
            }

            // Stage 3: Same crop, different place, related day (Check 1, 2, 3 days back) (STRICT)
            if (records.length === 0) {
                for (let i = 1; i <= 3; i++) {
                    const relatedDate = subtractDays(requestedDate, i);
                    const relatedAgmarkDate = formatToAgmarkDate(relatedDate);
                    console.log(`Stage 3: Searching for ${query.commodity} everywhere on related day ${relatedAgmarkDate} (${i} day(s) back)`);
                    fetched = await fetchRecords({ commodity: query.commodity, arrival_date: relatedAgmarkDate });
                    records = fetched.filter((r: any) => r.arrival_date === relatedAgmarkDate);
                    if (records.length > 0) {
                        const avg = records[0].modal_price;
                        console.log(`[MarketAPI] SUCCESS - Stage 3 (National Date Fallback) Match: Found ${records.length} records on ${relatedAgmarkDate}. Modal Price: INR ${avg}/quintal`);
                        break;
                    } else {
                        console.log(`[MarketAPI] MISS - Stage 3 (${i} days back): No records found on ${relatedAgmarkDate}.`);
                    }
                }
            }

            // Stage 4: Same crop, different place, different day (Any Date Fallback)
            if (records.length === 0) {
                console.log(`Stage 4: Searching for ${query.commodity} everywhere (Final Fallback - Any Date)`);
                records = await fetchRecords({ commodity: query.commodity });
                if (records.length > 0) {
                    const avg = records[0].modal_price;
                    console.log(`[MarketAPI] SUCCESS - Stage 4 (National Final Fallback) Match: Found ${records.length} records. Modal Price: INR ${avg}/quintal`);
                } else {
                    console.log(`[MarketAPI] FAIL - Stage 4: No historical records found for ${query.commodity} at all.`);
                }
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
        } catch (error: any) {
            const status = error.response?.status;
            const msg = error.response?.data?.error || error.message;
            console.error(`Agmarknet API Error [${status || 'No Status'}]: ${msg}`);
            return this.getMockData(query);
        }
    }

    async getCommodities(): Promise<string[]> {
        return [
            'Ajwan', 'Alasande Gram', 'Almond(Badam)', 'Aloe Vera', 'Amaranthus', 'Ambada Seed', 'Amla(Nelli Kai)', 'Amranthas Red', 'Antawala', 'Anthorium', 'Apple', 'Apricot(Jardalu/Khumani)', 'Arecanut(Betelnut/Supari)', 'Arhar (Toor/Red Gram)(Whole)', 'Arhar Dal(Tur Dal)', 'Ashgourd', 'Astera', 'BOP', 'Bael', 'Bajra(Pearl Millet/Cumbu)', 'Balsam', 'Bamboo', 'Banana', 'Banana - Green', 'Barley (Jau)', 'Batar', 'Beans', 'Beetroot', 'Bengal Gram Dal(Chana Dal)', 'Bengal Gram(Gram)(Whole)', 'Ber(Zizyphus/Boreher)', 'Betal Leaves', 'Bhindi(Ladies Finger)', 'Big Gram', 'Binola', 'Bitter gourd', 'Black Gram Dal(Urd Dal)', 'Black Gram(Urd Beans)(Whole)', 'Black pepper', 'Borehannu', 'Bottle gourd', 'Branch', 'Brinjal', 'Broken Rice', 'Broomstick(Jhadoo)', 'Bull', 'Bullar', 'Bunch Beans', 'Butter', 'Cabbage', 'Calf', 'Camel Hair', 'Cane', 'Capsicum', 'Cardamoms', 'Carnation', 'Carrot', 'Cashew Kernnel', 'Cashew Nuts', 'Castor Seed', 'Castor Seed', 'Cauliflower', 'Chansaur', 'Chapparad Avare', 'Chennangi Dal', 'Cherry', 'Chikoos(Sapota)', 'Chili Red', 'Chilly Capsicum', 'Chow Chow', 'Chrysanthemum', 'Chrysanthemum(Loose)', 'Cinamon(Dalchini)', 'Cloves', 'Cluster beans', 'Cocoa', 'Coconut', 'Coconut Oil', 'Coconut Seed', 'Coffee', 'Colacasia', 'Copra', 'Coriander(Leaves)', 'Corriander seed', 'Cotton', 'Cotton Seed', 'Cow', 'Cowpea (Lobia/Karamani)', 'Cowpea(Veg)', 'Cucumbar(Kheera)', 'Cummin Seed(Jeera)', 'Dalda', 'Delha', 'Dhaincha', 'Donda (Thondekai)', 'Drumstick', 'Dry Chillies', 'Dry Fodder', 'Dry Grapes', 'Duck', 'Duster Beans', 'Egg', 'Elephant Yam (Suran)', 'Field Pea', 'Fig(Anjura/Anjeer)', 'Firewood', 'Fish', 'Flower Brocoli', 'Fodder Seed', 'Forest Leaves', 'Fox Nut(Makhana)', 'French Beans(Frasbean)', 'Galgal(Lemon)', 'Garlic', 'Ghee', 'Gingelly Oil', 'Ginger(Dry)', 'Ginger(Green)', 'Gladiolus Bulb', 'Gladiolus Cut Flower', 'Goat', 'Goat Hair', 'Gram Raw(Chholia)', 'Gramflour', 'Grapes', 'Green Avare (W)', 'Green Chilli', 'Green Fodder', 'Green Gram Dal (Moong Dal)', 'Green Gram(Moong)(Whole)', 'Green Peas', 'Ground Nut Oil', 'Ground Nut Seed', 'Groundnut', 'Groundnut (Split)', 'Groundnut pods (raw)', 'Guar', 'Guar Seed(Cluster Beans Seed)', 'Guava', 'Gur(Jaggery)', 'Haldi Powder', 'Haralekai', 'He Buffalo', 'Hen', 'Hibiscus', 'Hide and skins', 'Honey', 'Indian Beans (Seam)', 'Indian Colza(Sarson)', 'Isabgul (Psyllium)', 'Jack Fruit', 'Jaffri', 'Jaggery', 'Jamamkhan', 'Jamun(Narale Hannu)', 'Jarbara', 'Jasmine', 'Javi', 'Jowar(Sorghum)', 'Jute', 'Jute Seed', 'Kabuli Chana(Chickpeas-White)', 'Kacholam', 'Kadaikanni', 'Kakada', 'Kankambra', 'Karamani', 'Karbuja(Musk Melon)', 'Kartali (Kankro)', 'Kevda', 'Kharif Mash', 'Khoya', 'Kinnow', 'Knool Khol', 'Kodo Millet(Varagu)', 'Kohlrabi', 'Kolinji', 'Koorka', 'Koura', 'Kulthi(Horse Gram)', 'Lak(Teora)', 'Leafy Vegetable', 'Lemon', 'Lentil (Masur)(Whole)', 'Lilly', 'Lime', 'Linseed', 'Litchi', 'Little gourd (Kundru)', 'Long Melon(Kakri)', 'Lotus', 'Lukad', 'Lupto', 'Macaroni wheat', 'Mace', 'Macheri', 'Mahua', 'Mahua Seed(Vippa chettu)', 'Maida Atta', 'Maize', 'Mango', 'Mango (Raw-Ripe)', 'Marigold(Calcutta)', 'Marigold(loose)', 'Marget', 'Mashrooms', 'Masur Dal', 'Mataki', 'Math (Bharmoth)', 'Maulsari', 'Meat', 'Methi Seeds', 'Methi(Leaves)', 'Millets', 'Mint(Pudina)', 'Moath Dal', 'Moth Bean(Matki)', 'Mousambi(Sweet Lime)', 'Mustard', 'Mustard Oil', 'Myrobolan(Harad)', 'Nearle Hannu', 'Neem Seed', 'Nelli Kai', 'Niger Seed (Ramtil)', 'Nutmeg', 'Onion', 'Onion Green', 'Orange', 'Orchid', 'Other Pulses', 'Ox', 'Paddy(Basmati)', 'Paddy(Common)', 'Papaya', 'Paprika', 'Peach', 'Pear(Marasebu)', 'Peas Wet', 'Peas cod', 'Pecan Nut', 'Pegeon Pea(Arhar Fali)', 'Pepper garbled', 'Pepper ungarbled', 'Pig', 'Pigeon Pea (Arhar Fali)', 'Pineapple', 'Plum', 'Pointed gourd (Parval)', 'Polherb', 'Pomegranate', 'Pomfret', 'Ponnanganni', 'Pork', 'Potato', 'Prawn', 'Ptarmigan', 'Puffed Rice', 'Pumpkin', 'Pundi', 'Puti', 'Raddish', 'Ragi (Finger Millet)', 'Raibel', 'Rajgir', 'Ram', 'Rat Tail Radish (Mogara)', 'Raya', 'Red Gram', 'Redfish', 'Ribbed Celery', 'Rice', 'Riccbia', 'Ridgeguard(Tori)', 'Rose(Local)', 'Rose(Loose))', 'Rubber', 'Safflower', 'Saffron', 'Sabu Daney', 'Saji', 'Same/Savi', 'Sandalwood', 'Sanhemp', 'Sapota', 'Sarsaparilla', 'Seetapal', 'Sesamum(Sesame,Gingelly,Til)', 'She Buffalo', 'She Goat', 'Sheep', 'Skin And Hide', 'Snakeguard', 'Soanf', 'Soapnut(Antawala/Ritha)', 'Sorgum(Jawar)', 'Soyabean', 'Spinach', 'Sponge gourd', 'Squash(Chappal Kadoo)', 'Strawberry', 'Suva (Dill Seed)', 'Suvarna Gadde', 'Sweet Potato', 'Sweet Pumpkin', 'T.V. Cumbu', 'Tamarind Fruit', 'Tamarind Seed', 'Tapioca', 'Taramira', 'Tea', 'Tejpatta', 'Tender Coconut', 'Thogrikai', 'Thondekai', 'Tinda', 'Tomato', 'Tube Rose(Double)', 'Tube Rose(Loose)', 'Tube Rose(Single)', 'Turmeric', 'Turnip', 'Vanilla', 'Walnut', 'Water Melon', 'Wheat', 'Wheat Atta', 'White Peas', 'Wood', 'Wool', 'Yam', 'Yam (Ratalu)', 'Zizyphus'
        ].sort();
    }

    async getMarkets(): Promise<string[]> {
        return [
            'Andaman and Nicobar', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli', 'Daman and Diu', 'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir', 'Jharkhand', 'Karnataka', 'Kerala', 'Lakshadweep', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
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

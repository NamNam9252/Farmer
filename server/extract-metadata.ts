import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

const apiKey = process.env.DATA_GOV_API_KEY;
const baseUrl = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';

async function extractMetadata() {
    try {
        const response = await axios.get(baseUrl, {
            params: {
                'api-key': apiKey,
                'format': 'json',
                'limit': 200 // Fetching 200 recent records
            }
        });

        const records = response.data.records || [];
        const commodities = [...new Set(records.map((r: any) => r.commodity))].sort();
        const markets = [...new Set(records.map((r: any) => r.market))].sort();

        console.log('UNIQUE_COMMODITIES:', JSON.stringify(commodities));
        console.log('UNIQUE_MARKETS:', JSON.stringify(markets));

    } catch (error: any) {
        console.error('ERROR:', error.message);
    }
}

extractMetadata();

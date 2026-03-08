import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

const apiKey = process.env.DATA_GOV_API_KEY;
const baseUrl = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';

async function findCommodity(name: string) {
    try {
        console.log(`Searching for any available data for: ${name}`);
        const response = await axios.get(baseUrl, {
            params: {
                'api-key': apiKey,
                'format': 'json',
                'limit': 10,
                'filters[commodity]': name
            }
        });

        const records = response.data.records || [];
        if (records.length > 0) {
            console.log(`Found ${records.length} records for ${name}`);
            console.log('Sample Market/State:', records[0].market, '/', records[0].state);
        } else {
            console.log(`No records found globally for ${name} with this exact name.`);

            // Try partial search
            console.log('Trying partial search...');
            const allRes = await axios.get(baseUrl, {
                params: {
                    'api-key': apiKey,
                    'format': 'json',
                    'limit': 1000
                }
            });
            const allRecords = allRes.data.records || [];
            const matches = allRecords.filter((r: any) => r.commodity.toLowerCase().includes(name.toLowerCase()));
            const uniqueMatches = [...new Set(matches.map((r: any) => r.commodity))];
            console.log('Potential matches in API:', uniqueMatches.join(', '));
        }
    } catch (error: any) {
        console.error('ERROR:', error.message);
    }
}

findCommodity('Almonds');

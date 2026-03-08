import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

const apiKey = process.env.DATA_GOV_API_KEY;
const baseUrl = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';

async function testApi() {
    console.log('Testing Agmarknet API with key:', apiKey);
    try {
        const response = await axios.get(baseUrl, {
            params: {
                'api-key': apiKey,
                'format': 'json',
                'limit': 100
            }
        });
        console.log('API_RESPONSE_STATUS:', response.status);
        console.log('RECORDS_COUNT:', response.data.records?.length);
        if (response.data.records && response.data.records.length > 0) {
            console.log('SAMPLE_RECORD:', JSON.stringify(response.data.records[0], null, 2));
        } else {
            console.log('NO_RECORDS_FOUND');
        }
    } catch (error: any) {
        console.error('API_ERROR:', error.response?.data || error.message);
    }
}

testApi();

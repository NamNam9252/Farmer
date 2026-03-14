import Groq from 'groq-sdk';
import { CropRecommendationInput, CropRecommendationReport, CropRecommendation } from '../../schema/crop-recommendation.schema.js';
import { MarketService } from '../market/market.service.js';
import { WeatherService } from '../weather/weather.service.js';

// ─── Indian Soil Map (State → Primary Soil Types) ───
const SOIL_MAP: Record<string, { type: string; typeHindi: string; description: string }> = {
    'Rajasthan': { type: 'Sandy/Arid', typeHindi: 'रेतीली/शुष्क', description: 'Sandy and arid soil, low water retention. Good for drought-resistant crops like Bajra, Mustard, Guar.' },
    'Punjab': { type: 'Alluvial', typeHindi: 'जलोढ़', description: 'Highly fertile alluvial soil from Indo-Gangetic plain. Excellent for Wheat, Rice, Sugarcane.' },
    'Haryana': { type: 'Alluvial', typeHindi: 'जलोढ़', description: 'Rich alluvial soil, good irrigation. Ideal for Wheat, Rice, Cotton, Mustard.' },
    'Uttar Pradesh': { type: 'Alluvial', typeHindi: 'जलोढ़', description: 'Deep alluvial deposits, very fertile. Best for Wheat, Rice, Sugarcane, Potato.' },
    'Bihar': { type: 'Alluvial', typeHindi: 'जलोढ़', description: 'Gangetic alluvial plains, highly fertile. Good for Rice, Wheat, Maize, Lentils.' },
    'West Bengal': { type: 'Alluvial/Deltaic', typeHindi: 'जलोढ़/डेल्टा', description: 'Delta alluvial soil, high moisture. Ideal for Rice, Jute, Tea.' },
    'Maharashtra': { type: 'Black (Regur)', typeHindi: 'काली (रेगुर)', description: 'Black cotton soil (regur), high clay content, retains moisture. Perfect for Cotton, Soybean, Sugarcane.' },
    'Gujarat': { type: 'Black/Alluvial', typeHindi: 'काली/जलोढ़', description: 'Mix of black and alluvial soil. Excellent for Cotton, Groundnut, Tobacco.' },
    'Madhya Pradesh': { type: 'Black (Regur)', typeHindi: 'काली (रेगुर)', description: 'Deep black soil, high fertility. Best for Soybean, Wheat, Cotton, Gram.' },
    'Karnataka': { type: 'Red/Laterite', typeHindi: 'लाल/लेटराइट', description: 'Red and laterite soil, moderate fertility. Good for Ragi, Coffee, Coconut, Sugarcane.' },
    'Tamil Nadu': { type: 'Red/Black', typeHindi: 'लाल/काली', description: 'Red loamy and black soil mix. Suitable for Rice, Sugarcane, Banana, Cotton.' },
    'Andhra Pradesh': { type: 'Red/Black', typeHindi: 'लाल/काली', description: 'Red and black soil regions. Good for Rice, Cotton, Chili, Tobacco.' },
    'Telangana': { type: 'Red/Black', typeHindi: 'लाल/काली', description: 'Red chalka and black soil. Best for Cotton, Rice, Maize, Turmeric.' },
    'Kerala': { type: 'Laterite', typeHindi: 'लेटराइट', description: 'Laterite soil, acidic and leached. Ideal for Rubber, Coconut, Tea, Spices.' },
    'Odisha': { type: 'Red/Alluvial', typeHindi: 'लाल/जलोढ़', description: 'Coastal alluvial and red soil inland. Good for Rice, Jute, Sugarcane.' },
    'Assam': { type: 'Alluvial/Forest', typeHindi: 'जलोढ़/वन', description: 'Alluvial with forest soil. Best for Tea, Rice, Jute, Bamboo.' },
    'Jharkhand': { type: 'Red/Laterite', typeHindi: 'लाल/लेटराइट', description: 'Red laterite soil, acidic. Good for Rice, Maize, Vegetables.' },
    'Chhattisgarh': { type: 'Red/Yellow', typeHindi: 'लाल/पीली', description: 'Red and yellow soil, moderate fertility. Best for Rice, Maize, Oilseeds.' },
    'Himachal Pradesh': { type: 'Mountain/Forest', typeHindi: 'पर्वतीय/वन', description: 'Mountain and forest soil, rich organic matter. Good for Apple, Wheat, Maize.' },
    'Uttarakhand': { type: 'Mountain/Alluvial', typeHindi: 'पर्वतीय/जलोढ़', description: 'Mountain soil in hills, alluvial in plains. Ideal for Basmati Rice, Wheat, Litchi.' },
    'Jammu & Kashmir': { type: 'Mountain/Alluvial', typeHindi: 'पर्वतीय/जलोढ़', description: 'Mountain meadow and alluvial valley soil. Best for Saffron, Apple, Walnut, Rice.' },
    'Goa': { type: 'Laterite', typeHindi: 'लेटराइट', description: 'Laterite coastal soil. Good for Coconut, Cashew, Rice.' },
    'Meghalaya': { type: 'Forest/Laterite', typeHindi: 'वन/लेटराइट', description: 'Forest and laterite soil, acidic. Good for Turmeric, Ginger, Potato.' },
    'Tripura': { type: 'Alluvial/Red', typeHindi: 'जलोढ़/लाल', description: 'Alluvial and red loam soil. Suitable for Rice, Rubber, Tea.' },
    'Manipur': { type: 'Mountain/Alluvial', typeHindi: 'पर्वतीय/जलोढ़', description: 'Hill and valley alluvial soil. Ideal for Rice, Maize, Fruits.' },
    'Nagaland': { type: 'Mountain/Forest', typeHindi: 'पर्वतीय/वन', description: 'Forest soil, rich humus. Good for Rice, Maize, Millets.' },
    'Mizoram': { type: 'Mountain/Forest', typeHindi: 'पर्वतीय/वन', description: 'Forest mountain soil. Good for Rice, Maize, Ginger.' },
    'Arunachal Pradesh': { type: 'Mountain/Forest', typeHindi: 'पर्वतीय/वन', description: 'Sub-alpine to tropical forest soil. Good for Rice, Maize, Millet, Oranges.' },
    'Sikkim': { type: 'Mountain/Forest', typeHindi: 'पर्वतीय/वन', description: 'High altitude forest soil, organic rich. Ideal for Cardamom, Ginger, Orange.' },
    'Ladakh': { type: 'Mountain/Cold Desert', typeHindi: 'पर्वतीय/शीत मरुस्थल', description: 'Sandy mountain desert soil, low organic matter, extreme cold. Ideal for Barley, Oats, Peas, Apricots.' },
};

// Reverse geocode lat/lng to Indian state
async function reverseGeocode(lat: number, lng: number): Promise<{ state: string; district: string }> {
    try {
        const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1&accept-language=en`,
            { headers: { 'User-Agent': 'KisanSaathi/1.0' } }
        );
        const data = await response.json() as any;
        return {
            state: data.address?.state || 'Unknown',
            district: data.address?.state_district || data.address?.county || 'Unknown',
        };
    } catch {
        return { state: 'Unknown', district: 'Unknown' };
    }
}

// Determine current Indian agricultural season
function getCurrentSeason(): "Kharif (June-Sept)" | "Rabi (Oct-Feb)" | "Zaid/Summer (March-May)" {
    const month = new Date().getMonth() + 1; // 1-12
    if (month >= 6 && month <= 10) return 'Kharif (June-Sept)' as any;
    if (month === 11 || month === 12 || month === 1 || month === 2) return 'Rabi (Oct-Feb)';
    return 'Zaid/Summer (March-May)';
}

function getDynamicCropsToFetch(season: string, state: string, temp: number): string[] {
    const isSouthOrEast = ['Kerala', 'Tamil Nadu', 'Karnataka', 'Assam', 'Meghalaya'].includes(state);
    const isMountainState = ['Ladakh', 'Himachal Pradesh', 'Uttarakhand', 'Jammu & Kashmir', 'Sikkim'].includes(state);

    // Hard Temperature Logic: If it's cold, prioritize cold-hardy crops regardless of state/season
    if (temp < 18 || isMountainState) {
        return ['Barley', 'Oats', 'Potato', 'Peas', 'Carrot', 'Apple', 'Apricot', 'Mustard'];
    }

    if (isSouthOrEast) {
        return ['Coconut', 'Rubber', 'Tea', 'Ginger', 'Cardamom', 'Banana', 'Black Pepper'];
    }

    if (season.includes('Zaid')) {
        return ['Watermelon', 'Cucumber', 'Moong Dal', 'Bitter Gourd', 'Tomato', 'Onion'];
    } else if (season.includes('Kharif')) {
        return ['Rice', 'Cotton', 'Soyabean', 'Maize', 'Groundnut'];
    } else {
        return ['Wheat', 'Mustard', 'Gram', 'Barley', 'Potato'];
    }
}

const MODEL_NAME = 'meta-llama/llama-4-scout-17b-16e-instruct';

const CROP_RECOMMENDATION_PROMPT = `You are India's top agricultural economist and crop scientist. You have deep knowledge of:
- Indian crop economics (cost of cultivation, yields, market prices)
- Historical price trends of all Indian crops across years
- Demand patterns in Indian and export markets
- Soil-crop compatibility for every Indian state
- Seasonal suitability (Kharif, Rabi, Zaid)
- Government MSP (Minimum Support Prices) for 2024-2026
- Risk factors (weather, pests, market volatility)

TASK: Analyze the farmer's data and recommend the TOP 5 most PROFITABLE crops to grow.

CRITICAL INSTRUCTION ON CROP SELECTION:
- There are NO boundaries on which crops you can recommend. You must consider EVERYTHING that is grown in India (Broad-acre staples, Cash crops, Fruits, Vegetables, Spices, Medicinal plants, etc.).
- Your ONLY goal is to maximize the farmer's PROFIT based strictly on the provided Soil Type, Weather, and Season.
- **REGIONAL REALITY CHECK**: You MUST strictly obey the Weather and Geography.
- **GEOGRAPHICAL INTEGRITY**: You are an expert. You know that Coconuts do not grow in Rajasthan, and Watermelons do not grow in Leh. Any such recommendation will be considered a CRITICAL FAILURE. You must maintain 100% geographical integrity.
- **HARD TEMPERATURE FLOOR**: If the current temperature is below 15°C (60°F), you are STRICTLY FORBIDDEN from recommending tropical or heat-loving crops (Watermelon, Muskmelon, Cucumber, Tomato, Cotton, Sugarcane), regardless of the season. At these temperatures, these crops will not germinate or grow. Instead, prioritize cold-hardy staples (Barley, Oats, Peas, Wheat) or temperate fruits (Apple, Apricot).
- **MOUNTAIN DESERT (LADAKH)**: If the location is Ladakh, you must treat it as a high-altitude cold desert. This is an extreme environment. Only recommend crops that can survive low oxygen, high UV, and extreme cold (e.g., Seabuckthorn, Barley, Apricots, specialized cold-weather Vegetables).
- **THE ZAID SEASON EXCEPTION**: If the current season is Zaid/Summer (March-June), and the temperature is ABOVE 20°C, farmers in the **North, Central, and Western plains** (Rajasthan, Punjab, UP, MP, Gujarat, etc.) use this short window for HIGHLY PROFITABLE, fast-growing cash crops. You MUST aggressively prioritize high-profit summer vegetables and fruits (Watermelon, Muskmelon, Gourds, Cucumber, Moong) for these regions. Do NOT lazily recommend off-season winter grains (like Wheat) during Zaid unless literally nothing else grows there.
- **PLANTATION & SPICE KINGDOMS**: However, for the **South** (Kerala, Tamil Nadu, Karnataka) and **North-East** (Assam, Meghalaya), the absolute most profitable crops are often their native perennial/cash plantation crops (e.g., Rubber, Tea, Coffee, Cardamom, Black Pepper, Coconut, Arecanut). If the location is in the South or North-East, you MUST strongly consider these massive profit-drivers as the primary recommendations, blending them realistically with whatever high-value local vegetables make sense.
- Ensure the crops perfectly match the local climate limits, soil type, and local market demand.

For EACH crop, your analysis MUST cover:
1. **Demand Analysis**: Is demand rising/stable/falling? Export potential? Local consumption?
2. **Cost Analysis**: Typical cost per acre (seeds, fertilizer, labor, irrigation)
3. **Revenue Analysis**: Expected yield × current market price = revenue per acre
4. **Profit Calculation**: Revenue - Cost = Profit per acre
5. **Historical Context**: How have prices trended over the last 2-3 years? Stable or volatile?
6. **Why This Crop**: Clear reasoning connecting soil type + climate + season + demand + profit

Return ONLY valid JSON. No markdown, no explanation — raw JSON only.

JSON structure:
{
    "recommendations": [
        {
            "rank": 1,
            "crop": "English crop name",
            "cropHindi": "Hindi crop name",
            "reason": "Detailed 2-3 sentence analysis in English explaining WHY this crop is profitable for this farmer — covering demand, soil fit, market price trends, and expected returns",
            "reasonHindi": "Same analysis in simple Hindi a farmer can understand",
            "demandLevel": "High",
            "estimatedCostPerAcre": "₹15,000-18,000",
            "estimatedRevenuePerAcre": "₹45,000-55,000",
            "estimatedProfitPerAcre": "₹27,000-37,000",
            "currentMarketPrice": "₹5,500/quintal",
            "bestSeason": "Rabi (Nov-Mar)",
            "riskLevel": "Low",
            "riskFactors": ["Late frost damage", "Storage pest infestation"],
            "growthDuration": "120-150 days"
        }
    ],
    "summary": "2-3 sentence overall summary in English explaining the recommendation strategy",
    "summaryHindi": "Same summary in simple Hindi"
}

STRICT RULES:
1. Recommend exactly 5 crops, ranked by estimated profit (highest first)
2. All prices must be realistic 2025-2026 Indian market prices in INR
3. Cost estimates must include: seeds, fertilizers, pesticides, labor, irrigation
4. Only recommend crops compatible with the given soil type and current season
5. If farmer provided preferred_crops, analyze those FIRST but still fill 5 total
6. demandLevel: exactly "Low", "Medium", or "High"
7. riskLevel: exactly "Low", "Medium", or "High"
8. Return ONLY the JSON. Nothing else.`;

export class CropRecommendationService {
    private groq: Groq;
    private marketService: MarketService;
    private weatherService: WeatherService;

    constructor() {
        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) throw new Error('GROQ_API_KEY is not set');
        this.groq = new Groq({ apiKey });
        this.marketService = new MarketService();
        this.weatherService = new WeatherService();
    }

    async generateRecommendation(input: CropRecommendationInput): Promise<CropRecommendationReport> {
        // Step 1: Reverse geocode location to state/district
        console.log(`[CropRecommendation] Reverse geocoding ${input.latitude}, ${input.longitude}...`);
        const geo = await reverseGeocode(input.latitude, input.longitude);
        console.log(`[CropRecommendation] Location: ${geo.district}, ${geo.state}`);

        // Step 2: Determine soil type (user override or auto-detect)
        let soilInfo: { type: string; typeHindi: string; description: string; source: 'auto-detected' | 'user-provided' };
        if (input.soil_type) {
            soilInfo = {
                type: input.soil_type,
                typeHindi: input.soil_type,
                description: `User-specified soil type: ${input.soil_type}`,
                source: 'user-provided',
            };
        } else {
            const mapped = SOIL_MAP[geo.state];
            soilInfo = mapped
                ? { ...mapped, source: 'auto-detected' as const }
                : { type: 'Unknown', typeHindi: 'अज्ञात', description: 'Could not determine soil type for this location.', source: 'auto-detected' as const };
        }
        console.log(`[CropRecommendation] Soil: ${soilInfo.type} (${soilInfo.source})`);

        // Step 3: Get current weather
        let weather = { temperature: 30, humidity: 50, rainfall_probability: 20 };
        try {
            const w = await this.weatherService.getWeather(input.latitude, input.longitude);
            weather = { temperature: w.temperature, humidity: w.humidity, rainfall_probability: w.rain_probability };
            console.log(`[CropRecommendation] Weather: ${weather.temperature}°C, ${weather.humidity}% humidity`);
        } catch (e) {
            console.log(`[CropRecommendation] Weather fetch failed, using defaults`);
        }

        // Step 4: Fetch current market prices
        // We fetch prices for the user's preferred crops, plus a dynamic list of relevant crops based on season/region
        // This gives the AI real-world market context without artificially biasing it towards off-season staples
        const currentSeason = getCurrentSeason();
        const dynamicCropList = getDynamicCropsToFetch(currentSeason, geo.state || '', weather.temperature);

        const cropsToCheck = input.preferred_crops
            ? [...new Set([...input.preferred_crops, ...dynamicCropList])].slice(0, 5)
            : dynamicCropList.slice(0, 5);

        const priceSnapshots: { crop: string; price: string; market: string; district: string; variety: string; date: string }[] = [];

        const pricePromises = cropsToCheck.map(async (crop: string) => {
            try {
                const result = await this.marketService.getMandiPrices({
                    commodity: crop,
                    state: geo.state || undefined,
                    district: geo.district !== 'Unknown' ? geo.district : undefined,
                });
                if (result.records.length > 0) {
                    const r = result.records[0];
                    console.log(`[CropRecommendation] SUCCESS [${result.searchStage}] - Price for ${crop}: ₹${r.modalPrice}/quintal at ${r.market}, ${r.district}`);
                    return {
                        crop: r.commodity,
                        price: `₹${r.modalPrice}/quintal`,
                        market: r.market,
                        district: r.district,
                        variety: r.variety,
                        date: r.arrivalDate,
                    };
                } else {
                    console.log(`[CropRecommendation] INFO - No live market price found for ${crop}. Using AI-driven profit estimation.`);
                }
            } catch (err) {
                console.log(`[CropRecommendation] ERROR - Failed to fetch price for ${crop}: ${err instanceof Error ? err.message : 'Unknown technical error'}`);
            }
            return null;
        });

        const results = await Promise.allSettled(pricePromises);
        for (const r of results) {
            if (r.status === 'fulfilled' && r.value) priceSnapshots.push(r.value);
        }

        console.log(`[CropRecommendation] Fetched prices for ${priceSnapshots.length} crops`);

        // Step 5: Build the AI prompt with all context
        const userContext = `
FARMER'S DATA:
- Location: ${geo.district}, ${geo.state}, India
- Latitude: ${input.latitude}, Longitude: ${input.longitude}
- Soil Type: ${soilInfo.type} — ${soilInfo.description}
- Current Weather: ${weather.temperature}°C, Humidity ${weather.humidity}%, Rain Probability ${weather.rainfall_probability}%
- Current Season: ${currentSeason}
- Date: ${new Date().toLocaleDateString('en-IN')}
${input.preferred_crops?.length ? `- Farmer's Preferred Crops: ${input.preferred_crops.join(', ')}` : ''}

CURRENT MARKET PRICES (from Agmarknet for requested crops):
${priceSnapshots.length > 0
                ? priceSnapshots.map(p => `- ${p.crop} (${p.variety}): ${p.price} at ${p.market}, ${p.district} (${p.date})`).join('\n')
                : '- AI MUST use its own deep knowledge of 2025-2026 Indian market prices to accurately estimate Revenue & Profit.'}

Based on ALL of the above — soil, climate, season, current market prices, demand trends, cost of cultivation, and profit potential — recommend the TOP 5 most profitable crops for this farmer.`;

        // Step 6: Call Groq AI
        console.log(`[CropRecommendation] Sending to Groq AI...`);

        const MAX_RETRIES = 3;
        let lastError: Error | null = null;

        for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
            try {
                const response = await this.groq.chat.completions.create({
                    model: MODEL_NAME,
                    messages: [
                        {
                            role: 'user',
                            content: CROP_RECOMMENDATION_PROMPT + '\n\n' + userContext,
                        }
                    ],
                    temperature: 0.3,
                    max_tokens: 3000,
                });

                const content = response.choices[0]?.message?.content ?? '';
                const parsed = this.parseJsonResponse(content);

                console.log(`[CropRecommendation] AI returned ${parsed.recommendations?.length || 0} recommendations`);
                if (parsed.recommendations && parsed.recommendations.length > 0) {
                    parsed.recommendations.forEach((r: any) => {
                        console.log(`  --> #${r.rank} ${r.crop} | Profit: ${r.estimatedProfitPerAcre} | Demand: ${r.demandLevel}`);
                    });
                }

                return {
                    location: {
                        latitude: input.latitude,
                        longitude: input.longitude,
                        state: geo.state,
                        district: geo.district,
                    },
                    soilInfo,
                    weather: {
                        temperature: weather.temperature,
                        humidity: weather.humidity,
                        rainfall_probability: weather.rainfall_probability,
                    },
                    currentSeason,
                    recommendations: parsed.recommendations || [],
                    summary: parsed.summary || 'Crop recommendations generated based on your location, soil, and market analysis.',
                    summaryHindi: parsed.summaryHindi || 'आपके स्थान, मिट्टी और बाजार विश्लेषण के आधार पर फसल सिफारिशें।',
                    generatedAt: new Date().toISOString(),
                };
            } catch (error) {
                const msg = error instanceof Error ? error.message : 'Unknown error';
                const isRateLimit = msg.includes('429') || msg.toLowerCase().includes('rate limit');

                if (isRateLimit && attempt < MAX_RETRIES) {
                    const waitSeconds = 30;
                    console.log(`[CropRecommendation] Rate limited. Waiting ${waitSeconds}s...`);
                    await new Promise(r => setTimeout(r, waitSeconds * 1000));
                    lastError = new Error(msg);
                    continue;
                }
                throw new Error(`Crop recommendation failed: ${msg}`);
            }
        }
        throw lastError ?? new Error('Crop recommendation failed after retries');
    }

    private parseJsonResponse(content: string): { recommendations: CropRecommendation[]; summary: string; summaryHindi: string } {
        try {
            const match = content.match(/\{[\s\S]*\}/);
            if (!match) throw new Error('No JSON found');
            return JSON.parse(match[0]);
        } catch {
            return {
                recommendations: [],
                summary: 'Could not generate recommendations. Please try again.',
                summaryHindi: 'सिफारिशें उत्पन्न नहीं हो सकीं। कृपया पुनः प्रयास करें।',
            };
        }
    }
}

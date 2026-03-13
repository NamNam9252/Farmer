import OpenAI from 'openai';
import { WeatherService } from '../weather/weather.service.js';
import { MarketplaceService } from '../marketplace-new/marketplace-new.service.js';
import { AdvisoryService } from '../advisory/advisory.service.js';
import { CropRecommendationService } from '../crop-recommendation/crop-recommendation.service.js';
import { DiseaseService } from '../disease/disease.service.js';
import * as CommunityService from '../community/community.service.js';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

type WeatherCard = {
    temp: number;
    condition: string;
    humidity?: number;
    rainProbability?: number;
};

type MarketPriceCard = {
    commodity: string;
    modalPrice: number | string;
    market?: string;
    unit?: string;
    date?: string;
};

type MarketplaceItemCard = {
    name: string;
    price: number | string;
    unit?: string;
    location?: string;
};

type CommunityCard = {
    name: string;
    memberCount: number | string;
};

type CropRecommendationCard = {
    name: string;
    profitEstimate?: string;
    marketPrice?: string;
};

type AdvisoryCard = {
    stage: string;
    action: string;
    reason: string;
    riskLevel: string;
};

type UserProfileCard = {
    name?: string | null;
    phone?: string | null;
    email?: string | null;
    role?: string | null;
};

const mapWeatherCard = (data: any): WeatherCard => {
    const condition = data?.overview || data?.forecast?.[0]?.summary || '';
    return {
        temp: data?.temperature ?? 0,
        condition,
        humidity: data?.humidity,
        rainProbability: data?.rain_probability,
    };
};

const mapMarketPriceCards = (records: any[]): MarketPriceCard[] => {
    return (records || []).map((item) => ({
        commodity: item?.commodity ?? 'Unknown',
        modalPrice: item?.modal_price ?? item?.modalPrice ?? item?.modalprice ?? '?',
        market: item?.market,
        unit: item?.unit,
        date: item?.arrival_date ?? item?.date,
    }));
};

const mapMarketplaceItemCards = (items: any[]): MarketplaceItemCard[] => {
    return (items || []).map((item) => ({
        name: item?.itemName ?? item?.title ?? item?.name ?? 'Unknown',
        price: item?.pricePerUnit ?? item?.price ?? '?',
        unit: item?.unit,
        location: item?.location,
    }));
};

const mapCommunityCards = (communities: any[]): CommunityCard[] => {
    return (communities || []).map((item) => ({
        name: item?.name ?? 'Unknown',
        memberCount: item?._count?.members ?? item?.memberCount ?? '?',
    }));
};

const mapCropRecommendationCards = (report: any): CropRecommendationCard[] => {
    const list = report?.recommendations || [];
    return list.map((crop: any) => ({
        name: crop?.crop ?? crop?.name ?? 'Unknown',
        profitEstimate: crop?.estimatedProfitPerAcre ?? crop?.profitEstimate,
        marketPrice: crop?.currentMarketPrice,
    }));
};

// ─── NVIDIA OpenAI-Compatible Client ─────────────────────────
const client = new OpenAI({
    baseURL: 'https://integrate.api.nvidia.com/v1',
    apiKey: process.env.NVIDIA_API_KEY || '',
});

// ─── Tool Definitions ────────────────────────────────────────
const TOOLS: OpenAI.Chat.Completions.ChatCompletionTool[] = [
    {
        type: 'function',
        function: {
            name: 'navigate_to_page',
            description: 'Navigate the user to a specific page/screen in the Farmer app. Use this when user wants to go to a page, see a feature, or open a section.',
            parameters: {
                type: 'object',
                properties: {
                    route: {
                        type: 'string',
                        enum: [
                            '/', '/disease', '/market', '/profile', '/advisory',
                            '/crop-recommendation', '/marketplace-new', '/marketplace-new/post-item',
                            '/marketplace-new/post-demand', '/marketplace-new/browse-items',
                            '/marketplace-new/browse-demands', '/marketplace-new/my-listings',
                            '/marketplace-new/purchase-requests', '/marketplace-new/demand-offers',
                            '/community',
                        ],
                        description: 'The route path to navigate to',
                    },
                    description: {
                        type: 'string',
                        description: 'Human-readable description of where you are navigating the user',
                    },
                },
                required: ['route', 'description'],
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'get_weather',
            description: 'Get current weather and 5-day forecast for a location. Returns temperature, humidity, rain probability, daily forecast, and hourly forecast. Note: Alerts and AI overviews may be empty on the free plan.',
            parameters: {
                type: 'object',
                properties: {
                    latitude: { type: 'number', description: 'Latitude of location' },
                    longitude: { type: 'number', description: 'Longitude of location' },
                },
                required: ['latitude', 'longitude'],
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'get_market_prices',
            description: 'Get mandi (marketplace) prices for crops. Use when user asks about crop prices, mandi rates, market prices.',
            parameters: {
                type: 'object',
                properties: {
                    state: { type: 'string', description: 'State name (e.g. "Uttar Pradesh")' },
                    district: { type: 'string', description: 'District name (optional)' },
                    commodity: { type: 'string', description: 'Crop/commodity name (e.g. "Wheat", "Rice")' },
                },
                required: ['state'],
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'list_marketplace_items',
            description: 'Browse items available for sale on the marketplace. Use when user wants to see what is available to buy.',
            parameters: {
                type: 'object',
                properties: {
                    category: { type: 'string', description: 'Filter by category (optional)' },
                    maxPrice: { type: 'number', description: 'Maximum price filter (optional)' },
                },
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'create_marketplace_listing',
            description: 'Create a new item listing for selling on the marketplace. Use when user wants to sell something. ALWAYS confirm with user before creating.',
            parameters: {
                type: 'object',
                properties: {
                    itemName: { type: 'string', description: 'Name of the item to sell' },
                    description: { type: 'string', description: 'Description of the item' },
                    pricePerUnit: { type: 'number', description: 'Price per unit in INR' },
                    unit: { type: 'string', enum: ['KG', 'QUINTAL', 'TON', 'PIECE', 'DOZEN', 'BUNDLE', 'BAG', 'LITER', 'OTHER'], description: 'Unit of measurement' },
                    quantityAvailable: { type: 'number', description: 'Quantity available for sale' },
                    category: { type: 'string', enum: ['CROPS', 'FRUITS', 'VEGETABLES', 'GRAINS', 'SEEDS', 'FERTILIZERS', 'PESTICIDES', 'FARMING_EQUIPMENT', 'LIVESTOCK_PRODUCTS', 'OTHER'], description: 'Category of the item' },
                    location: { type: 'string', description: 'Pickup location' },
                },
                required: ['itemName', 'pricePerUnit', 'unit', 'quantityAvailable', 'category', 'location'],
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'create_demand_post',
            description: 'Post a demand/buy request on the marketplace. Use when user wants to buy something specific.',
            parameters: {
                type: 'object',
                properties: {
                    itemName: { type: 'string', description: 'Name of item needed' },
                    description: { type: 'string', description: 'Description of demand' },
                    expectedPrice: { type: 'number', description: 'Expected price per unit in INR' },
                    unit: { type: 'string', enum: ['KG', 'QUINTAL', 'TON', 'PIECE', 'DOZEN', 'BUNDLE', 'BAG', 'LITER', 'OTHER'], description: 'Unit' },
                    quantityNeeded: { type: 'number', description: 'Quantity needed' },
                    location: { type: 'string', description: 'Delivery/Preferred location' },
                    category: { type: 'string', enum: ['CROPS', 'FRUITS', 'VEGETABLES', 'GRAINS', 'SEEDS', 'FERTILIZERS', 'PESTICIDES', 'FARMING_EQUIPMENT', 'LIVESTOCK_PRODUCTS', 'OTHER'], description: 'Category' },
                },
                required: ['itemName', 'expectedPrice', 'unit', 'quantityNeeded', 'category', 'location'],
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'list_communities',
            description: 'Find nearby farmer communities. Use when user asks about communities, groups, forums near them.',
            parameters: {
                type: 'object',
                properties: {
                    latitude: { type: 'number', description: 'Latitude' },
                    longitude: { type: 'number', description: 'Longitude' },
                    radiusKm: { type: 'number', description: 'Search radius in km (default 50)' },
                },
                required: ['latitude', 'longitude'],
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'join_community',
            description: 'Join a specific community by its ID. ALWAYS confirm with user before joining.',
            parameters: {
                type: 'object',
                properties: {
                    communityId: { type: 'string', description: 'ID of the community to join' },
                    communityName: { type: 'string', description: 'Name of the community (for display)' },
                },
                required: ['communityId'],
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'get_crop_recommendation',
            description: 'Get AI-powered crop recommendation based on location, soil, and climate. Use when user asks what to grow, crop suggestions. Providing soil or season is optional as they are auto-detected.',
            parameters: {
                type: 'object',
                properties: {
                    latitude: { type: 'number', description: 'Latitude' },
                    longitude: { type: 'number', description: 'Longitude' },
                    soilType: { type: 'string', description: 'Type of soil' },
                    preferredCrops: { type: 'array', items: { type: 'string' }, description: 'Specific crops user is interested in' },
                },
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'get_advisory',
            description: 'Get farming advisory/recommendations based on current conditions. Use when user asks for farming advice.',
            parameters: {
                type: 'object',
                properties: {
                    crop_name: { type: 'string', description: 'Name of the crop' },
                    days_since_sowing: { type: 'number', description: 'Days since the crop was sown' },
                    soil_moisture: { type: 'string', enum: ['low', 'medium', 'high'], description: 'Current soil moisture level' },
                    temperature: { type: 'number', description: 'Current temperature in °C' },
                    humidity: { type: 'number', description: 'Current humidity %' },
                    rain_probability: { type: 'number', description: 'Rain probability %' },
                    pest_reported: { type: 'boolean', description: 'Whether pest activity is reported' },
                    soil_n: { type: 'string', enum: ['low', 'medium', 'high'], description: 'Soil nitrogen level' },
                    soil_p: { type: 'string', enum: ['low', 'medium', 'high'], description: 'Soil phosphorus level' },
                    soil_k: { type: 'string', enum: ['low', 'medium', 'high'], description: 'Soil potassium level' },
                },
                required: ['crop_name', 'days_since_sowing', 'soil_moisture', 'temperature', 'humidity', 'rain_probability', 'pest_reported', 'soil_n', 'soil_p', 'soil_k'],
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'get_user_profile',
            description: 'Get the current logged-in user profile information. Use when user asks about their account, profile, details.',
            parameters: {
                type: 'object',
                properties: {},
            },
        },
    },
    {
        type: 'function',
        function: {
            name: 'analyze_crop_disease',
            description: 'Analyze an uploaded image of a crop to detect diseases. Use when user uploads a photo of a sick plant or asks for disease diagnosis.',
            parameters: {
                type: 'object',
                properties: {
                    cropType: { type: 'string', description: 'Type of crop (e.g. Tomato, Wheat)' },
                },
            },
        },
    },
];

// ─── System Prompt ───────────────────────────────────────────
const getSystemPrompt = (lat?: number, lng?: number, imagePath?: string) => `You are **KrishiMitra** (कृषिमित्र), the intelligent AI assistant for the "Farmer One Stop Solution" app. You help Indian farmers in both Hindi and English.

${lat && lng ? `## User Context:
- Current Latitude: ${lat}
- Current Longitude: ${lng}
(Use these coordinates for weather, market prices, and communities unless the user specifies otherwise.)` : ''}

${imagePath ? `## Visual Context:
- AN IMAGE IS ATTACHED to this message.
- If the user asks what it is or asks about disease, use the "analyze_crop_disease" tool.
- If the user wants to sell what's in the image, proceed with "create_marketplace_listing" and use the image as the listing's reference.` : ''}

## Your Capabilities:
You can perform ANY action a user can do manually in the app:
1. **Navigate** — Send users to any page (home, disease detection, market, marketplace, community, advisory, crop recommendation, profile)
2. **Weather** — Fetch real-time weather data for any location
3. **Market Prices** — Get live mandi/crop prices from across India
4. **Marketplace** — Browse items for sale, create sell listings, post buy demands
5. **Communities** — Find, browse, and join farmer communities
6. **Crop Advice** — AI-powered crop recommendations based on soil and season
7. **Advisory** — Farming advisory based on current field conditions
8. **Profile** — View user profile information

## Rules:
- Respond in the SAME LANGUAGE the user uses. If they speak Hindi, reply in Hindi. If English, reply in English.
- **Use Markdown Formatting**: Always use markdown to make your responses readable. 
  - Use **bold** for emphasis or key terms.
  - Use bullet points or numbered lists for steps or lists of items.
  - Use ### Headers to organize long responses.
- **STRICT: Do NOT use Markdown tables.** Tables do not fit on mobile screens.
- For comparisons, use short bullet lists or compact key-value lines instead.
- For WRITE operations (creating listings, joining communities), ALWAYS call the tool with type "confirm" so the user sees a confirmation popup BEFORE the action happens.
- When navigating, briefly explain what the page does.
- When the user query is ambiguous, ask clarifying questions. For example, if they say "sell wheat" — ask about price, quantity, unit.
- Keep responses concise and farmer-friendly. Avoid jargon.
- If you don't have enough info to call a tool (e.g. no lat/lon for weather), ask the user for the missing information or suggest using the app's location.
- For marketplace listings: ask about item name, price, unit, quantity, and category step by step if user hasn't provided them.
- You can see images if the user sends one — describe what you see and suggest disease analysis if it's a crop image.

## Available Pages:
- Home (/) — Main dashboard
- Disease Detection (/disease) — Upload crop photos for AI disease analysis
- Market (/market) — Live mandi prices
- Marketplace (/marketplace-new) — Buy/sell farm products
- Post Item (/marketplace-new/post-item) — Sell something
- Post Demand (/marketplace-new/post-demand) — Post a buy request
- Browse Items (/marketplace-new/browse-items) — Browse things for sale
- Community (/community) — Farmer communities and chat
- Advisory (/advisory) — Smart farming advice
- Crop Recommendation (/crop-recommendation) — AI crop suggestions
- Profile (/profile) — User account

Be helpful, warm, and proactive. You are the farmer's best digital companion! 🌾`;

// ─── Service Instances ───────────────────────────────────────
const weatherService = new WeatherService();
const marketplaceService = new MarketplaceService();
const advisoryService = new AdvisoryService();
const cropRecommendationService = new CropRecommendationService();
const diseaseService = new DiseaseService();

// ─── Tool Executor ───────────────────────────────────────────
interface AgentAction {
    type: 'navigate' | 'confirm' | 'display_data' | 'text';
    route?: string;
    dataType?: string;
    data?: any;
    confirmAction?: string;
    confirmPayload?: any;
    message?: string;
}

interface AgentResponse {
    message: string;
    action?: AgentAction;
}

async function executeTool(
    toolName: string,
    args: any,
    userId: string,
    ambientLocation?: { lat?: number; lng?: number; imagePath?: string }
): Promise<{ result: any; action?: AgentAction }> {
    switch (toolName) {
        case 'navigate_to_page': {
            return {
                result: { navigated: true, route: args.route, description: args.description },
                action: {
                    type: 'navigate',
                    route: args.route,
                    message: args.description,
                },
            };
        }

        case 'get_weather': {
            try {
                const lat = args.latitude ?? ambientLocation?.lat;
                const lng = args.longitude ?? ambientLocation?.lng;
                
                if (!lat || !lng) {
                    return { result: { error: 'Location coordinates missing' } };
                }

                const data = await weatherService.getWeather(lat, lng);
                const cardData = mapWeatherCard(data);
                return {
                    result: data,
                    action: {
                        type: 'display_data',
                        dataType: 'weather',
                        data: cardData,
                    },
                };
            } catch (error: any) {
                return { result: { error: 'Failed to fetch weather: ' + error.message } };
            }
        }

        case 'get_market_prices': {
            try {
                // Use the Data.gov.in API directly for market prices
                const apiKey = process.env.DATA_GOV_API_KEY;
                let url = `https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=${apiKey}&format=json&limit=10`;
                if (args.state) url += `&filters[state]=${encodeURIComponent(args.state)}`;
                if (args.district) url += `&filters[district]=${encodeURIComponent(args.district)}`;
                if (args.commodity) url += `&filters[commodity]=${encodeURIComponent(args.commodity)}`;

                const res = await fetch(url);
                const data = await res.json() as any;
                const records = data.records || [];

                const slice = records.slice(0, 10);
                const cardData = mapMarketPriceCards(slice);
                return {
                    result: slice,
                    action: {
                        type: 'display_data',
                        dataType: 'market_prices',
                        data: cardData,
                    },
                };
            } catch (error: any) {
                return { result: { error: 'Failed to fetch market prices: ' + error.message } };
            }
        }

        case 'list_marketplace_items': {
            try {
                const filters: any = { excludeUserId: userId };
                if (args.category) filters.category = args.category;
                if (args.maxPrice) filters.maxPrice = args.maxPrice;
                const items = await marketplaceService.getItems(filters);
                const cardData = mapMarketplaceItemCards(items);
                return {
                    result: items,
                    action: {
                        type: 'display_data',
                        dataType: 'marketplace_items',
                        data: cardData,
                    },
                };
            } catch (error: any) {
                return { result: { error: 'Failed to fetch marketplace items: ' + error.message } };
            }
        }

        case 'create_marketplace_listing': {
            // Don't execute — return confirmation action
                return {
                    result: { status: 'awaiting_confirmation', listing: args },
                    action: {
                        type: 'confirm',
                        confirmAction: 'create_marketplace_listing',
                        confirmPayload: {
                            itemName: args.itemName,
                            description: args.description,
                            pricePerUnit: args.pricePerUnit,
                            unit: args.unit,
                            quantityAvailable: args.quantityAvailable,
                            category: args.category,
                            location: args.location,
                        },
                        message: `Create listing: ${args.itemName} at ₹${args.pricePerUnit}/${args.unit}?`,
                    },
                };
        }

        case 'create_demand_post': {
                return {
                    result: { status: 'awaiting_confirmation', demand: args },
                    action: {
                        type: 'confirm',
                        confirmAction: 'create_demand_post',
                        confirmPayload: {
                            itemName: args.itemName,
                            description: args.description,
                            expectedPrice: args.expectedPrice || args.budgetPerUnit,
                            unit: args.unit,
                            quantityNeeded: args.quantityNeeded,
                            category: args.category,
                            location: args.location,
                        },
                        message: `Post demand: ${args.itemName}, budget ₹${args.expectedPrice || args.budgetPerUnit}/${args.unit}?`,
                    },
                };
        }

        case 'list_communities': {
            try {
                const lat = args.latitude ?? ambientLocation?.lat;
                const lng = args.longitude ?? ambientLocation?.lng;

                if (!lat || !lng) {
                     return { result: { error: 'Location coordinates missing' } };
                }

                const communities = await CommunityService.getNearbyCommunities(
                    lat,
                    lng,
                    args.radiusKm || 50
                );
                const cardData = mapCommunityCards(communities);
                return {
                    result: communities,
                    action: {
                        type: 'display_data',
                        dataType: 'communities',
                        data: cardData,
                    },
                };
            } catch (error: any) {
                return { result: { error: 'Failed to fetch communities: ' + error.message } };
            }
        }

        case 'join_community': {
            return {
                result: { status: 'awaiting_confirmation', communityId: args.communityId },
                action: {
                    type: 'confirm',
                    confirmAction: 'join_community',
                    confirmPayload: { communityId: args.communityId },
                    message: `Join community "${args.communityName || args.communityId}"?`,
                },
            };
        }

        case 'get_crop_recommendation': {
            try {
                const lat = args.latitude ?? ambientLocation?.lat;
                const lng = args.longitude ?? ambientLocation?.lng;

                if (!lat || !lng) {
                    return { result: { error: 'Location coordinates missing' } };
                }

                const report = await cropRecommendationService.generateRecommendation({
                    latitude: lat,
                    longitude: lng,
                    soil_type: args.soilType,
                    preferred_crops: args.preferredCrops,
                });
                const cardData = mapCropRecommendationCards(report);
                return {
                    result: report,
                    action: {
                        type: 'display_data',
                        dataType: 'crop_recommendation',
                        data: { recommendations: cardData },
                        route: '/crop-recommendation',
                    },
                };
            } catch (error: any) {
                return { result: { error: 'Failed to generate crop recommendation: ' + error.message } };
            }
        }

        case 'get_advisory': {
            try {
                const recs = advisoryService.getRecommendation(args);
                const cardData: AdvisoryCard[] = (recs || []).map((r) => ({
                    stage: r.stage,
                    action: r.action,
                    reason: r.reason,
                    riskLevel: r.riskLevel,
                }));
                return {
                    result: recs,
                    action: {
                        type: 'display_data',
                        dataType: 'advisory',
                        data: cardData,
                    },
                };
            } catch (error: any) {
                return { result: { error: 'Failed to get advisory: ' + error.message } };
            }
        }

        case 'get_user_profile': {
            try {
                const user = await prisma.user.findUnique({
                    where: { id: userId },
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                        email: true,
                        role: true,
                        status: true,
                        preferredLanguage: true,
                        profileImageUrl: true,
                        createdAt: true,
                        farmerProfile: true,
                    },
                });
                const cardData: UserProfileCard = {
                    name: user?.name ?? null,
                    phone: user?.phone ?? null,
                    email: user?.email ?? null,
                    role: user?.role ?? null,
                };
                return {
                    result: user,
                    action: {
                        type: 'display_data',
                        dataType: 'user_profile',
                        data: cardData,
                    },
                };
            } catch (error: any) {
                return { result: { error: 'Failed to fetch profile: ' + error.message } };
            }
        }

        case 'analyze_crop_disease': {
            try {
                if (!ambientLocation?.imagePath) {
                    return { result: { error: 'No image found to analyze. Please upload a photo of the crop.' } };
                }

                const result = await diseaseService.analyzeImage(
                    ambientLocation.imagePath,
                    args.cropType,
                    'en'
                );

                return {
                    result,
                    action: {
                        type: 'display_data',
                        dataType: 'crop_disease_analysis',
                        data: result,
                    },
                };
            } catch (error: any) {
                return { result: { error: 'Disease analysis failed: ' + error.message } };
            }
        }

        default:
            return { result: { error: `Unknown tool: ${toolName}` } };
    }
}

// ─── Confirm Action Executor ─────────────────────────────────
export async function executeConfirmedAction(
    userId: string,
    action: string,
    payload: any
): Promise<any> {
    switch (action) {
        case 'create_marketplace_listing': {
            const mappedPayload = { ...payload };
            if (payload.quantityAvailable && !payload.quantity) {
                mappedPayload.quantity = payload.unit ? `${payload.quantityAvailable} ${payload.unit}` : String(payload.quantityAvailable);
            }
            return marketplaceService.createItem(userId, mappedPayload);
        }
        case 'create_demand_post': {
            const mappedPayload = { ...payload };
            if (payload.budgetPerUnit && !payload.expectedPrice) {
                mappedPayload.expectedPrice = payload.budgetPerUnit;
            }
            if (payload.expectedPrice && !payload.budgetPerUnit) {
                mappedPayload.budgetPerUnit = payload.expectedPrice;
            }
            if (typeof payload.quantityNeeded === 'number') {
                mappedPayload.quantityNeeded = payload.unit ? `${payload.quantityNeeded} ${payload.unit}` : String(payload.quantityNeeded);
            }
            return marketplaceService.createDemand(userId, mappedPayload);
        }
        case 'join_community':
            return CommunityService.joinCommunity(userId, payload.communityId);
        default:
            throw new Error(`Unknown confirmed action: ${action}`);
    }
}

// ─── Main Chat Handler ──────────────────────────────────────
export interface ChatMessage {
    role: 'user' | 'assistant' | 'system';
    content: string;
}

export async function handleChat(
    userId: string,
    message: string,
    conversationHistory: ChatMessage[] = [],
    lat?: number,
    lng?: number,
    imagePath?: string
): Promise<AgentResponse> {
    // Build messages array
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
        { role: 'system', content: getSystemPrompt(lat, lng, imagePath) },
        ...conversationHistory.map((m) => ({
            role: m.role as 'user' | 'assistant' | 'system',
            content: m.content,
        })),
        { role: 'user', content: message },
    ];

    try {
        // First call — may include tool calls
        const response = await client.chat.completions.create({
            model: 'openai/gpt-oss-120b',
            messages,
            tools: TOOLS,
            tool_choice: 'auto',
            temperature: 0.7,
            max_tokens: 1024,
        });

        const choice = response.choices[0];

        // If no tool calls, return plain text
        if (!choice.message.tool_calls || choice.message.tool_calls.length === 0) {
            return {
                message: choice.message.content || 'I could not process that request.',
            };
        }

        // Execute the first tool call
        const toolCall: any = choice.message.tool_calls[0];
        const toolArgs = JSON.parse(toolCall.function.arguments);
        const { result, action } = await executeTool(
            toolCall.function.name, 
            toolArgs, 
            userId, 
            { lat, lng, imagePath }
        );

        // Feed tool result back to model for natural language response
        const followUpMessages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
            ...messages,
            choice.message as any,
            {
                role: 'tool',
                tool_call_id: toolCall.id,
                content: JSON.stringify(result),
            },
        ];

        const followUp = await client.chat.completions.create({
            model: 'openai/gpt-oss-120b',
            messages: followUpMessages,
            temperature: 0.7,
            max_tokens: 1024,
        });

        const finalMessage = followUp.choices[0].message.content || 'Done!';

        return {
            message: finalMessage,
            action,
        };
    } catch (error: any) {
        console.error('Agent error:', error);
        return {
            message: `Sorry, I encountered an error: ${error.message}. Please try again.`,
        };
    }
}

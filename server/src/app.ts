import express from 'express';
import cors from 'cors';
import { errorMiddleware } from './middleware/error.middleware.js';
import { loggerMiddleware } from './middleware/logger.middleware.js';
import v1Routes from './routes.js';
import { SMS, smsRouter } from './modules/sms/index.js'; // 👈 ADD THIS

const app = express();

// middleware
app.use(loggerMiddleware);
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 👇 ADD THIS — init SMS before routes
SMS.init();

// Load versioned routes
app.use('/api/v1', v1Routes);

// 👇 ADD THIS — mount SMS webhook at the right endpoint
app.use('/api/v1/sms', smsRouter);

// 👇 ADD THIS — your incoming SMS listener
SMS.onMessage(async (action, payload, from) => {
    console.log(`[SMS] action="${action}" from=${from}`);

    switch (action) {
        case 'advisory':
            // return await getAdvisory(payload);

        case 'crop':
            // return await getCropRecommendation(payload);

        case 'weather':
            // return await getWeather(payload);

        case 'market':
            // return await getMarketPrice(payload);

        case 'disease':
            // return await getDiseaseInfo(payload);

        case 'schemes':
            // return await getSchemes(payload);

        default:
            throw new Error(`Unknown SMS action: ${action}`);
    }
});

// Base route
app.get('/', (_req, res) => {
    res.json({ message: 'AgriAI API v1', success: true });
});

app.get('/api/v1', (_req, res) => {
    res.json({ message: 'AgriAI API v1 - Running', success: true });
});

// Final error handling middleware
app.use(errorMiddleware);

export default app;
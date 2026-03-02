import express from 'express';
import cors from 'cors';
import { errorMiddleware } from './middleware/error.middleware.js';
import { loggerMiddleware } from './middleware/logger.middleware.js';
import v1Routes from './routes.js';

const app = express();

// middleware
app.use(loggerMiddleware);
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Load versioned routes
app.use('/api/v1', v1Routes);

// Base route
app.get('/', (_req, res) => {
    res.json({ message: 'Kisan Saathi API v1', success: true });
});

app.get('/api/v1', (_req, res) => {
    res.json({ message: 'Kisan Saathi API v1 - Running', success: true });
});

// Final error handling middleware
app.use(errorMiddleware);

export default app;

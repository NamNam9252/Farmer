import express from 'express';
import cors from 'cors';
import { errorMiddleware } from './middleware/error.middleware.js';
import v1Routes from './routes.js';

const app = express();

// middleware
app.use(cors());
app.use(express.json());

// Load versioned routes
app.use('/api/v1', v1Routes);

// Base route
app.get('/', (req, res) => {
    res.send({ message: 'Hello from server!' });
});

// Final error handling middleware
app.use(errorMiddleware);

export default app;

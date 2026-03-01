import './src/core/config/env';
import express from 'express';
import cors from 'cors';
import diseaseRoutes from './src/modules/disease/disease.routes';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

app.get('/', (_req, res) => {
  res.json({ message: 'Kisan Saathi API v1', success: true });
});

app.get('/api/v1', (_req, res) => {
  res.json({ message: 'Kisan Saathi API v1 - Running', success: true });
});

app.use('/api/v1/disease', diseaseRoutes);

app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('[Error]', err.message);
  res.status(500).json({
    success: false,
    message: err.message || 'Internal server error',
  });
});

app.listen(port, () => {
  console.log(`✅ Kisan Saathi Server running at http://localhost:${port}`);
  console.log(`   Disease API → POST http://localhost:${port}/api/v1/disease/analyze`);
});

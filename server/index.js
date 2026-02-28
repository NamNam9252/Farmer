import express from 'express';
import cors from 'cors';

const app = express();
const port = process.env.PORT || 3000;

// middleware
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.send({ message: 'Hello from server!' });
});

// example endpoint
app.get('/api/time', (req, res) => {
  res.json({ time: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`);
});

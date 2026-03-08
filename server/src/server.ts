import 'dotenv/config';
import http from 'http';
import app from './app.js';
import { setupSocket } from './socket.js';

const port = process.env.PORT || 3000;

const server = http.createServer(app);
setupSocket(server);

server.listen(port, () => {
    console.log(`Server listening on http://localhost:${port}`);
});

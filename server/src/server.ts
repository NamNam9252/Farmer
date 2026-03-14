import dotenv from "dotenv";
import fs from "fs";
import http from "http";
import path from "path";
import app from "./app.js";
import { setupSocket } from "./socket.js";
import { start_crawler } from "./core/jobs/news-crawler.job.js";

const envCandidates = [
  path.resolve(process.cwd(), ".env"),
  path.resolve(process.cwd(), "server", ".env"),
];

const envPath = envCandidates.find((candidate) => fs.existsSync(candidate)) ?? envCandidates[0];
dotenv.config({ path: envPath });

const port = process.env.PORT || 3000;

const server = http.createServer(app);
setupSocket(server);

server.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`);
  console.log(`[ENV] Loaded .env from ${envPath} | NVIDIA_API_KEY=${process.env.NVIDIA_API_KEY ? "SET" : "MISSING"}`);
  start_crawler();
});

import { Router } from 'express';
import { chat, confirmAction } from './agent.controller.js';
import { requireAuth } from '../../middleware/auth.middleware.js';
import multer from 'multer';
import * as path from 'path';
import * as fs from 'fs';

const uploadsDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `agent_${Date.now()}${ext}`);
  },
});

const upload = multer({ storage });

const router = Router();

router.use(requireAuth);

// POST /api/v1/agent/chat — Send a message to the AI agent
router.post('/chat', upload.single('image'), chat);

// POST /api/v1/agent/confirm — Execute a confirmed action (after user approves)
router.post('/confirm', confirmAction);

export default router;

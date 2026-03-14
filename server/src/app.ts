import express from 'express';
import cors from 'cors';
import OpenAI from 'openai';
import { errorMiddleware } from './middleware/error.middleware.js';
import { loggerMiddleware } from './middleware/logger.middleware.js';
import v1Routes from './routes.js';
import { SMS, smsRouter } from './modules/sms/index.js'; // 👈 ADD THIS

const SMS_SINGLE_MESSAGE_BUDGET = 160;
const SMS_REPLY_MAX_CHARS = 280;
const SMS_MODEL_NAME = 'openai/gpt-oss-120b';
const SMS_LOG_PREVIEW = 180;
const SMS_CHUNK_SEND_DELAY_MS = 1200;
const SMS_REQUIRED_PREFIX = ')]k';

const nvidiaClient = new OpenAI({
    baseURL: 'https://integrate.api.nvidia.com/v1',
    apiKey: process.env.NVIDIA_API_KEY || '',
});

const fitToCharLimit = (value: string, limit: number): string => {
    if (value.length <= limit) return value;
    const trimmed = value.slice(0, limit).trim();
    const lastSentenceBreak = Math.max(trimmed.lastIndexOf('.'), trimmed.lastIndexOf('!'), trimmed.lastIndexOf('?'));
    if (lastSentenceBreak >= Math.floor(limit * 0.6)) {
        return trimmed.slice(0, lastSentenceBreak + 1).trim();
    }
    return trimmed;
};

const sleep = (ms: number): Promise<void> =>
    new Promise((resolve) => setTimeout(resolve, ms));

const splitForSingleSms = (text: string, budget: number): string[] => {
    const compact = text.trim().replace(/\s+/g, ' ');
    if (!compact) return [''];

    const parts: string[] = [];
    let current = '';

    const pushCurrent = (): void => {
        if (current.trim()) {
            parts.push(current.trim());
        }
        current = '';
    };

    for (const word of compact.split(' ')) {
        const candidate = current ? `${current} ${word}` : word;
        const smsBytes = Buffer.byteLength(candidate, 'utf-8');

        if (smsBytes <= budget) {
            current = candidate;
            continue;
        }

        if (current) {
            pushCurrent();
        }

        let token = word;
        while (token) {
            let low = 1;
            let high = token.length;
            let best = 0;

            while (low <= high) {
                const mid = Math.floor((low + high) / 2);
                const slice = token.slice(0, mid);
                const ok = Buffer.byteLength(slice, 'utf-8') <= budget;
                if (ok) {
                    best = mid;
                    low = mid + 1;
                } else {
                    high = mid - 1;
                }
            }

            if (best === 0) {
                best = 1;
            }

            parts.push(token.slice(0, best));
            token = token.slice(best);
        }
    }

    pushCurrent();
    return parts;
};

const trimToByteBudget = (text: string, budget: number): string => {
    if (Buffer.byteLength(text, 'utf-8') <= budget) return text;

    let low = 0;
    let high = text.length;
    let best = '';

    while (low <= high) {
        const mid = Math.floor((low + high) / 2);
        const candidate = text.slice(0, mid).trimEnd();
        if (Buffer.byteLength(candidate, 'utf-8') <= budget) {
            best = candidate;
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }

    return best;
};

const withSequencePrefix = (chunks: string[], budget: number): string[] => {
    if (chunks.length <= 1) return chunks;

    return chunks.map((chunk, index) => {
        const prefix = `${index + 1}/${chunks.length} `;
        const allowedBodyBytes = budget - Buffer.byteLength(prefix, 'utf-8');
        const body = allowedBodyBytes > 0 ? trimToByteBudget(chunk, allowedBodyBytes) : '';
        return `${prefix}${body}`.trimEnd();
    });
};

const createSmsReply = async (decodedPrompt: string, action?: string): Promise<string> => {
    if (!process.env.NVIDIA_API_KEY) {
        console.error('[SMS] NVIDIA_API_KEY missing; cannot call model');
        throw new Error('NVIDIA_API_KEY is not configured in the server environment');
    }

    console.log(
        `[SMS] prompting model=${SMS_MODEL_NAME} action=${action ?? 'general'} promptChars=${decodedPrompt.length} promptPreview="${decodedPrompt.slice(0, SMS_LOG_PREVIEW)}"`
    );

    const response = await nvidiaClient.chat.completions.create({
        model: SMS_MODEL_NAME,
        messages: [
            {
                role: 'system',
                content: 'You are an SMS farming assistant for Indian users. Reply with plain text only, no markdown, no JSON, no bullet lists, and no emojis. Give practical and specific advice in 1-2 short sentences. Target roughly 150 characters when useful, but avoid fluff and repetition. Keep language simple and actionable.',
            },
            {
                role: 'user',
                content: `Action: ${action ?? 'general'}\nPrompt: ${decodedPrompt}`,
            },
        ],
        temperature: 0.2,
        max_tokens: 400,
    });

    const raw = response.choices[0]?.message?.content?.trim() || 'Unable to process your request right now.';
    console.log(`[SMS] model responded | chars=${raw.length} preview="${raw.slice(0, SMS_LOG_PREVIEW)}"`);
    return fitToCharLimit(raw.replace(/\s+/g, ' '), SMS_REPLY_MAX_CHARS);
};

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
    console.log(
        `[SMS] incoming envelope | from=${from} action="${action}" payloadType=${typeof payload}`
    );

    if (typeof payload !== 'string') {
        console.warn(`[SMS] ignoring message from ${from}: payload is not text`);
        return { skipDefaultResponse: true, data: { ignored: true, reason: 'non-string payload' } };
    }

    const promptText = payload.trim();
    console.log(`[SMS] received plain payload from ${from} | chars=${promptText.length}`);

    if (!promptText) {
        console.warn(`[SMS] ignoring empty prompt from ${from}`);
        return { skipDefaultResponse: true, data: { ignored: true, reason: 'empty-prompt' } };
    }

    if (!promptText.startsWith(SMS_REQUIRED_PREFIX)) {
        console.warn(
            `[SMS] ignoring prompt from ${from}: missing required prefix ${SMS_REQUIRED_PREFIX}`
        );
        return {
            skipDefaultResponse: true,
            data: { ignored: true, reason: 'missing-required-prefix' },
        };
    }

    const promptBody = promptText.slice(SMS_REQUIRED_PREFIX.length).trim();
    if (!promptBody) {
        console.warn(`[SMS] ignoring prompt from ${from}: prefix present but body is empty`);
        return { skipDefaultResponse: true, data: { ignored: true, reason: 'empty-prefixed-body' } };
    }

    console.log(
        `[SMS] accepted prefixed prompt from ${from} | chars=${promptBody.length} preview="${promptBody.slice(0, SMS_LOG_PREVIEW)}"`
    );

    try {
        const modelReply = await createSmsReply(promptBody, action);
        const replyBytes = Buffer.byteLength(modelReply, 'utf-8');

        console.log(
            `[SMS] model reply ready for ${from} | replyChars=${modelReply.length} smsBytes=${replyBytes}`
        );

        if (replyBytes <= SMS_SINGLE_MESSAGE_BUDGET) {
            console.log(`[SMS] sending single SMS to ${from}`);
            await SMS.sendText(from, modelReply);
            console.log(`[SMS] single SMS sent to ${from}`);
        } else {
            const chunks = withSequencePrefix(
                splitForSingleSms(modelReply, SMS_SINGLE_MESSAGE_BUDGET),
                SMS_SINGLE_MESSAGE_BUDGET
            );
            console.warn(
                `[SMS] reply overflow: ${replyBytes}B; sending ${chunks.length} paced SMS message(s)`
            );

            for (let i = 0; i < chunks.length; i += 1) {
                console.log(
                    `[SMS] sending chunk ${i + 1}/${chunks.length} to ${from} | chunkChars=${chunks[i].length} smsBytes=${Buffer.byteLength(chunks[i], 'utf-8')}`
                );
                await SMS.sendText(from, chunks[i]);

                if (i < chunks.length - 1) {
                    console.log(`[SMS] pausing ${SMS_CHUNK_SEND_DELAY_MS}ms before next chunk`);
                    await sleep(SMS_CHUNK_SEND_DELAY_MS);
                }
            }

            console.log(`[SMS] all ${chunks.length} SMS chunk(s) sent to ${from}`);
        }
    } catch (error: any) {
        const detail = error?.message ?? 'unknown error';
        console.error(`[SMS] model/send failure for ${from}: ${detail}`);

        // Best-effort plain-text fallback so the user still receives a reply.
        try {
            const fallback = 'Unable to process right now. Please retry in a minute.';
            await SMS.sendText(from, fallback);
            console.log(`[SMS] fallback SMS sent to ${from}`);
        } catch (fallbackError: any) {
            console.error(
                `[SMS] fallback send also failed for ${from}: ${fallbackError?.message ?? 'unknown'}`
            );
        }
    }

    return { skipDefaultResponse: true, data: { delivered: true } };
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
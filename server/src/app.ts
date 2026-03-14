import express from 'express';
import cors from 'cors';
import OpenAI from 'openai';
import { errorMiddleware } from './middleware/error.middleware.js';
import { loggerMiddleware } from './middleware/logger.middleware.js';
import v1Routes from './routes.js';
import { SMS, smsRouter } from './modules/sms/index.js'; // 👈 ADD THIS
import { decode, encode } from './modules/sms/sms.codec.js';

const SMS_SINGLE_MESSAGE_BUDGET = 100;
const SMS_REPLY_MAX_CHARS = 280;
const SMS_MODEL_NAME = 'openai/gpt-oss-120b';
const SMS_LOG_PREVIEW = 180;

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
        const encodedLength = Buffer.byteLength(encode(candidate), 'utf-8');

        if (encodedLength <= budget) {
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
                const ok = Buffer.byteLength(encode(slice), 'utf-8') <= budget;
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
                content: 'You are an SMS farming assistant for Indian users. Reply with plain text only, no markdown, no JSON, no lists with bullets, no emojis. Keep it concise, practical, and under 280 characters. Prefer one or two short sentences that are still useful.',
            },
            {
                role: 'user',
                content: `Action: ${action ?? 'general'}\nPrompt: ${decodedPrompt}`,
            },
        ],
        temperature: 0.2,
        max_tokens: 120,
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
        console.warn(`[SMS] ignoring message from ${from}: payload is not encoded string`);
        return { skipDefaultResponse: true, data: { ignored: true, reason: 'non-string payload' } };
    }

    const trimmedPayload = payload.trim();
    console.log(`[SMS] received encoded payload from ${from} | chars=${trimmedPayload.length}`);

    let decodedPrompt = '';
    try {
        decodedPrompt = decode(trimmedPayload);
    } catch (error: any) {
        console.warn(
            `[SMS] ignoring undecodable payload from ${from} | error=${error?.message ?? 'unknown'}`
        );
        return { skipDefaultResponse: true, data: { ignored: true, reason: 'decode-failed' } };
    }

    if (!decodedPrompt.trim()) {
        console.warn(`[SMS] ignoring empty decoded prompt from ${from}`);
        return { skipDefaultResponse: true, data: { ignored: true, reason: 'empty-decoded-prompt' } };
    }

    console.log(
        `[SMS] decoded prompt from ${from} | chars=${decodedPrompt.length} preview="${decodedPrompt.slice(0, SMS_LOG_PREVIEW)}"`
    );

    try {
        const modelReply = await createSmsReply(decodedPrompt, action);
        const encoded = encode(modelReply);
        const encodedLength = Buffer.byteLength(encoded, 'utf-8');

        console.log(
            `[SMS] encoded model reply for ${from} | replyChars=${modelReply.length} encodedBytes=${encodedLength}`
        );

        if (encodedLength <= SMS_SINGLE_MESSAGE_BUDGET) {
            console.log(`[SMS] sending single encoded SMS to ${from}`);
            await SMS.sendText(from, encoded);
            console.log(`[SMS] single encoded SMS sent to ${from}`);
        } else {
            const chunks = splitForSingleSms(modelReply, SMS_SINGLE_MESSAGE_BUDGET);
            console.warn(`[SMS] reply overflow: ${encodedLength}B; sending ${chunks.length} encoded SMS message(s)`);

            for (let i = 0; i < chunks.length; i += 1) {
                const encodedChunk = encode(chunks[i]);
                console.log(
                    `[SMS] sending chunk ${i + 1}/${chunks.length} to ${from} | chunkChars=${chunks[i].length} encodedBytes=${Buffer.byteLength(encodedChunk, 'utf-8')}`
                );
                await SMS.sendText(from, encodedChunk);
            }

            console.log(`[SMS] all ${chunks.length} encoded chunk(s) sent to ${from}`);
        }
    } catch (error: any) {
        const detail = error?.message ?? 'unknown error';
        console.error(`[SMS] model/send failure for ${from}: ${detail}`);

        // Best-effort encoded fallback so the user still receives a reply.
        try {
            const fallback = 'Unable to process right now. Please retry in a minute.';
            const encodedFallback = encode(fallback);
            await SMS.sendText(from, encodedFallback);
            console.log(`[SMS] fallback encoded SMS sent to ${from}`);
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
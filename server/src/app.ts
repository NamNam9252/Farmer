import express from 'express';
import cors from 'cors';
import { decode as base91Decode, encode as base91Encode } from 'node-base91';
import { compress as smazCompress, decompress as smazDecompress } from 'tsmaz';
import { deflateSync, inflateSync, strToU8, strFromU8 } from 'fflate';
import { errorMiddleware } from './middleware/error.middleware.js';
import { loggerMiddleware } from './middleware/logger.middleware.js';
import v1Routes from './routes.js';
import { SMS, smsRouter } from './modules/sms/index.js';

const CODEC_FLAG_RAW_UTF8 = 0x00;
const CODEC_FLAG_SMAZ = 0x01;
const CODEC_FLAG_DEFLATE = 0x02;
const RAW_PROMPT_ACTION = '__raw_prompt__';

const SMS_MAX_PARTS = 3;
const SMS_MAX_PLAIN_PART_LEN = 120;
const SMS_MAX_RESPONSE_LEN = 340;
const THRESHOLD = 100;

const SELF_BASE_URL = process.env.SELF_SERVER_BASE_URL ?? `http://127.0.0.1:${process.env.PORT ?? '3000'}`;
const API_BASE_URL = `${SELF_BASE_URL}/api/v1`;

const codecName = (flag: number): string => {
    switch (flag) {
        case CODEC_FLAG_RAW_UTF8:
            return 'raw-utf8';
        case CODEC_FLAG_SMAZ:
            return 'smaz';
        case CODEC_FLAG_DEFLATE:
            return 'deflate';
        default:
            return `unknown(${flag})`;
    }
};

const clampResponse = (text: string): string => {
    const normalized = text.replace(/\s+/g, ' ').trim();
    if (normalized.length <= SMS_MAX_RESPONSE_LEN) {
        console.log(`[SMS][SIZE] response within limit (${normalized.length}/${SMS_MAX_RESPONSE_LEN})`);
        return normalized;
    }

    const clamped = `${normalized.slice(0, SMS_MAX_RESPONSE_LEN - 3).trim()}...`;
    console.log(`[SMS][SIZE] response trimmed (${normalized.length} -> ${clamped.length})`);
    return clamped;
};

const splitForSms = (text: string): string[] => {
    const words = text.split(/\s+/).filter(Boolean);
    const parts: string[] = [];
    let current = '';

    for (const word of words) {
        const next = current ? `${current} ${word}` : word;
        if (next.length > SMS_MAX_PLAIN_PART_LEN) {
            if (current) parts.push(current);
            current = word;
        } else {
            current = next;
        }
    }

    if (current) parts.push(current);
    if (parts.length <= SMS_MAX_PARTS) {
        console.log(`[SMS][SPLIT] parts=${parts.length}, maxParts=${SMS_MAX_PARTS}, chunkTarget=${SMS_MAX_PLAIN_PART_LEN}`);
        return parts;
    }

    const merged = parts.slice(0, SMS_MAX_PARTS - 1);
    const remainingText = parts.slice(SMS_MAX_PARTS - 1).join(' ');
    merged.push(clampResponse(remainingText));
    console.log(`[SMS][SPLIT] overflow detected, merged into ${merged.length} parts`);
    return merged;
};

const decodeIncomingSms = (encodedMessage: string): string => {
    console.log(`[SMS][DECODE] incoming encoded length=${encodedMessage.length}`);
    const decoded = new Uint8Array(base91Decode(encodedMessage.trim()));
    if (decoded.length < 1) {
        throw new Error('Decoded message is empty');
    }

    const flag = decoded[0];
    const payload = decoded.slice(1);
    console.log(`[SMS][DECODE] base91->bytes=${decoded.length}, flag=${codecName(flag)}, payloadBytes=${payload.length}`);

    switch (flag) {
        case CODEC_FLAG_RAW_UTF8:
            return strFromU8(payload);
        case CODEC_FLAG_SMAZ:
            return smazDecompress(payload);
        case CODEC_FLAG_DEFLATE:
            return strFromU8(inflateSync(payload));
        default:
            throw new Error(`Unsupported codec flag: ${flag}`);
    }
};

const concatBytes = (a: Uint8Array, b: Uint8Array): Uint8Array => {
    const out = new Uint8Array(a.length + b.length);
    out.set(a);
    out.set(b, a.length);
    return out;
};

const encodeOutgoingSms = (plainText: string): string => {
    const raw = strToU8(plainText);
    console.log(`[SMS][ENCODE] plain chars=${plainText.length}, utf8Bytes=${raw.length}, threshold=${THRESHOLD}`);

    let selectedFlag = CODEC_FLAG_RAW_UTF8;
    let selectedPayload: Uint8Array = raw;

    if (raw.length < THRESHOLD) {
        const smazed = new Uint8Array(smazCompress(plainText));
        console.log(`[SMS][ENCODE] below threshold, smazBytes=${smazed.length}, rawBytes=${raw.length}`);

        if (smazed.length < raw.length) {
            selectedFlag = CODEC_FLAG_SMAZ;
            selectedPayload = smazed;
        }
    } else {
        const zlibbed = deflateSync(raw, { level: 9 });
        selectedFlag = CODEC_FLAG_DEFLATE;
        selectedPayload = zlibbed;
        console.log(`[SMS][ENCODE] above threshold, deflateBytes=${zlibbed.length}`);
    }

    const framed = concatBytes(new Uint8Array([selectedFlag]), selectedPayload);
    const encoded = base91Encode(framed);
    console.log(`[SMS][ENCODE] selected=${codecName(selectedFlag)}, framedBytes=${framed.length}, encodedChars=${encoded.length}`);
    return encoded;
};

const extractLatLon = (prompt: string): { lat: number; lon: number } | null => {
    const nums = prompt.match(/-?\d+(?:\.\d+)?/g);
    if (!nums || nums.length < 2) return null;

    const lat = Number.parseFloat(nums[0]);
    const lon = Number.parseFloat(nums[1]);

    if (Number.isNaN(lat) || Number.isNaN(lon)) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    console.log(`[SMS][INTENT] extracted coordinates lat=${lat}, lon=${lon}`);
    return { lat, lon };
};

const callSelf = async (path: string): Promise<any> => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 20_000);
    try {
        const url = `${API_BASE_URL}${path}`;
        const startedAt = Date.now();
        console.log(`[SMS][CALL] -> ${url}`);

        const response = await fetch(url, {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' },
            signal: controller.signal,
        });

        const body: any = await response.json().catch(() => ({}));
        if (!response.ok) {
            const reason = typeof body?.message === 'string' ? body.message : `HTTP ${response.status}`;
            console.log(`[SMS][CALL] <- status=${response.status}, error="${reason}", tookMs=${Date.now() - startedAt}`);
            throw new Error(reason);
        }

        console.log(`[SMS][CALL] <- status=${response.status}, tookMs=${Date.now() - startedAt}`);

        return body;
    } finally {
        clearTimeout(timer);
    }
};

const summarizeEndpointResult = (intent: string, body: any): string => {
    if (intent === 'weather') {
        const data = body?.data ?? {};
        const temp = data?.temperature;
        const humidity = data?.humidity;
        const rain = data?.rain_probability;
        const overview = data?.overview ?? 'No weather summary available';
        return `Weather update: ${overview}. Temp ${temp ?? '?'} C, humidity ${humidity ?? '?'}%, rain chance ${rain ?? '?'}%.`;
    }

    if (intent === 'market') {
        const rows: any[] = Array.isArray(body?.data) ? body.data : [];
        if (!rows.length) return 'No market price data was returned.';

        const top = rows.slice(0, 3).map((row) => {
            return `${row.commodity} at ${row.market}: INR ${row.averagePrice}/${row.unit ?? 'unit'} (min ${row.lowestPrice}, max ${row.highestPrice})`;
        });
        return `Top market prices: ${top.join(' | ')}`;
    }

    if (intent === 'schemes' || intent === 'news') {
        const rows: any[] = Array.isArray(body?.data) ? body.data : [];
        if (!rows.length) return `No ${intent} items are available right now.`;
        const names = rows
            .slice(0, 3)
            .map((item) => item?.title ?? item?.name ?? item?.scheme_name ?? item?.headline ?? 'Untitled')
            .join(' | ');
        return `Latest ${intent}: ${names}`;
    }

    return typeof body?.message === 'string' ? body.message : 'Request processed successfully.';
};

const fulfillPromptViaEndpoint = async (prompt: string): Promise<string> => {
    const lower = prompt.toLowerCase();
    console.log(`[SMS][INTENT] analyzing prompt="${prompt}"`);

    if (/(weather|temperature|humidity|rain|forecast)/i.test(lower)) {
        console.log('[SMS][INTENT] matched weather');
        const coords = extractLatLon(prompt);
        if (!coords) {
            return 'To fetch weather, include coordinates like: weather for 28.61 77.21';
        }

        const body = await callSelf(`/weather?lat=${coords.lat}&lon=${coords.lon}`);
        return summarizeEndpointResult('weather', body);
    }

    if (/(price|rates|rate|mandi|market)/i.test(lower)) {
        console.log('[SMS][INTENT] matched market');
        const commodityMatch = prompt.match(/(?:price|rate|rates|mandi|market)(?:\s+of|\s+for)?\s+([a-zA-Z ]{2,30})/i);
        const commodity = commodityMatch?.[1]?.trim() || 'Wheat';
        console.log(`[SMS][INTENT] commodity=${commodity}`);
        const body = await callSelf(`/market/prices?commodity=${encodeURIComponent(commodity)}&market=Delhi`);
        return summarizeEndpointResult('market', body);
    }

    if (/(scheme|yojana|subsidy|government help|govt)/i.test(lower)) {
        console.log('[SMS][INTENT] matched schemes');
        const body = await callSelf('/schemes');
        return summarizeEndpointResult('schemes', body);
    }

    if (/(news|headline|latest update)/i.test(lower)) {
        console.log('[SMS][INTENT] matched news');
        const body = await callSelf('/news');
        return summarizeEndpointResult('news', body);
    }

    console.log('[SMS][INTENT] no route matched');
    return 'I can handle weather, market prices, schemes, and news by SMS. Please ask one of these, for example: weather 28.61 77.21 or market price of wheat.';
};

const sendEncodedSmsResponse = async (to: string, text: string): Promise<void> => {
    const trimmed = clampResponse(text);
    const parts = splitForSms(trimmed);
    const total = parts.length;
    console.log(`[SMS][SEND] preparing response for ${to}, totalParts=${total}, chars=${trimmed.length}`);

    for (let i = 0; i < parts.length; i++) {
        const partText = total > 1 ? `${i + 1}/${total} ${parts[i]}` : parts[i];
        console.log(`[SMS][SEND] part ${i + 1}/${total} plainChars=${partText.length}`);
        const encoded = encodeOutgoingSms(partText);
        console.log(`[SMS][SEND] part ${i + 1}/${total} encodedChars=${encoded.length}`);
        await SMS.sendRaw(to, encoded);
        console.log(`[SMS][SEND] part ${i + 1}/${total} sent to ${to}`);
    }
};

const app = express();

// middleware
app.use(loggerMiddleware);
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

SMS.init();

// Load versioned routes
app.use('/api/v1', v1Routes);

app.use('/api/v1/sms', smsRouter);

SMS.onMessage(async (action, payload, from) => {
    console.log(`[SMS] action="${action}" from=${from}`);

    if (action === RAW_PROMPT_ACTION) {
        const encodedIncoming = typeof payload === 'string' ? payload : String(payload ?? '');
        let decodedPrompt = '';

        console.log(`[SMS][FLOW] received raw prompt payload from ${from}, encodedChars=${encodedIncoming.length}`);

        try {
            decodedPrompt = decodeIncomingSms(encodedIncoming);
            console.log(`[SMS][FLOW] decoded prompt from ${from}: ${decodedPrompt}`);
        } catch (error: any) {
            const errText = `Could not decode your message: ${error?.message ?? 'unknown decode error'}`;
            console.log(`[SMS][FLOW] decode failed for ${from}: ${errText}`);
            console.log(`[SMS][FLOW] ignoring non-conforming SMS from ${from}`);
            return { ok: false, ignored: true, err: errText };
        }

        try {
            const responseText = await fulfillPromptViaEndpoint(decodedPrompt);
            console.log(`[SMS][FLOW] endpoint response text generated (chars=${responseText.length})`);
            await sendEncodedSmsResponse(from, responseText);
            console.log(`[SMS][FLOW] response sent to ${from}`);
            return { ok: true, message: responseText };
        } catch (error: any) {
            const errText = `Request failed: ${error?.message ?? 'unknown error'}`;
            console.log(`[SMS][FLOW] processing failed for ${from}: ${errText}`);
            await sendEncodedSmsResponse(from, errText);
            return { ok: false, err: errText };
        }
    }

    switch (action) {
        case 'advisory':
            return 'Advisory action is not configured in app.ts';

        case 'crop':
            return 'Crop action is not configured in app.ts';

        case 'weather':
            return 'Weather action is not configured in app.ts';

        case 'market':
            return 'Market action is not configured in app.ts';

        case 'disease':
            return 'Disease action is not configured in app.ts';

        case 'schemes':
            return 'Schemes action is not configured in app.ts';

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
import { ResolvedAdvisoryInput } from "../../schema/advisory.schema.js";
import OpenAI from 'openai';
import { z } from 'zod';

type RiskLevel = 'Low' | 'Medium' | 'High';

interface Recommendation {
  stage: string;
  action: string;
  actionHindi: string;
  reason: string;
  reasonHindi: string;
  riskLevel: RiskLevel;
}

const recommendationSchema = z.object({
  action: z.string().min(8).max(220),
  actionHindi: z.string().min(8).max(260),
  reason: z.string().min(12).max(420),
  reasonHindi: z.string().min(12).max(460),
  riskLevel: z.enum(['Low', 'Medium', 'High']),
});

const advisoryModelResponseSchema = z.object({
  recommendations: z.array(recommendationSchema).min(1).max(8),
});

const RISK_ORDER: Record<RiskLevel, number> = { High: 0, Medium: 1, Low: 2 };
const MODEL_NAME = 'openai/gpt-oss-120b';
const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 1500;

const nvidiaClient = new OpenAI({
  baseURL: 'https://integrate.api.nvidia.com/v1',
  apiKey: process.env.NVIDIA_API_KEY || '',
});

const getStage = (days: number): string => {
  if (days <= 10) return 'germination';
  if (days <= 30) return 'vegetative';
  if (days <= 50) return 'flowering';
  return 'fruiting';
};

const sleep = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

const isRetryableError = (error: unknown): boolean => {
  const message = error instanceof Error ? error.message.toLowerCase() : '';
  const status =
    typeof error === 'object' && error !== null && 'status' in error
      ? Number((error as { status?: number }).status)
      : NaN;

  return (
    status === 429 ||
    status === 500 ||
    status === 502 ||
    status === 503 ||
    status === 504 ||
    message.includes('rate limit') ||
    message.includes('timed out') ||
    message.includes('temporarily unavailable')
  );
};

const stripCodeFences = (value: string): string =>
  value
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();

const sanitizePotentialJson = (value: string): string =>
  value
    .replace(/[\u201C\u201D]/g, '"')
    .replace(/[\u2018\u2019]/g, "'")
    .replace(/,\s*([}\]])/g, '$1')
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '');

const findBalancedObject = (value: string): string | null => {
  const start = value.indexOf('{');
  if (start < 0) return null;

  let depth = 0;
  let inString = false;
  let escape = false;

  for (let i = start; i < value.length; i += 1) {
    const ch = value[i];

    if (escape) {
      escape = false;
      continue;
    }

    if (ch === '\\') {
      if (inString) escape = true;
      continue;
    }

    if (ch === '"') {
      inString = !inString;
      continue;
    }

    if (inString) continue;

    if (ch === '{') depth += 1;
    if (ch === '}') {
      depth -= 1;
      if (depth === 0) {
        return value.slice(start, i + 1);
      }
    }
  }

  return null;
};

const tryParseJson = (value: string): unknown | null => {
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
};

const extractJsonPayload = (raw: string): unknown => {
  const trimmed = raw.trim();
  if (!trimmed) {
    throw new Error('Empty model response');
  }

  const base = stripCodeFences(trimmed);
  const balanced = findBalancedObject(base);
  const regexObject = base.match(/\{[\s\S]*\}/)?.[0] ?? null;

  const candidates = [
    base,
    sanitizePotentialJson(base),
    balanced,
    balanced ? sanitizePotentialJson(balanced) : null,
    regexObject,
    regexObject ? sanitizePotentialJson(regexObject) : null,
  ].filter((item): item is string => Boolean(item));

  for (const candidate of candidates) {
    const parsed = tryParseJson(candidate);
    if (parsed !== null) {
      return parsed;
    }
  }

  throw new Error('No valid JSON object found in model response');
};

const systemPrompt = `You are an expert agricultural advisor for Indian farming conditions.
Generate practical, stage-aware recommendations based on weather, soil nutrients, soil moisture, and pest status.
Avoid generic advice. Prioritize actions by agronomic impact and urgency.

Output must be STRICT JSON with this shape only:
{
  "recommendations": [
    {
      "action": "string",
      "actionHindi": "string",
      "reason": "string",
      "reasonHindi": "string",
      "riskLevel": "High|Medium|Low"
    }
  ]
}

Rules:
- Return 3-6 recommendations when risks exist; otherwise return exactly 1 low-risk monitoring recommendation.
- Include realistic interventions farmers can execute.
- Keep action concise and imperative.
- Keep reason specific and tied to the provided numeric inputs.
- For each recommendation, provide both English and Hindi fields with equivalent meaning.
- No markdown, no extra keys, no explanations outside JSON.`;

export class AdvisoryService {
  private async repairJsonWithModel(rawContent: string): Promise<unknown> {
    console.warn('[AdvisoryService] Initial JSON parse failed, attempting model-assisted JSON repair');
    const repairPrompt = `Fix the following invalid JSON and return ONLY corrected valid JSON.

Required schema:
{
  "recommendations": [
    {
      "action": "string",
      "actionHindi": "string",
      "reason": "string",
      "reasonHindi": "string",
      "riskLevel": "High|Medium|Low"
    }
  ]
}

Invalid JSON:
${rawContent.slice(0, 8000)}`;

    const response = await nvidiaClient.chat.completions.create({
      model: MODEL_NAME,
      messages: [
        { role: 'system', content: 'You correct malformed JSON. Return only valid JSON.' },
        { role: 'user', content: repairPrompt },
      ],
      temperature: 0,
      max_tokens: 1400,
    });

    const repairedRaw = response.choices[0]?.message?.content ?? '';
    console.log(`[AdvisoryService] JSON repair response received | length=${repairedRaw.length}`);
    return extractJsonPayload(repairedRaw);
  }

  async getRecommendation(input: ResolvedAdvisoryInput): Promise<Recommendation[]> {
    const startTime = Date.now();
    if (!process.env.NVIDIA_API_KEY) {
      throw new Error('NVIDIA_API_KEY is not configured in the server environment');
    }

    const stage = getStage(input.days_since_sowing);
    console.log(
      `[AdvisoryService] Generating advisory | crop=${input.crop} | stage=${stage} | temp=${input.temperature}C | humidity=${input.humidity}% | rainProb=${input.rain_probability}% | pest=${input.pest_reported}`
    );

    const prompt = `Farmer context:
${JSON.stringify({
  crop: input.crop,
  stage,
  days_since_sowing: input.days_since_sowing,
  soil_n: input.soil_n,
  soil_p: input.soil_p,
  soil_k: input.soil_k,
  soil_moisture: input.soil_moisture,
  pest_reported: input.pest_reported,
  temperature_c: input.temperature,
  humidity_percent: input.humidity,
  rain_probability_percent: input.rain_probability,
  location: {
    latitude: input.latitude,
    longitude: input.longitude,
  },
}, null, 2)}

Generate an intelligent agronomy action plan with trade-offs where relevant.
Prioritize immediate risk mitigation first, then yield and quality optimization.
Output strict JSON only.`;

    let rawContent = '';

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt += 1) {
      try {
        console.log(`[AdvisoryService] NVIDIA model call attempt ${attempt}/${MAX_RETRIES}`);
        const response = await nvidiaClient.chat.completions.create({
          model: MODEL_NAME,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: prompt },
          ],
          temperature: 0.25,
          max_tokens: 1200,
        });

        rawContent = response.choices[0]?.message?.content ?? '';
        console.log(`[AdvisoryService] Model response received | length=${rawContent.length}`);
        break;
      } catch (error) {
        if (attempt < MAX_RETRIES && isRetryableError(error)) {
          const delayMs = RETRY_DELAY_MS * attempt;
          const message = error instanceof Error ? error.message : 'Unknown error';
          console.warn(
            `[AdvisoryService] Retriable model error on attempt ${attempt}: ${message}. Retrying in ${delayMs}ms`
          );
          await sleep(RETRY_DELAY_MS * attempt);
          continue;
        }
        const message = error instanceof Error ? error.message : 'Unknown error';
        console.error(`[AdvisoryService] Model call failed (non-retriable) | error=${message}`);
        throw new Error(`NVIDIA advisory generation failed: ${message}`);
      }
    }

    let parsedPayload: unknown;
    try {
      parsedPayload = extractJsonPayload(rawContent);
      console.log('[AdvisoryService] JSON parse succeeded without repair');
    } catch {
      parsedPayload = await this.repairJsonWithModel(rawContent);
      console.log('[AdvisoryService] JSON parse succeeded after repair pass');
    }

    const validated = advisoryModelResponseSchema.safeParse(parsedPayload);

    if (!validated.success) {
      console.error('[AdvisoryService] Response schema validation failed');
      throw new Error('NVIDIA advisory response was not valid JSON in expected format');
    }

    const recommendations = validated.data.recommendations
      .map((item) => ({
        stage,
        action: item.action.trim(),
        actionHindi: item.actionHindi.trim(),
        reason: item.reason.trim(),
        reasonHindi: item.reasonHindi.trim(),
        riskLevel: item.riskLevel,
      }))
      .sort(
      (a, b) => RISK_ORDER[a.riskLevel] - RISK_ORDER[b.riskLevel]
    );

    const durationMs = Date.now() - startTime;
    console.log(
      `[AdvisoryService] Advisory generated successfully | count=${recommendations.length} | durationMs=${durationMs}`
    );

    return recommendations;
  }
}
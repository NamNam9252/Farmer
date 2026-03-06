import Groq from 'groq-sdk';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';

export interface ProductLink {
  name: string;
  nameHindi: string;
  platform: string;
  url: string;
  priceRange: string;
}

export interface DiseaseAnalysisResult {
  id: string;
  imagePath: string;
  diseaseName: string;
  diseaseNameHindi: string;
  cropName: string;
  confidenceScore: number;
  severity: 'none' | 'low' | 'medium' | 'high';
  isHealthy: boolean;
  description: string;
  descriptionHindi: string;
  treatments: string[];
  treatmentsHindi: string[];
  preventions: string[];
  preventionsHindi: string[];
  productLinks: ProductLink[];
  createdAt: string;
}

// Groq — FREE tier with Llama-4 Scout Vision
// Get key at: https://console.groq.com
// Free tier: ~14,400 req/day, 30 RPM
const MODEL_NAME = 'meta-llama/llama-4-scout-17b-16e-instruct';

const PROMPT = `You are a highly experienced agricultural scientist for Indian farmers.

Analyze the crop image carefully and return ONLY a valid JSON object. No markdown, no explanation — raw JSON only.

JSON structure:
{
  "diseaseName": "English disease name e.g. 'Early Blight' or 'Healthy Plant'",
  "diseaseNameHindi": "Hindi name e.g. 'प्रारंभिक झुलसा' or 'स्वस्थ पौधा'",
  "cropName": "detected crop in English",
  "confidenceScore": 0.92,
  "severity": "none",
  "isHealthy": false,
  "description": "2-3 sentence English description of the disease and its impact",
  "descriptionHindi": "2-3 sentence Hindi description in very simple language a farmer can understand",
  "treatments": [
    "Apply Mancozeb 75% WP @ 2.5g per litre of water, spray on affected leaves",
    "Apply Copper Oxychloride 50% WP @ 3g per litre as a follow-up spray after 7 days"
  ],
  "treatmentsHindi": [
    "मैंकोजेब 75% WP 2.5 ग्राम प्रति लीटर पानी में मिलाकर प्रभावित पत्तियों पर छिड़कें",
    "7 दिन बाद कॉपर ऑक्सीक्लोराइड 50% WP 3 ग्राम प्रति लीटर पानी में मिलाकर छिड़कें"
  ],
  "preventions": [
    "Avoid overhead irrigation; use drip irrigation to keep foliage dry",
    "Apply recommended dose of Potassium fertilizer to strengthen plant immunity"
  ],
  "preventionsHindi": [
    "ऊपर से पानी देने से बचें; ड्रिप सिंचाई का उपयोग करें ताकि पत्तियाँ सूखी रहें",
    "पौधों की रोग प्रतिरोधक क्षमता बढ़ाने के लिए पोटाश खाद की संस्तुत मात्रा दें"
  ],
  "productLinks": [
    {
      "name": "Mancozeb 75% WP",
      "nameHindi": "मैंकोजेब 75% WP",
      "platform": "BigHaat",
      "url": "https://www.bighaat.com/search?q=mancozeb+75+wp",
      "priceRange": "₹120-250"
    },
    {
      "name": "Copper Oxychloride 50% WP",
      "nameHindi": "कॉपर ऑक्सीक्लोराइड 50% WP",
      "platform": "Agribegri",
      "url": "https://www.agribegri.com/search?q=copper+oxychloride+50+wp",
      "priceRange": "₹100-200"
    },
    {
      "name": "Mancozeb 75% WP",
      "nameHindi": "मैंकोजेब 75% WP",
      "platform": "DeHaat",
      "url": "https://www.dehaat.com/search?q=mancozeb+75+wp",
      "priceRange": "₹110-230"
    }
  ]
}

STRICT RULES:
1. Treatments must have EXACT chemical name with formulation (e.g. Propiconazole 25% EC) and EXACT dosage (e.g. 2ml/litre or 500g/acre). Do NOT change treatments — they must be scientifically accurate.
2. productLinks must contain the SAME medicines mentioned in treatments. Build search URLs by URL-encoding the medicine name (spaces = +). Use these platforms: BigHaat (bighaat.com), Agribegri (agribegri.com), DeHaat (dehaat.com), AgroStar (agrostar.in), Krishisevak (krishisevak.in). Pick the 3 cheapest/most farmer-friendly.
3. priceRange must be realistic INR estimates for that chemical (research common market prices).
4. severity must be exactly one of: "none", "low", "medium", "high".
5. confidenceScore: decimal 0.0–1.0.
6. If plant is healthy: isHealthy=true, severity="none", treatments=[], treatmentsHindi=[], productLinks=[].
7. Return ONLY the JSON. Nothing else.`;

export class DiseaseService {
  private groq: Groq;

  constructor() {
    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) {
      throw new Error('GROQ_API_KEY is not set in environment variables');
    }
    this.groq = new Groq({ apiKey });
  }

  async analyzeImage(
    imagePath: string,
    cropType: string,
    _language: string
  ): Promise<DiseaseAnalysisResult> {
    const imageBuffer = fs.readFileSync(imagePath);
    const fileSizeKB = Math.round(imageBuffer.length / 1024);
    console.log(`[DiseaseService] Image: ${imagePath} | Size: ${fileSizeKB}KB`);
    if (imageBuffer.length < 1000) {
      throw new Error('Image file is too small or corrupted. Please send a clear photo.');
    }
    const base64Image = imageBuffer.toString('base64');
    const mimeType = this._getMimeType(imagePath);

    const userText = cropType
      ? `This is a ${cropType} crop. Analyze it for diseases.`
      : 'Identify the crop and analyze it for diseases.';

    const MAX_RETRIES = 3;
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        const response = await this.groq.chat.completions.create({
          model: MODEL_NAME,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: PROMPT + '\n\n' + userText,
                },
                {
                  type: 'image_url',
                  image_url: {
                    url: `data:${mimeType};base64,${base64Image}`,
                  },
                },
              ],
            },
          ],
          temperature: 0.1,
          max_tokens: 1800,
        });

        const content = response.choices[0]?.message?.content ?? '';
        const parsed = this._parseJsonResponse(content);

        return {
          id: uuidv4(),
          imagePath: path.basename(imagePath), // Return just filename
          cropName: cropType || parsed.cropName || '',
          createdAt: new Date().toISOString(),
          diseaseName: 'Unknown',
          diseaseNameHindi: 'अज्ञात',
          confidenceScore: 0,
          severity: 'none',
          isHealthy: false,
          description: '',
          descriptionHindi: '',
          treatments: [],
          treatmentsHindi: [],
          preventions: [],
          preventionsHindi: [],
          productLinks: [],
          ...parsed,
        };
      } catch (error) {
        const msg = error instanceof Error ? error.message : 'Unknown error';
        const isRateLimit =
          msg.includes('429') ||
          msg.toLowerCase().includes('rate limit') ||
          msg.toLowerCase().includes('quota');

        if (isRateLimit && attempt < MAX_RETRIES) {
          const retryMatch = msg.match(/(\d+(\.\d+)?)\s*s/);
          const waitSeconds = retryMatch ? Math.ceil(parseFloat(retryMatch[1])) : 30;
          console.log(`[DiseaseService] Rate limited. Waiting ${waitSeconds}s before retry ${attempt}/${MAX_RETRIES - 1}...`);
          await new Promise((resolve) => setTimeout(resolve, waitSeconds * 1000));
          lastError = new Error(msg);
          continue;
        }

        if (isRateLimit) {
          const err = new Error('Rate limit hit. Please try again in a moment.');
          (err as any).statusCode = 429;
          throw err;
        }

        throw new Error(`Disease analysis failed: ${msg}`);
      } finally {
        if (attempt === MAX_RETRIES || lastError === null) {
          try {
            if (fs.existsSync(imagePath)) fs.unlinkSync(imagePath);
          } catch (_) { }
        }
      }
    }

    throw lastError ?? new Error('Disease analysis failed after retries');
  }

  private _parseJsonResponse(content: string): Partial<DiseaseAnalysisResult> {
    try {
      const match = content.match(/\{[\s\S]*\}/);
      if (!match) throw new Error('No JSON object found in response');
      return JSON.parse(match[0]);
    } catch {
      return {
        diseaseName: 'Analysis Incomplete',
        diseaseNameHindi: 'जांच अधूरी',
        confidenceScore: 0,
        severity: 'none',
        isHealthy: false,
        description:
          'Could not fully analyze the image. Please try again with a clearer photo in good lighting.',
        descriptionHindi:
          'फोटो साफ न होने से जांच नहीं हो पाई। अच्छी रोशनी में साफ फोटो से दोबारा कोशिश करें।',
        treatments: [],
        treatmentsHindi: [],
        preventions: [],
        preventionsHindi: [],
        productLinks: [],
      };
    }
  }

  private _getMimeType(filePath: string): string {
    const ext = path.extname(filePath).toLowerCase();
    const map: Record<string, string> = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
    };
    return map[ext] ?? 'image/jpeg';
  }
}

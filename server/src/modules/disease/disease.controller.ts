import { Request, Response, NextFunction } from 'express';
import { DiseaseService } from './disease.service.js';
import { analyzeDiseaseSchema } from '../../schema/disease.schema.js';

let diseaseService: DiseaseService | null = null;
const getService = () => {
  if (!diseaseService) diseaseService = new DiseaseService();
  return diseaseService;
};

export const analyzeDisease = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const file = req.file;
    if (!file) {
      res.status(400).json({
        success: false,
        message: 'Image file is required / फोटो आवश्यक है',
      });
      return;
    }

    const parsed = analyzeDiseaseSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        success: false,
        message: 'Invalid input',
        error: parsed.error.flatten(),
      });
      return;
    }

    const { cropType, language } = parsed.data;

    const result = await getService().analyzeImage(
      file.path,
      cropType,
      language
    );

    res.status(200).json({
      success: true,
      message: 'Analysis complete / जांच पूरी हुई',
      data: result,
    });
  } catch (error) {
    if ((error as any).statusCode === 429) {
      res.status(429).json({
        success: false,
        message: (error as Error).message,
        retryAfter: (error as any).retryAfter ?? 60,
      });
      return;
    }
    next(error);
  }
};

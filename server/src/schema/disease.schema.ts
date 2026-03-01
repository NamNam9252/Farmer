import { z } from 'zod';

export const analyzeDiseaseSchema = z.object({
  cropType: z.string().optional().default(''),
  language: z.enum(['hi', 'en']).default('hi'),
});

export type AnalyzeDiseaseInput = z.infer<typeof analyzeDiseaseSchema>;

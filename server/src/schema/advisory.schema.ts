import { z } from 'zod';

export const advisorySchema = z.object({
  crop: z.enum(['wheat', 'rice', 'tomato']),
  days_since_sowing: z.number().int().nonnegative(),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  soil_n: z.enum(['low', 'medium', 'high']),
  soil_p: z.enum(['low', 'medium', 'high']),
  soil_k: z.enum(['low', 'medium', 'high']),
  soil_moisture: z.enum(['low', 'medium', 'high']),
  pest_reported: z.boolean(),

  // Optional — fetched from Open-Meteo if not provided
  rain_probability: z.number().min(0).max(100).optional(),
  humidity: z.number().min(0).max(100).optional(),
  temperature: z.number().optional(),
});

export type AdvisoryInput = z.infer<typeof advisorySchema>;

// After weather is merged in, all fields are guaranteed present
export interface ResolvedAdvisoryInput {
  crop: string;
  days_since_sowing: number;
  latitude: number;
  longitude: number;
  soil_n: 'low' | 'medium' | 'high';
  soil_p: 'low' | 'medium' | 'high';
  soil_k: 'low' | 'medium' | 'high';
  soil_moisture: 'low' | 'medium' | 'high';
  pest_reported: boolean;
  rain_probability: number;
  humidity: number;
  temperature: number;
}
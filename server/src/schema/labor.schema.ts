import { z } from "zod";

export const createLaborProfileSchema = z.object({
  skills: z.array(z.string()).min(1),
  experienceYears: z.number().int().min(0).optional(),
  dailyRate: z.number().positive().optional(),
  districtId: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  serviceRadiusKm: z.number().optional(),
});

export const hireLaborSchema = z.object({
  wageAmount: z.number().positive(),
  workHoursPerDay: z.number().int().positive().optional(),
  workDaysPerWeek: z.number().int().positive().optional(),
});

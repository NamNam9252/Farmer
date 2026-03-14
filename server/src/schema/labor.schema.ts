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

export const requestLaborBookingSchema = z.object({
  taskDescription: z.string().min(3),
  startDate: z.string().datetime(),
  endDate: z.string().datetime().optional(),
  agreedRate: z.number().positive().optional(),
  totalAmount: z.number().positive().optional(),
  landId: z.string().optional(),
});

export const respondLaborBookingSchema = z.object({
  action: z.enum(["accept", "reject"]),
  cancelReason: z.string().min(3).optional(),
});

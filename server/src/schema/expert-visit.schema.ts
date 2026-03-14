import { z } from 'zod';
import { VisitStatus } from '@prisma/client';

export const createVisitRequestSchema = z.object({
  problemDescription: z.string().min(10, "Description must be at least 10 characters / विवरण कम से कम 10 वर्णों का होना चाहिए"),
  cropName: z.string().optional(),
  urgencyLevel: z.string().optional(),
  locationId: z.string().optional(),
  landId: z.string().optional(),
});

export const updateVisitStatusSchema = z.object({
  status: z.nativeEnum(VisitStatus).optional(),
  notes: z.string().optional(),
  scheduledAt: z.string().datetime().optional().or(z.date()),
});

export type CreateVisitRequestInput = z.infer<typeof createVisitRequestSchema>;
export type UpdateVisitStatusInput = z.infer<typeof updateVisitStatusSchema>;

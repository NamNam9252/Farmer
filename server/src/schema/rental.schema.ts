import { z } from "zod";

const AssetTypeSchema = z.enum(["PROPERTY", "VEHICLE", "EQUIPMENT", "OTHER"]);
const AssetStatusSchema = z.enum(["AVAILABLE", "LOCKED", "INACTIVE"]);

export const CreateAssetSchema = z.object({
  title: z.string().min(1).max(120),
  description: z.string().min(1),
  type: AssetTypeSchema,
  basePrice: z.number().positive(),
  imageUrl: z.string().url().optional(),
});

export const UpdateAssetSchema = CreateAssetSchema.partial().extend({
  status: z.enum(["AVAILABLE", "INACTIVE"]).optional(),
});

export const ListAssetsSchema = z.object({
  type: AssetTypeSchema.optional(),
  status: AssetStatusSchema.optional(),
  minPrice: z.coerce.number().positive().optional(),
  maxPrice: z.coerce.number().positive().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export const PlaceBidSchema = z
  .object({
    amount: z.number().positive(),
    startDate: z.coerce.date(),
    endDate: z.coerce.date(),
    message: z.string().max(500).optional(),
  })
  .refine((d) => new Date(d.startDate) > new Date(), {
    message: "startDate cannot be in the past",
    path: ["startDate"],
  })
  .refine((d) => new Date(d.endDate) > new Date(d.startDate), {
    message: "endDate must be after startDate",
    path: ["endDate"],
  });

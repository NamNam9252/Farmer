// src/schema/warehouse.schema.ts
import { z } from "zod";

export const createListingSchema = z.object({
  body: z
    .object({
      locationId: z.string(),
      title: z.string().min(3),
      totalAreaSqft: z.number().positive(),
      askingPricePerMonth: z.number().positive(),
      availableFrom: z.coerce.date(),
      availableUntil: z.coerce.date(),
      amenities: z.array(z.string()).default([]),
      latitude: z.number(),
      longitude: z.number(),
    })
    .refine((d) => d.availableFrom < d.availableUntil, {
      message: "availableFrom must be before availableUntil",
      path: ["availableFrom"],
    }),
});

export const submitOfferSchema = z.object({
  body: z
    .object({
      offeredPricePerMonth: z.number().positive(),
      requestedFrom: z.coerce.date(),
      requestedUntil: z.coerce.date(),
      message: z.string().optional(),
    })
    .refine((d) => d.requestedFrom < d.requestedUntil, {
      message: "requestedFrom must be before requestedUntil",
      path: ["requestedFrom"],
    }),
});

export const addInventoryItemSchema = z.object({
  body: z
    .object({
      sourceType: z.enum(["OWNED", "LEASED"]),
      rentalId: z.string().optional(),
      locationId: z.string().optional(),
      itemType: z.enum(["CROP", "MACHINERY", "EQUIPMENT", "INPUT", "OTHER"]),
      name: z.string().min(1),
      quantity: z.number().positive(),
      unit: z.string().min(1),
      batchLabel: z.string().optional(),
      expiryDate: z.coerce.date().optional(),
    })
    .refine((d) => (d.sourceType === "LEASED" ? !!d.rentalId : true), {
      message: "rentalId required for LEASED",
      path: ["rentalId"],
    })
    .refine((d) => (d.sourceType === "OWNED" ? !!d.locationId : true), {
      message: "locationId required for OWNED",
      path: ["locationId"],
    }),
});

export const updateInventoryItemSchema = z.object({
  body: z.object({
    itemType: z
      .enum(["CROP", "MACHINERY", "EQUIPMENT", "INPUT", "OTHER"])
      .optional(),
    name: z.string().min(1).optional(),
    quantity: z.number().positive().optional(),
    unit: z.string().optional(),
    batchLabel: z.string().optional(),
    expiryDate: z.coerce.date().optional(),
  }),
});

export const nearbyListingsSchema = z.object({
  query: z.object({
    lat: z.coerce.number(),
    lng: z.coerce.number(),
    radiusKm: z.coerce.number().positive().default(50),
  }),
});

export type CreateListingInput = z.infer<typeof createListingSchema>["body"];
export type SubmitOfferInput = z.infer<typeof submitOfferSchema>["body"];
export type AddInventoryItemInput = z.infer<
  typeof addInventoryItemSchema
>["body"];
export type UpdateInventoryInput = z.infer<
  typeof updateInventoryItemSchema
>["body"];

import { z } from 'zod';

export const locationSchema = z.object({
    body: z.object({
        type: z.enum(['HOME', 'FARM', 'WAREHOUSE', 'DELIVERY', 'COMMUNITY_HUB', 'ALERT_ZONE', 'OTHER']),
        label: z.string().optional(),
        stateId: z.string(),
        districtId: z.string(),
        pincodeId: z.string(),
        village: z.string().optional(),
        addressLine: z.string().optional(),
        latitude: z.number(),
        longitude: z.number(),
    }),
});

export const farmerProfileSchema = z.object({
    body: z.object({
        totalLandArea: z.number().optional(),
        experienceYears: z.number().optional(),
        aadhaarLast4: z.string().optional(),
    }),
});

export const laborProfileSchema = z.object({
    body: z.object({
        skills: z.array(z.string()).optional(),
        experienceYears: z.number().optional(),
        dailyRate: z.number().optional(),
        serviceRadiusKm: z.number().optional(),
    }),
});

export const expertProfileSchema = z.object({
    body: z.object({
        specializations: z.array(z.string()).optional(),
        qualifications: z.string().optional(),
        institution: z.string().optional(),
        yearsExperience: z.number().optional(),
    }),
});

export type LocationInput = z.infer<typeof locationSchema>['body'];
export type FarmerProfileInput = z.infer<typeof farmerProfileSchema>['body'];
export type LaborProfileInput = z.infer<typeof laborProfileSchema>['body'];
export type ExpertProfileInput = z.infer<typeof expertProfileSchema>['body'];

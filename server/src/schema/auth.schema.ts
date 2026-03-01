import { z } from 'zod';

export const signupSchema = z.object({
    body: z.object({
        name: z.string().min(2, 'Name must be at least 2 characters'),
        phone: z.string().min(10, 'Phone must be at least 10 digits'),
        password: z.string().min(6, 'Password must be at least 6 characters'),
        role: z.enum(['FARMER', 'BUYER', 'LABOR', 'EXPERT', 'ADMIN']),
        email: z.string().email('Invalid email').optional(),
    }),
});

export const loginSchema = z.object({
    body: z.object({
        phone: z.string().min(10, 'Phone must be at least 10 digits'),
        password: z.string().min(6, 'Password must be at least 6 characters'),
    }),
});

export type SignupInput = z.infer<typeof signupSchema>['body'];
export type LoginInput = z.infer<typeof loginSchema>['body'];

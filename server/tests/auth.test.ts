import request from 'supertest';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import app from '../src/app.js';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

describe('Auth Routes (/api/v1/auth)', () => {
    const testPhone = '9998887776';
    const testEmail = 'testuser123@example.com';
    const testPassword = 'Password123!';

    // Clean up any existing test user before starting
    beforeAll(async () => {
        await prisma.user.deleteMany({
            where: {
                OR: [{ phone: testPhone }, { email: testEmail }],
            },
        });
    });

    afterAll(async () => {
        await prisma.user.deleteMany({
            where: {
                OR: [{ phone: testPhone }, { email: testEmail }],
            },
        });
    });

    describe('POST /signup', () => {
        it('should successfully create a new user and return standard response', async () => {
            const res = await request(app).post('/api/v1/auth/signup').send({
                name: 'Test Farmer',
                phone: testPhone,
                email: testEmail,
                password: testPassword,
                role: 'FARMER',
            });

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.message).toBe('User registered successfully');
            expect(res.body.data.user).toBeDefined();
            expect(res.body.data.user.phone).toBe(testPhone);
            expect(res.body.data.token).toBeDefined();
            expect(typeof res.body.data.token).toBe('string');
        });

        it('should fail with 400 if user with same phone exists', async () => {
            const res = await request(app).post('/api/v1/auth/signup').send({
                name: 'Another Farmer',
                phone: testPhone, // Same phone
                password: testPassword,
                role: 'FARMER',
            });

            expect(res.status).toBe(400);
            expect(res.body.success).toBe(false);
            expect(res.body.message).toBe('User with this phone number already exists.');
        });

        it('should fail validation if password is too short', async () => {
            const res = await request(app).post('/api/v1/auth/signup').send({
                name: 'Short Password User',
                phone: '1231231234',
                password: '123', // Less than 6 chars
                role: 'FARMER',
            });

            expect(res.status).toBe(400);
            expect(res.body.success).toBe(false);
            expect(res.body.message).toBe('Validation Error');
            expect(res.body.error.body.password._errors).toContain('Password must be at least 6 characters');
        });
    });

    describe('POST /login', () => {
        it('should successfully login and return standard response', async () => {
            const res = await request(app).post('/api/v1/auth/login').send({
                phone: testPhone,
                password: testPassword,
            });

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.message).toBe('Login successful');
            expect(res.body.data.user).toBeDefined();
            expect(res.body.data.token).toBeDefined();
        });

        it('should fail with 401 for wrong password', async () => {
            const res = await request(app).post('/api/v1/auth/login').send({
                phone: testPhone,
                password: 'WrongPassword!',
            });

            expect(res.status).toBe(401);
            expect(res.body.success).toBe(false);
            expect(res.body.message).toBe('Invalid credentials');
        });

        it('should fail with 401 for non-existent user', async () => {
            const res = await request(app).post('/api/v1/auth/login').send({
                phone: '0000000000',
                password: testPassword,
            });

            expect(res.status).toBe(401);
            expect(res.body.success).toBe(false);
            expect(res.body.message).toBe('Invalid credentials');
        });
    });
});

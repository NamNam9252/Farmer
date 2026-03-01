import { PrismaClient } from '@prisma/client';
import { afterAll } from 'vitest';


const prisma = new PrismaClient();

afterAll(async () => {
    await prisma.$disconnect();
});

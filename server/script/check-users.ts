import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    try {
        const users = await prisma.user.findMany({
            take: 10,
            select: {
                name: true,
                phone: true,
                email: true,
                role: true,
            }
        });
        console.log('USERS_FOUND:', JSON.stringify(users, null, 2));
    } catch (error) {
        console.error('ERROR:', error);
    } finally {
        await prisma.$disconnect();
    }
}

main();

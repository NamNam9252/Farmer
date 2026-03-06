import { PrismaClient, UserRole, UserStatus } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
    try {
        const phone = '1234567890';
        const password = 'password123';
        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = await prisma.user.create({
            data: {
                name: 'Test Farmer',
                phone: phone,
                email: 'test@farmer.com',
                passwordHash: hashedPassword,
                role: UserRole.FARMER,
                status: UserStatus.ACTIVE,
                preferredLanguage: 'hi',
            }
        });

        console.log('SUCCESS: User Created', newUser.id);
    } catch (error: any) {
        console.error('FAILED: Error creating user');
        console.error('CODE:', error.code);
        console.error('MESSAGE:', error.message);
        console.error('META:', JSON.stringify(error.meta, null, 2));
    } finally {
        await prisma.$disconnect();
    }
}

main();

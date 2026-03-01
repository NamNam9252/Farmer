import { PrismaClient, User, UserRole, UserStatus } from '@prisma/client';
import { SignupInput } from '../../schema/auth.schema.js';

const prisma = new PrismaClient();

export class AuthRepository {
    async findByPhone(phone: string): Promise<User | null> {
        return prisma.user.findUnique({
            where: { phone },
        });
    }

    async findByEmail(email: string): Promise<User | null> {
        return prisma.user.findUnique({
            where: { email },
        });
    }

    async createUser(data: SignupInput, passwordHash: string): Promise<User> {
        return prisma.user.create({
            data: {
                name: data.name,
                phone: data.phone,
                email: data.email,
                passwordHash,
                role: data.role as UserRole,
                status: UserStatus.ACTIVE, // Normally this would be PENDING_VERIFICATION, simplifying for now
            },
        });
    }
}

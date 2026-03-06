import { PrismaClient, User, UserRole, UserStatus, VerificationChannel } from '@prisma/client';
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
                status: UserStatus.PENDING_VERIFICATION,
            },
        });
    }

    async createVerification(userId: string, otpHash: string): Promise<any> {
        return prisma.userVerification.create({
            data: {
                userId,
                channel: VerificationChannel.EMAIL_LINK,
                otpHash,
                expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 mins
            }
        });
    }

    async findVerificationOrReject(userId: string): Promise<any> {
        return prisma.userVerification.findFirst({
            where: {
                userId,
                isUsed: false,
                expiresAt: { gt: new Date() }
            },
            orderBy: { createdAt: 'desc' }
        });
    }

    async markVerificationUsedAndActivateUser(verificationId: string, userId: string): Promise<User> {
        return prisma.$transaction(async (tx) => {
            await tx.userVerification.update({
                where: { id: verificationId },
                data: { isUsed: true }
            });
            return tx.user.update({
                where: { id: userId },
                data: { status: UserStatus.ACTIVE, isEmailVerified: true }
            });
        });
    }
}

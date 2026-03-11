import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

export class SchemesRepository {
    static async getAll() {
        return prisma.governmentScheme.findMany({
            where: {
                isActive: true,
                isDeleted: false,
            },
            orderBy: {
                createdAt: 'desc',
            },
        });
    }

    static async getById(id: string) {
        return prisma.governmentScheme.findUnique({
            where: { id },
        });
    }
}

import { PrismaClient, VisitStatus } from "@prisma/client";
const prisma = new PrismaClient();

export class ExpertVisitRepository {
  findFarmerProfileByUserId(userId: string) {
    return prisma.farmerProfile.findUnique({
      where: { userId },
    });
  }

  findExpertProfileByUserId(userId: string) {
    return prisma.expertProfile.findUnique({
      where: { userId },
    });
  }

  createVisit(data: {
    farmerId: string;
    problemDescription: string;
    cropName?: string | null;
    urgencyLevel?: string | null;
    locationId?: string | null;
    landId?: string | null;
    status: VisitStatus;
  }) {
    return prisma.expertVisit.create({ data });
  }

  findByFarmerId(farmerId: string) {
    return prisma.expertVisit.findMany({
      where: { farmerId },
      include: {
        expert: {
          include: { user: true }
        },
        location: true
      },
      orderBy: { createdAt: 'desc' }
    });
  }

  findAvailable() {
    return prisma.expertVisit.findMany({
      where: { status: VisitStatus.REQUESTED },
      include: {
        farmer: {
          include: { user: true }
        },
        location: true
      },
      orderBy: { createdAt: 'desc' }
    });
  }

  findById(id: string) {
    return prisma.expertVisit.findUnique({
      where: { id },
    });
  }

  update(id: string, data: any) {
    return prisma.expertVisit.update({
      where: { id },
      data,
    });
  }
}

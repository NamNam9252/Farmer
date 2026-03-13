import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

export class LaborRepository {
  findProfileByUserId(userId: string) {
    return prisma.laborProfile.findUnique({
      where: { userId },
    });
  }

  createProfile(data: {
    userId: string;
    skills: string[];
    experienceYears?: number;
    dailyRate?: number;
    districtId?: string;
    latitude?: number;
    longitude?: number;
    serviceRadiusKm?: number;
  }) {
    return prisma.laborProfile.create({ data });
  }

  findAvailable(districtId?: string) {
    return prisma.laborProfile.findMany({
      where: {
        isAvailable: true,
        isDeleted: false,
        districtId,
      },
    });
  }

  findById(id: string) {
    return prisma.laborProfile.findUnique({
      where: { id },
    });
  }

  setAvailability(id: string, isAvailable: boolean) {
    return prisma.laborProfile.update({
      where: { id },
      data: { isAvailable },
    });
  }

  findActiveEmployment(laborId: string) {
    return prisma.laborEmployment.findFirst({
      where: {
        laborId,
        status: "ACTIVE",
      },
    });
  }

  createEmployment(data: {
    laborId: string;
    farmerId: string;
    wageAmount: number;
    workHoursPerDay?: number;
    workDaysPerWeek?: number;
    startDate: Date;
  }) {
    return prisma.laborEmployment.create({ data });
  }

  terminateEmployment(id: string) {
    return prisma.laborEmployment.update({
      where: { id },
      data: {
        status: "TERMINATED",
        endDate: new Date(),
      },
    });
  }

  findFarmerLabor(farmerId: string) {
    return prisma.laborEmployment.findMany({
      where: {
        farmerId,
        status: "ACTIVE",
      },
      include: {
        labor: true,
      },
    });
  }

  findFarmerProfile(userId: string) {
    return prisma.farmerProfile.findUnique({
      where: { userId },
    });
  }
}

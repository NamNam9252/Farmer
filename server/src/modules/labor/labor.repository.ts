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

  async upsertProfile(userId: string, data: {
    skills?: string[];
    experienceYears?: number;
    dailyRate?: number;
    districtId?: string;
    latitude?: number;
    longitude?: number;
    serviceRadiusKm?: number;
    name?: string;
    phone?: string;
  }) {
    return prisma.$transaction(async (tx) => {
      // 1. Upsert LaborProfile
      const profile = await tx.laborProfile.upsert({
        where: { userId },
        create: {
          userId,
          skills: data.skills ?? [],
          experienceYears: data.experienceYears ?? 0,
          dailyRate: data.dailyRate ?? 0,
          serviceRadiusKm: data.serviceRadiusKm ?? 10,
          ...(data.districtId ? { districtId: data.districtId } : {}),
          ...(data.latitude ? { latitude: data.latitude } : {}),
          ...(data.longitude ? { longitude: data.longitude } : {}),
        },
        update: {
          ...(data.skills !== undefined && { skills: data.skills }),
          ...(data.experienceYears !== undefined && { experienceYears: data.experienceYears }),
          ...(data.dailyRate !== undefined && { dailyRate: data.dailyRate }),
          ...(data.districtId !== undefined && { districtId: data.districtId }),
          ...(data.latitude !== undefined && { latitude: data.latitude }),
          ...(data.longitude !== undefined && { longitude: data.longitude }),
          ...(data.serviceRadiusKm !== undefined && { serviceRadiusKm: data.serviceRadiusKm }),
        },
      });

      // 2. Update User if name or phone provided
      if (data.name !== undefined || data.phone !== undefined) {
        await tx.user.update({
          where: { id: userId },
          data: {
            ...(data.name !== undefined && { name: data.name }),
            ...(data.phone !== undefined && { phone: data.phone }),
          },
        });
      }

      return profile;
    });
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

import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

export class LaborRepository {
  findProfileByUserId(userId: string) {
    return prisma.laborProfile.findUnique({
      where: { userId },
    });
  }

  findProfileById(id: string) {
    return prisma.laborProfile.findUnique({
      where: { id },
      include: {
        user: true,
      },
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

  findAvailable(districtId?: string, all?: boolean) {
    return prisma.laborProfile.findMany({
      where: {
        ...(all ? {} : { isAvailable: true }),
        isDeleted: false,
        ...(districtId ? { districtId } : {}),
        // Ensure user exists to avoid Prisma crash on required relation
        // Using a string field (name) instead of ID to avoid Malformed ObjectID validation on empty string
        user: {
          name: {
            not: "",
          },
        },
      },
      include: {
        user: true,
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

  async findUserByLaborId(laborId: string) {
    const labor = await prisma.laborProfile.findUnique({
      where: { id: laborId },
      select: { userId: true },
    });
    return labor?.userId;
  }

  async findLaborEmployments(laborId: string) {
    return prisma.laborEmployment.findMany({
      where: { laborId },
      include: {
        farmer: {
          include: {
            user: true,
          },
        },
      },
    });
  }

  findOverlappingConfirmedBooking(
    laborId: string,
    startDate: Date,
    endDate: Date,
    excludeBookingId?: string,
  ) {
    return prisma.laborBooking.findFirst({
      where: {
        laborId,
        status: {
          in: ["ACCEPTED", "ONGOING"],
        },
        ...(excludeBookingId
          ? {
              id: {
                not: excludeBookingId,
              },
            }
          : {}),
        startDate: {
          lte: endDate,
        },
        OR: [
          {
            endDate: null,
          },
          {
            endDate: {
              gte: startDate,
            },
          },
        ],
      },
    });
  }

  createBooking(data: {
    laborId: string;
    farmerId: string;
    landId?: string;
    taskDescription: string;
    startDate: Date;
    endDate?: Date;
    agreedRate?: number;
    totalAmount?: number;
    status?: "REQUESTED" | "ACCEPTED";
  }) {
    return prisma.laborBooking.create({
      data: {
        laborId: data.laborId,
        farmerId: data.farmerId,
        ...(data.landId ? { landId: data.landId } : {}),
        taskDescription: data.taskDescription,
        startDate: data.startDate,
        ...(data.endDate ? { endDate: data.endDate } : {}),
        ...(data.agreedRate !== undefined ? { agreedRate: data.agreedRate } : {}),
        ...(data.totalAmount !== undefined ? { totalAmount: data.totalAmount } : {}),
        ...(data.status ? { status: data.status } : {}),
      },
      include: {
        labor: {
          include: {
            user: true,
          },
        },
        farmer: {
          include: {
            user: true,
          },
        },
      },
    });
  }

  findBookingById(id: string) {
    return prisma.laborBooking.findUnique({
      where: { id },
      include: {
        labor: {
          include: {
            user: true,
          },
        },
        farmer: {
          include: {
            user: true,
          },
        },
      },
    });
  }

  updateBookingStatus(
    id: string,
    status: "ACCEPTED" | "REJECTED" | "CANCELLED" | "COMPLETED" | "ONGOING",
    cancelReason?: string,
  ) {
    return prisma.laborBooking.update({
      where: { id },
      data: {
        status,
        ...(cancelReason ? { cancelReason } : {}),
      },
      include: {
        labor: {
          include: {
            user: true,
          },
        },
        farmer: {
          include: {
            user: true,
          },
        },
      },
    });
  }

  findLaborBookingRequests(laborId: string) {
    return prisma.laborBooking.findMany({
      where: {
        laborId,
        status: "REQUESTED",
      },
      include: {
        farmer: {
          include: {
            user: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });
  }

  findLaborBookings(laborId: string) {
    return prisma.laborBooking.findMany({
      where: {
        laborId,
        status: {
          in: ["ACCEPTED", "ONGOING", "COMPLETED"],
        },
      },
      include: {
        farmer: {
          include: {
            user: true,
          },
        },
      },
      orderBy: {
        startDate: "desc",
      },
    });
  }

  findFarmerBookings(farmerId: string) {
    return prisma.laborBooking.findMany({
      where: {
        farmerId,
        status: {
          in: ["ACCEPTED", "ONGOING", "REQUESTED"],
        },
      },
      include: {
        labor: {
          include: {
            user: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });
  }
}

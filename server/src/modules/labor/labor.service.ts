import { PrismaClient } from "@prisma/client";
import { LaborRepository } from "./labor.repository.js";

const prisma = new PrismaClient();

export class LaborService {
  private repo = new LaborRepository();

  async createProfile(userId: string, body: any) {
    const existing = await this.repo.findProfileByUserId(userId);
    if (existing) throw new Error("Labor profile already exists");

    return this.repo.createProfile({
      userId,
      skills: body.skills,
      experienceYears: body.experienceYears,
      dailyRate: body.dailyRate,
      districtId: body.districtId,
      latitude: body.latitude,
      longitude: body.longitude,
      serviceRadiusKm: body.serviceRadiusKm,
    });
  }

  async getProfile(userId: string) {
    const profile = await this.repo.findProfileByUserId(userId);
    if (!profile) return null;
    return profile;
  }

  async updateProfile(userId: string, body: any) {
    return this.repo.upsertProfile(userId, {
      skills: body.skills,
      experienceYears: body.experienceYears,
      dailyRate: body.dailyRate,
      districtId: body.districtId,
      latitude: body.latitude,
      longitude: body.longitude,
      serviceRadiusKm: body.serviceRadiusKm,
      name: body.name,
      phone: body.phone,
    });
  }

  async listAvailable(districtId?: string) {
    return this.repo.findAvailable(districtId);
  }

  async hireLabor(userId: string, laborId: string, body: any) {
    const farmer = await this.repo.findFarmerProfile(userId);
    if (!farmer) throw new Error("Farmer profile not found");

    const active = await this.repo.findActiveEmployment(laborId);
    if (active) throw new Error("Labor already employed");

    return prisma.$transaction(async (tx) => {
      const employment = await tx.laborEmployment.create({
        data: {
          laborId,
          farmerId: farmer.id,
          wageAmount: body.wageAmount,
          workHoursPerDay: body.workHoursPerDay,
          workDaysPerWeek: body.workDaysPerWeek,
          startDate: new Date(),
        },
      });

      await tx.laborProfile.update({
        where: { id: laborId },
        data: { isAvailable: false },
      });

      return employment;
    });
  }

  async terminateEmployment(employmentId: string) {
    const employment = await this.repo.terminateEmployment(employmentId);

    await this.repo.setAvailability(employment.laborId, true);

    return employment;
  }

  async farmerLabor(userId: string) {
    const farmer = await this.repo.findFarmerProfile(userId);
    if (!farmer) throw new Error("Farmer profile not found");

    return this.repo.findFarmerLabor(farmer.id);
  }
}

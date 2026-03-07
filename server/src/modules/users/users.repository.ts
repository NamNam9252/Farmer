import { PrismaClient, LocationType } from '@prisma/client';
import { LocationInput, FarmerProfileInput, LaborProfileInput, ExpertProfileInput } from '../../schema/user.schema.js';

const prisma = new PrismaClient();

export class UsersRepository {
    async createPrimaryLocation(userId: string, data: LocationInput) {
        return prisma.$transaction(async (tx) => {
            const location = await tx.location.create({
                data: {
                    userId,
                    type: data.type as LocationType,
                    label: data.label,
                    isPrimary: true,
                    stateId: data.stateId,
                    districtId: data.districtId,
                    pincodeId: data.pincodeId,
                    village: data.village,
                    addressLine: data.addressLine,
                    latitude: data.latitude,
                    longitude: data.longitude,
                }
            });

            await tx.user.update({
                where: { id: userId },
                data: { primaryLocationId: location.id }
            });

            return location;
        });
    }

    async createFarmerProfile(userId: string, data: FarmerProfileInput) {
        return prisma.farmerProfile.create({
            data: {
                userId,
                totalLandArea: data.totalLandArea,
                experienceYears: data.experienceYears,
                aadhaarLast4: data.aadhaarLast4,
            }
        });
    }

    async createLaborProfile(userId: string, data: LaborProfileInput) {
        return prisma.laborProfile.create({
            data: {
                userId,
                skills: data.skills || [],
                experienceYears: data.experienceYears,
                dailyRate: data.dailyRate,
                serviceRadiusKm: data.serviceRadiusKm,
            }
        });
    }

    async createExpertProfile(userId: string, data: ExpertProfileInput) {
        return prisma.expertProfile.create({
            data: {
                userId,
                specializations: data.specializations || [],
                qualifications: data.qualifications,
                institution: data.institution,
                yearsExperience: data.yearsExperience,
            }
        });
    }
}

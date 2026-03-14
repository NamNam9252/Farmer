import { ExpertVisitRepository } from "./expert-visit.repository.js";
import { CreateVisitRequestInput, UpdateVisitStatusInput } from "../../schema/expert-visit.schema.js";
import { VisitStatus } from "@prisma/client";

export class ExpertVisitService {
  private repository: ExpertVisitRepository;

  constructor() {
    this.repository = new ExpertVisitRepository();
  }

  async requestVisit(userId: string, input: CreateVisitRequestInput) {
    const farmerProfile = await this.repository.findFarmerProfileByUserId(userId);
    if (!farmerProfile) {
      throw new Error('Farmer profile not found / किसान प्रोफ़ाइल नहीं मिली');
    }

    return this.repository.createVisit({
      farmerId: farmerProfile.id,
      ...input,
      status: VisitStatus.REQUESTED,
    });
  }

  async getFarmerRequests(userId: string) {
    const farmerProfile = await this.repository.findFarmerProfileByUserId(userId);
    if (!farmerProfile) {
      throw new Error('Farmer profile not found / किसान प्रोफ़ाइल नहीं मिली');
    }

    return this.repository.findByFarmerId(farmerProfile.id);
  }

  async getAvailableRequests() {
    return this.repository.findAvailable();
  }

  async acceptVisit(userId: string, visitId: string) {
    const expertProfile = await this.repository.findExpertProfileByUserId(userId);
    if (!expertProfile) {
      throw new Error('Expert profile not found');
    }

    const visit = await this.repository.findById(visitId);
    if (!visit) {
      throw new Error('Visit request not found');
    }

    if (visit.status !== VisitStatus.REQUESTED) {
      throw new Error('Visit request is no longer available');
    }

    return this.repository.update(visitId, {
      expertId: expertProfile.id,
      status: VisitStatus.ACCEPTED,
    });
  }

  async updateVisit(userId: string, visitId: string, input: UpdateVisitStatusInput) {
    const expertProfile = await this.repository.findExpertProfileByUserId(userId);
    if (!expertProfile) {
      throw new Error('Expert profile not found');
    }

    const visit = await this.repository.findById(visitId);
    if (!visit) {
      throw new Error('Visit request not found');
    }

    if (visit.expertId !== expertProfile.id) {
      throw new Error('Not authorized to update this visit');
    }

    const updateData: any = {};
    if (input.status) updateData.status = input.status;
    if (input.notes) updateData.notes = input.notes;
    if (input.scheduledAt) updateData.scheduledAt = new Date(input.scheduledAt);
    if (input.status === VisitStatus.COMPLETED) updateData.completedAt = new Date();

    return this.repository.update(visitId, updateData);
  }
}

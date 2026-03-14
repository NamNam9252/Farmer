import { LaborRepository } from "./labor.repository.js";
import { createNotification } from "../notifications/notification.service.js";

export class LaborService {
  private repo = new LaborRepository();

  private parseDateRange(startDateInput: string, endDateInput?: string) {
    const startDate = new Date(startDateInput);
    if (Number.isNaN(startDate.getTime())) {
      throw new Error("Invalid start date");
    }

    const parsedEndDate = endDateInput ? new Date(endDateInput) : new Date(startDateInput);
    if (Number.isNaN(parsedEndDate.getTime())) {
      throw new Error("Invalid end date");
    }

    if (parsedEndDate < startDate) {
      throw new Error("End date must be on or after start date");
    }

    return { startDate, endDate: parsedEndDate };
  }

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

  async listAvailable(districtId?: string, all?: boolean) {
    return this.repo.findAvailable(districtId, all);
  }

  async requestBooking(userId: string, laborId: string, body: any) {
    const farmer = await this.repo.findFarmerProfile(userId);
    if (!farmer) throw new Error("Farmer profile not found");

    const labor = await this.repo.findProfileById(laborId);
    if (!labor) throw new Error("Labor profile not found");

    if (!body.taskDescription || typeof body.taskDescription !== "string") {
      throw new Error("Task description is required");
    }

    if (!body.startDate || typeof body.startDate !== "string") {
      throw new Error("Start date is required");
    }

    const { startDate, endDate } = this.parseDateRange(body.startDate, body.endDate);

    const overlap = await this.repo.findOverlappingConfirmedBooking(laborId, startDate, endDate);
    if (overlap) {
      throw new Error("Labor already has an accepted booking in this date range");
    }

    const booking = await this.repo.createBooking({
      laborId,
      farmerId: farmer.id,
      landId: body.landId,
      taskDescription: body.taskDescription,
      startDate,
      endDate,
      agreedRate: body.agreedRate,
      totalAmount: body.totalAmount,
      status: "REQUESTED",
    });

    await createNotification({
      userId: labor.userId,
      title: "New labor booking request",
      body: `You have a new booking request from ${booking.farmer.user.name}.`,
    });

    return {
      success: true,
      message: "Booking request sent",
      data: booking,
    };
  }

  async getLaborBookingRequests(userId: string) {
    const labor = await this.repo.findProfileByUserId(userId);
    if (!labor) throw new Error("Labor profile not found");

    const requests = await this.repo.findLaborBookingRequests(labor.id);
    return { success: true, data: requests };
  }

  async respondToBookingRequest(userId: string, bookingId: string, body: any) {
    const labor = await this.repo.findProfileByUserId(userId);
    if (!labor) throw new Error("Labor profile not found");

    const booking = await this.repo.findBookingById(bookingId);
    if (!booking) throw new Error("Booking request not found");
    if (booking.laborId !== labor.id) throw new Error("Unauthorized booking action");
    if (booking.status !== "REQUESTED") throw new Error("Only pending requests can be updated");

    const action = body.action as "accept" | "reject";
    if (action !== "accept" && action !== "reject") {
      throw new Error("Action must be accept or reject");
    }

    if (action === "accept") {
      const effectiveEndDate = booking.endDate ?? booking.startDate;
      const overlap = await this.repo.findOverlappingConfirmedBooking(
        booking.laborId,
        booking.startDate,
        effectiveEndDate,
        booking.id,
      );

      if (overlap) {
        throw new Error("You already have an accepted booking in this period");
      }

      const accepted = await this.repo.updateBookingStatus(booking.id, "ACCEPTED");
      await createNotification({
        userId: booking.farmer.userId,
        title: "Labor booking accepted",
        body: `${booking.labor.user.name} accepted your booking request.`,
      });

      return {
        success: true,
        message: "Booking request accepted",
        data: accepted,
      };
    }

    const rejected = await this.repo.updateBookingStatus(
      booking.id,
      "REJECTED",
      typeof body.cancelReason === "string" ? body.cancelReason : undefined,
    );
    await createNotification({
      userId: booking.farmer.userId,
      title: "Labor booking rejected",
      body: `${booking.labor.user.name} rejected your booking request.`,
    });

    return {
      success: true,
      message: "Booking request rejected",
      data: rejected,
    };
  }

  async hireLabor(userId: string, laborId: string, body: any) {
    const farmer = await this.repo.findFarmerProfile(userId);
    if (!farmer) throw new Error("Farmer profile not found");

    const labor = await this.repo.findProfileById(laborId);
    if (!labor) throw new Error("Labor profile not found");

    const startDate =
      typeof body.startDate === "string" && body.startDate.length > 0
        ? new Date(body.startDate)
        : new Date();
    const endDate =
      typeof body.endDate === "string" && body.endDate.length > 0
        ? new Date(body.endDate)
        : startDate;

    if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
      throw new Error("Invalid booking date");
    }

    const overlap = await this.repo.findOverlappingConfirmedBooking(laborId, startDate, endDate);
    if (overlap) throw new Error("Labor already has an accepted booking in this date range");

    const booking = await this.repo.createBooking({
      laborId,
      farmerId: farmer.id,
      taskDescription:
        typeof body.taskDescription === "string" && body.taskDescription.length > 0
          ? body.taskDescription
          : "General farm work",
      startDate,
      endDate,
      agreedRate: body.wageAmount,
      status: "ACCEPTED",
    });

    await createNotification({
      userId: labor.userId,
      title: "New booking confirmed",
      body: `A farmer booked you from ${startDate.toDateString()} to ${endDate.toDateString()}.`,
    });

    return {
      success: true,
      message: "Labor booked successfully",
      data: booking,
    };
  }

  async terminateEmployment(employmentId: string) {
    const employment = await this.repo.terminateEmployment(employmentId);

    await this.repo.setAvailability(employment.laborId, true);

    return employment;
  }

  async farmerLabor(userId: string) {
    const farmer = await this.repo.findFarmerProfile(userId);
    if (!farmer) throw new Error("Farmer profile not found");

    const data = await this.repo.findFarmerBookings(farmer.id);
    return { success: true, data };
  }

  async getMyEmployments(userId: string) {
    const labor = await this.repo.findProfileByUserId(userId);
    if (!labor) throw new Error("Labor profile not found");

    return this.repo.findLaborBookings(labor.id);
  }
}

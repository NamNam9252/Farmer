import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { PrismaClient } from "@prisma/client";
import { randomBytes } from "crypto";
import { WarehouseRepository } from "../src/modules/warehouse/warehouse.repository.js";

const prisma = new PrismaClient();
const repo = new WarehouseRepository();

describe("WarehouseRepository", () => {
  let ownerId: string;
  let offererId: string;
  let listing: any;
  let offer: any;

  beforeAll(async () => {
    // create valid-looking ObjectId hex strings for user IDs
    ownerId = randomBytes(12).toString("hex");
    offererId = randomBytes(12).toString("hex");

    // create a dummy location so we have a valid locationId for the listing
    const location = await prisma.location.create({
      data: {
        userId: ownerId,
        type: "WAREHOUSE",
        latitude: 0,
        longitude: 0,
        stateId: ownerId,
        districtId: ownerId,
        pincodeId: ownerId,
      },
    });

    listing = await repo.createListing(ownerId, {
      locationId: location.id,
      title: "Test Listing",
      totalAreaSqft: 100,
      askingPricePerMonth: 1000,
      availableFrom: new Date(),
      availableUntil: new Date(Date.now() + 1000 * 60 * 60 * 24),
      amenities: [],
      latitude: 0,
      longitude: 0,
    });

    offer = await repo.createOffer(listing.id, offererId, {
      offeredPricePerMonth: 900,
      requestedFrom: new Date(),
      requestedUntil: new Date(Date.now() + 1000 * 60 * 60 * 24),
    });
  });

  afterAll(async () => {
    // cleanup
    if (listing && listing.id) {
      await prisma.warehouseRental.deleteMany({
        where: { listingId: listing.id },
      });
      await prisma.warehouseRentalOffer.deleteMany({
        where: { listingId: listing.id },
      });
      await prisma.warehouseListing.deleteMany({ where: { id: listing.id } });
    }
    // also remove the dummy location if it was created
    await prisma.location.deleteMany({
      where: { userId: ownerId, type: "WAREHOUSE" },
    });
    await prisma.$disconnect();
  });

  it("acceptOfferAndCreateRental should persist a rental with correct ownerId", async () => {
    const rental = await repo.acceptOfferAndCreateRental(
      listing.id,
      ownerId,
      offer,
    );
    expect(rental).toBeDefined();
    expect(rental.ownerId).toBe(ownerId);
    expect(rental.tenantId).toBe(offererId);
    expect(rental.status).toBe("ACTIVE");
  });
});

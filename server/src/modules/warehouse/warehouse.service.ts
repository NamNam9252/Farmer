import { WarehouseRepository } from "./warehouse.repository.js";
import {
  CreateListingInput,
  SubmitOfferInput,
  AddInventoryItemInput,
  UpdateInventoryInput,
} from "../../schema/warehouse.schema.js";
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
  ConflictError,
} from "../../core/errors/custom.error.js";

export class WarehouseService {
  private repository: WarehouseRepository;

  constructor() {
    this.repository = new WarehouseRepository();
  }

  // ── Listings ─────────────────────────────────────────────

  async createListing(ownerId: string, data: CreateListingInput) {
    return this.repository.createListing(ownerId, data);
  }

  async getNearbyListings(lat: number, lng: number, radiusKm: number) {
    return this.repository.findNearbyListings(lat, lng, radiusKm);
  }

  // ── Offers ───────────────────────────────────────────────

  async submitOffer(
    listingId: string,
    offererId: string,
    data: SubmitOfferInput,
  ) {
    const listing = await this.repository.findListingById(listingId);
    if (!listing) throw new NotFoundError("Listing not found");
    if (listing.status !== "OPEN")
      throw new BadRequestError("Listing is not open for offers");
    if (listing.ownerId === offererId)
      throw new BadRequestError("You cannot offer on your own listing");

    const existing = await this.repository.findExistingPendingOffer(
      listingId,
      offererId,
    );
    if (existing)
      throw new ConflictError(
        "You already have a pending offer on this listing",
      );

    return this.repository.createOffer(listingId, offererId, data);
  }

  async getOffersForListing(listingId: string, requestingUserId: string) {
    const listing = await this.repository.findListingById(listingId);
    if (!listing) throw new NotFoundError("Listing not found");
    if (listing.ownerId !== requestingUserId)
      throw new ForbiddenError("Only the listing owner can view offers");
    return this.repository.findOffersByListing(listingId);
  }

  async acceptOffer(
    listingId: string,
    offerId: string,
    requestingUserId: string,
  ) {
    const listing = await this.repository.findListingById(listingId);
    if (!listing) throw new NotFoundError("Listing not found");
    if (listing.ownerId !== requestingUserId)
      throw new ForbiddenError("Only the listing owner can accept offers");
    if (listing.status !== "OPEN")
      throw new BadRequestError("Listing is no longer open");

    const offer = await this.repository.findOfferById(offerId);
    if (!offer || offer.listingId !== listingId)
      throw new NotFoundError("Offer not found");
    if (offer.status !== "PENDING")
      throw new BadRequestError("Offer is no longer pending");

    // pass ownerId so the repository can correctly create the rental
    return this.repository.acceptOfferAndCreateRental(
      listingId,
      listing.ownerId,
      offer,
    );
  }

  async withdrawOffer(offerId: string, requestingUserId: string) {
    const offer = await this.repository.findOfferById(offerId);
    if (!offer) throw new NotFoundError("Offer not found");
    if (offer.offererId !== requestingUserId)
      throw new ForbiddenError("You can only withdraw your own offers");
    if (offer.status !== "PENDING")
      throw new BadRequestError("Only pending offers can be withdrawn");
    return this.repository.updateOfferStatus(offerId, "WITHDRAWN");
  }

  // ── Rentals ──────────────────────────────────────────────

  async getMyRentals(userId: string) {
    const [asOwner, asTenant] = await Promise.all([
      this.repository.findRentalsByOwner(userId),
      this.repository.findRentalsByTenant(userId),
    ]);
    return { asOwner, asTenant };
  }

  // ── Inventory ────────────────────────────────────────────

  async addInventoryItem(ownerId: string, data: AddInventoryItemInput) {
    if (data.sourceType === "LEASED") {
      const rental = await this.repository.findRentalById(data.rentalId!);
      if (!rental) throw new NotFoundError("Rental not found");
      if (rental.tenantId !== ownerId)
        throw new ForbiddenError("This rental does not belong to you");
      if (rental.status !== "ACTIVE")
        throw new BadRequestError("Rental is not active");
      data.locationId = undefined;
    }

    if (data.sourceType === "OWNED") {
      data.rentalId = undefined;
    }

    return this.repository.createInventoryItem(ownerId, data);
  }

  async getMyInventory(ownerId: string) {
    const items = await this.repository.findInventoryByOwner(ownerId);

    const owned = Object.values(
      items
        .filter((i) => i.sourceType === "OWNED")
        .reduce<Record<string, { locationId: string; items: typeof items }>>(
          (acc, item) => {
            const key = item.locationId!;
            if (!acc[key]) acc[key] = { locationId: key, items: [] };
            acc[key].items.push(item);
            return acc;
          },
          {},
        ),
    );

    const leased = Object.values(
      items
        .filter((i) => i.sourceType === "LEASED")
        .reduce<Record<string, { rentalId: string; items: typeof items }>>(
          (acc, item) => {
            const key = item.rentalId!;
            if (!acc[key]) acc[key] = { rentalId: key, items: [] };
            acc[key].items.push(item);
            return acc;
          },
          {},
        ),
    );

    return { owned, leased };
  }

  async updateInventoryItem(
    itemId: string,
    ownerId: string,
    data: UpdateInventoryInput,
  ) {
    const item = await this.repository.findInventoryItemById(itemId);
    if (!item) throw new NotFoundError("Inventory item not found");
    if (item.ownerId !== ownerId)
      throw new ForbiddenError("This item does not belong to you");
    return this.repository.updateInventoryItem(itemId, data);
  }

  async deleteInventoryItem(itemId: string, ownerId: string) {
    const item = await this.repository.findInventoryItemById(itemId);
    if (!item) throw new NotFoundError("Inventory item not found");
    if (item.ownerId !== ownerId)
      throw new ForbiddenError("This item does not belong to you");
    return this.repository.softDeleteInventoryItem(itemId);
  }
}

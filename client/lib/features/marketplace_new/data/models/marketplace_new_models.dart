class MarketplaceItem {
  final String id;
  final String sellerId;
  final String itemName;
  final String category;
  final String quantity;
  final double pricePerUnit;
  final String location;
  final String? description;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? seller;

  MarketplaceItem({
    required this.id,
    required this.sellerId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.pricePerUnit,
    required this.location,
    this.description,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.seller,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    String? parseImageUrl(Map<String, dynamic> data) {
      final direct = data['imageUrl'] ?? data['image_url'] ?? data['image'];
      if (direct is String && direct.isNotEmpty) return direct;

      final images = data['images'];
      if (images is List && images.isNotEmpty && images.first is String) {
        final first = images.first as String;
        if (first.isNotEmpty) return first;
      }
      return null;
    }

    return MarketplaceItem(
      id: json['id']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OTHER',
      quantity: json['quantity']?.toString() ?? '',
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      seller: json['seller'] as Map<String, dynamic>?,
    );
  }
}

class MarketplaceDemand {
  final String id;
  final String buyerId;
  final String itemName;
  final String category;
  final String quantityNeeded;
  final double expectedPrice;
  final String location;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? buyer;

  MarketplaceDemand({
    required this.id,
    required this.buyerId,
    required this.itemName,
    required this.category,
    required this.quantityNeeded,
    required this.expectedPrice,
    required this.location,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.buyer,
  });

  factory MarketplaceDemand.fromJson(Map<String, dynamic> json) {
    return MarketplaceDemand(
      id: json['id']?.toString() ?? '',
      buyerId: json['buyerId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OTHER',
      quantityNeeded: json['quantityNeeded']?.toString() ?? '',
      expectedPrice: (json['expectedPrice'] as num?)?.toDouble() ?? 0.0,
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      buyer: json['buyer'] as Map<String, dynamic>?,
    );
  }
}

class PurchaseRequest {
  final String id;
  final String itemId;
  final String buyerId;
  final String sellerId;
  final String requestedQuantity;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MarketplaceItem? item;
  final Map<String, dynamic>? buyer;
  final Map<String, dynamic>? seller;

  PurchaseRequest({
    required this.id,
    required this.itemId,
    required this.buyerId,
    required this.sellerId,
    required this.requestedQuantity,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.item,
    this.buyer,
    this.seller,
  });

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) {
    return PurchaseRequest(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      buyerId: json['buyerId']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      requestedQuantity: json['requestedQuantity']?.toString() ?? '',
      message: json['message']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      item: json['item'] != null ? MarketplaceItem.fromJson(json['item']) : null,
      buyer: json['buyer'] as Map<String, dynamic>?,
      seller: json['seller'] as Map<String, dynamic>?,
    );
  }
}

class DemandOffer {
  final String id;
  final String demandId;
  final String sellerId;
  final String buyerId;
  final String quantityAvailable;
  final double offeredPrice;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MarketplaceDemand? demand;
  final Map<String, dynamic>? seller;
  final Map<String, dynamic>? buyer;

  DemandOffer({
    required this.id,
    required this.demandId,
    required this.sellerId,
    required this.buyerId,
    required this.quantityAvailable,
    required this.offeredPrice,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.demand,
    this.seller,
    this.buyer,
  });

  factory DemandOffer.fromJson(Map<String, dynamic> json) {
    return DemandOffer(
      id: json['id']?.toString() ?? '',
      demandId: json['demandId']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      buyerId: json['buyerId']?.toString() ?? '',
      quantityAvailable: json['quantityAvailable']?.toString() ?? '',
      offeredPrice: (json['offeredPrice'] as num?)?.toDouble() ?? 0.0,
      message: json['message']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      demand: json['demand'] != null ? MarketplaceDemand.fromJson(json['demand']) : null,
      seller: json['seller'] as Map<String, dynamic>?,
      buyer: json['buyer'] as Map<String, dynamic>?,
    );
  }
}

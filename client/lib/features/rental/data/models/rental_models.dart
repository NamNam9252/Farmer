enum AssetType {
  PROPERTY,
  VEHICLE,
  EQUIPMENT,
  OTHER
}

enum AssetStatus {
  AVAILABLE,
  LOCKED,
  INACTIVE
}

enum BidStatus {
  PENDING,
  ACCEPTED,
  REJECTED,
  WITHDRAWN
}

enum RentalStatus {
  UPCOMING,
  ACTIVE,
  COMPLETED,
  CANCELLED
}

class RentalAsset {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final AssetType type;
  final AssetStatus status;
  final double basePrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final Map<String, dynamic>? owner;

  RentalAsset({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.basePrice,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.owner,
  });

  factory RentalAsset.fromJson(Map<String, dynamic> json) {
    return RentalAsset(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _parseAssetType(json['type']),
      status: _parseAssetStatus(json['status']),
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['imageUrl'],
      owner: json['owner'],
    );
  }

  static AssetType _parseAssetType(String? type) {
    switch (type) {
      case 'PROPERTY': return AssetType.PROPERTY;
      case 'VEHICLE': return AssetType.VEHICLE;
      case 'EQUIPMENT': return AssetType.EQUIPMENT;
      default: return AssetType.OTHER;
    }
  }

  static AssetStatus _parseAssetStatus(String? status) {
    switch (status) {
      case 'AVAILABLE': return AssetStatus.AVAILABLE;
      case 'LOCKED': return AssetStatus.LOCKED;
      default: return AssetStatus.INACTIVE;
    }
  }
}

class RentalBid {
  final String id;
  final String assetId;
  final String bidderId;
  final double amount;
  final BidStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? bidder;
  final RentalAsset? asset;

  RentalBid({
    required this.id,
    required this.assetId,
    required this.bidderId,
    required this.amount,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.bidder,
    this.asset,
  });

  factory RentalBid.fromJson(Map<String, dynamic> json) {
    return RentalBid(
      id: json['id'] ?? '',
      assetId: json['assetId'] ?? '',
      bidderId: json['bidderId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: _parseBidStatus(json['status']),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      bidder: json['bidder'],
      asset: json['asset'] != null ? RentalAsset.fromJson(json['asset']) : null,
    );
  }

  static BidStatus _parseBidStatus(String? status) {
    switch (status) {
      case 'PENDING': return BidStatus.PENDING;
      case 'ACCEPTED': return BidStatus.ACCEPTED;
      case 'REJECTED': return BidStatus.REJECTED;
      case 'WITHDRAWN': return BidStatus.WITHDRAWN;
      default: return BidStatus.PENDING;
    }
  }
}

class RentalOrder {
  final String id;
  final String assetId;
  final String bidId;
  final String tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final double agreedPrice;
  final RentalStatus status;
  final RentalAsset? asset;
  final RentalBid? bid;

  RentalOrder({
    required this.id,
    required this.assetId,
    required this.bidId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.agreedPrice,
    required this.status,
    this.asset,
    this.bid,
  });

  factory RentalOrder.fromJson(Map<String, dynamic> json) {
    return RentalOrder(
      id: json['id'] ?? '',
      assetId: json['assetId'] ?? '',
      bidId: json['bidId'] ?? '',
      tenantId: json['tenantId'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      agreedPrice: (json['agreedPrice'] as num?)?.toDouble() ?? 0.0,
      status: _parseRentalStatus(json['status']),
      asset: json['asset'] != null ? RentalAsset.fromJson(json['asset']) : null,
      bid: json['bid'] != null ? RentalBid.fromJson(json['bid']) : null,
    );
  }

  static RentalStatus _parseRentalStatus(String? status) {
    switch (status) {
      case 'UPCOMING': return RentalStatus.UPCOMING;
      case 'ACTIVE': return RentalStatus.ACTIVE;
      case 'COMPLETED': return RentalStatus.COMPLETED;
      case 'CANCELLED': return RentalStatus.CANCELLED;
      default: return RentalStatus.UPCOMING;
    }
  }
}

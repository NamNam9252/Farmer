class LocationEntity {
  final String? id;
  final String type; // 'HOME', 'FARM', 'WAREHOUSE', etc.
  final String? label;
  final String stateId;
  final String districtId;
  final String pincodeId;
  final String? village;
  final String? addressLine;
  final double latitude;
  final double longitude;

  const LocationEntity({
    this.id,
    required this.type,
    this.label,
    required this.stateId,
    required this.districtId,
    required this.pincodeId,
    this.village,
    this.addressLine,
    required this.latitude,
    required this.longitude,
  });
}

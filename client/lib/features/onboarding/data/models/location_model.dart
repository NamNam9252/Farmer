import '../../domain/entities/location.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    super.id,
    required super.type,
    super.label,
    required super.stateId,
    required super.districtId,
    required super.pincodeId,
    super.village,
    super.addressLine,
    required super.latitude,
    required super.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (label != null) 'label': label,
      'stateId': stateId,
      'districtId': districtId,
      'pincodeId': pincodeId,
      if (village != null) 'village': village,
      if (addressLine != null) 'addressLine': addressLine,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

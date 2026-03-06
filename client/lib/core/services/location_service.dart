import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String state;
  final String district;
  final String pincode;
  final String? village;
  final String? addressLine;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.state,
    required this.district,
    required this.pincode,
    this.village,
    this.addressLine,
  });
}

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return await _reverseGeocode(position.latitude, position.longitude);
  }

  static Future<LocationResult> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'AgriAI/1.0', // Nominatim requires a user-agent
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final state = address['state'] ?? 'Unknown State';
          final district =
              address['state_district'] ??
              address['county'] ??
              address['city'] ??
              'Unknown District';
          final pincode = address['postcode'] ?? '000000';
          final village =
              address['village'] ?? address['suburb'] ?? address['town'];
          final addressLine = data['display_name'];

          return LocationResult(
            latitude: lat,
            longitude: lng,
            state: state,
            district: district,
            pincode: pincode,
            village: village,
            addressLine: addressLine,
          );
        }
      }
    } catch (e) {
      // Fallback
    }

    return LocationResult(
      latitude: lat,
      longitude: lng,
      state: 'Unknown',
      district: 'Unknown',
      pincode: '000000',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../data/api/labor_api.dart';
import '../providers/labor_profile_provider.dart';

class LaborLocationOnboardingScreen extends ConsumerStatefulWidget {
  const LaborLocationOnboardingScreen({super.key});

  @override
  ConsumerState<LaborLocationOnboardingScreen> createState() => _LaborLocationOnboardingScreenState();
}

class _LaborLocationOnboardingScreenState extends ConsumerState<LaborLocationOnboardingScreen> {
  LatLng? _selectedLocation;
  double _serviceRadius = 10.0;
  bool _isDetecting = false;
  bool _isSaving = false;
  final MapController _mapController = MapController();
  final LaborApi _laborApi = LaborApi();

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<bool> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable GPS location service to auto-detect your location.'),
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Please allow permission and try again.'),
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. Enable it from app settings.'),
          ),
        );
      }
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetecting = true);
    try {
      final hasAccess = await _ensureLocationAccess();
      if (!hasAccess) {
        if (mounted && _selectedLocation == null) {
          setState(() => _selectedLocation = const LatLng(20.5937, 78.9629));
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final newLoc = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLoc;
      });
      // Small delay to ensure map is built before moving
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _mapController.move(newLoc, 13);
      });
    } catch (e) {
      debugPrint('Location detection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not auto-detect location. Please select on map.')),
        );
        // If detection fails, we can fall back to a center-of-country zoom or leave it to manual
        setState(() => _selectedLocation = const LatLng(20.5937, 78.9629)); // Center of India if fail
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  Future<void> _saveOnboarding() async {
    if (_selectedLocation == null) return;
    setState(() => _isSaving = true);
    try {
      await _laborApi.updateProfile({
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'serviceRadiusKm': _serviceRadius.toInt(),
      });
      
      ref.invalidate(laborProfileProvider);
      if (mounted) {
        context.go(RouteNames.laborHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      body: _isDetecting && _selectedLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Detecting your location...'),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? const LatLng(20.5937, 78.9629),
                    initialZoom: _selectedLocation == null ? 4 : 13,
                    onTap: (tapPosition, point) {
                      setState(() => _selectedLocation = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.agriai.farmer',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.error,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

          // ── PREMIUM HEADER ──
          SharedHeader(
            backgroundImage: 'assets/images/service_icons/smart_farming.png',
            title: isHindi ? 'कार्य स्थान' : 'Work Location',
            subtitle: isHindi ? 'अपना कार्य क्षेत्र चुनें' : 'Set Your Work Area',
            showBackButton: false,
          ),

          // ── BOTTOM OVERLAY ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isHindi ? 'कार्य त्रिज्या' : 'Service Radius',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_serviceRadius.toInt()} km',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _serviceRadius,
                    min: 1,
                    max: 50,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _serviceRadius = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDetecting ? null : _detectLocation,
                          icon: _isDetecting 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded),
                          label: Text(isHindi ? 'ऑटो' : 'Auto'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (_isSaving || _selectedLocation == null) ? null : _saveOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(isHindi ? 'जारी रखें' : 'Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

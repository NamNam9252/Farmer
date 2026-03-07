import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/widgets/custom_auth_field.dart';
import '../../../auth/presentation/widgets/custom_auth_button.dart';
import '../../domain/entities/location.dart';
import '../providers/onboarding_provider.dart';
import '../state/onboarding_state.dart';

class LocationSetupScreen extends ConsumerStatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  ConsumerState<LocationSetupScreen> createState() =>
      _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> {
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressLineController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _stateController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    _villageController.dispose();
    _addressLineController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final locationResult = await LocationService.getCurrentLocation();
      setState(() {
        _latitude = locationResult.latitude;
        _longitude = locationResult.longitude;
        _stateController.text = locationResult.state;
        _districtController.text = locationResult.district;
        _pincodeController.text = locationResult.pincode;
        _villageController.text = locationResult.village ?? '';
        _addressLineController.text = locationResult.addressLine ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _submitLocation() {
    final stateStr = _stateController.text.trim();
    final districtStr = _districtController.text.trim();
    final pincodeStr = _pincodeController.text.trim();
    final lat = _latitude;
    final lng = _longitude;

    if (stateStr.isEmpty ||
        districtStr.isEmpty ||
        pincodeStr.isEmpty ||
        lat == null ||
        lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please use "Auto-detect Location" to fill required fields',
          ),
        ),
      );
      return;
    }

    final locationEntity = LocationEntity(
      type: 'HOME',
      stateId: stateStr,
      districtId: districtStr,
      pincodeId: pincodeStr,
      village: _villageController.text.trim(),
      addressLine: _addressLineController.text.trim(),
      latitude: lat,
      longitude: lng,
    );

    ref
        .read(onboardingControllerProvider.notifier)
        .submitLocation(locationEntity);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OnboardingState>(onboardingControllerProvider, (previous, next) {
      if (next is LocationSubmitted) {
        context.push(RouteNames.roleSetup); // Assume this route will exist
      } else if (next is OnboardingError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final state = ref.watch(onboardingControllerProvider);
    final isSubmitting = state is OnboardingLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Set Primary Location',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Where is your primary farm or residence located?',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Auto-detect Button
            ElevatedButton.icon(
              onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
              icon:
                  _isFetchingLocation
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(
                        CupertinoIcons.location_solid,
                        color: Colors.white,
                      ),
              label: Text(
                _isFetchingLocation ? 'Detecting...' : 'Auto-detect Location',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'State *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CustomAuthField(
              controller: _stateController,
              hintText: 'e.g. Maharashtra',
              prefixIcon: CupertinoIcons.map,
            ),

            const SizedBox(height: 16),
            const Text(
              'District *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CustomAuthField(
              controller: _districtController,
              hintText: 'e.g. Pune',
              prefixIcon: CupertinoIcons.map_pin_ellipse,
            ),

            const SizedBox(height: 16),
            const Text(
              'Pincode *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CustomAuthField(
              controller: _pincodeController,
              hintText: 'e.g. 411001',
              prefixIcon: CupertinoIcons.number,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            const Text(
              'Village/Town (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CustomAuthField(
              controller: _villageController,
              hintText: 'Your village or locality',
              prefixIcon: CupertinoIcons.building_2_fill,
            ),

            const SizedBox(height: 32),
            CustomAuthButton(
              text: 'Save & Continue',
              isLoading: isSubmitting,
              onPressed: _submitLocation,
            ),
          ],
        ),
      ),
    );
  }
}

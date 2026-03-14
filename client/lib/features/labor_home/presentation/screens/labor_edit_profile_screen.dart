import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../data/api/labor_api.dart';
import '../../data/constants/labor_skills.dart';
import '../providers/labor_profile_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class LaborEditProfileScreen extends ConsumerStatefulWidget {
  const LaborEditProfileScreen({super.key});

  @override
  ConsumerState<LaborEditProfileScreen> createState() =>
      _LaborEditProfileScreenState();
}

class _LaborEditProfileScreenState
    extends ConsumerState<LaborEditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _skillSearchController = TextEditingController();
  
  double _latitude = 20.5937;
  double _longitude = 78.9629;
  double _serviceRadius = 10;
  bool _isDetecting = false;
  final MapController _mapController = MapController();
  
  final _laborApi = LaborApi();
  final List<String> _selectedSkills = [];
  bool _initialized = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _skillSearchController.dispose();
    _mapController.dispose();
    super.dispose();
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
      if (!hasAccess) return;

      final position = await Geolocator.getCurrentPosition();
      final newLoc = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      _mapController.move(newLoc, 13);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await _laborApi.getProfile();
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final profile = data['data'];
        if (profile['skills'] != null) {
          _selectedSkills.clear();
          for (final skill in profile['skills']) {
            _selectedSkills.add(skill.toString());
          }
        }
        final lat = profile['latitude'];
        final lng = profile['longitude'];
        if (lat != null && lng != null) {
          _latitude = lat.toDouble();
          _longitude = lng.toDouble();
          // Move map contextually
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _mapController.move(LatLng(_latitude, _longitude), 13);
          });
        }
        _serviceRadius = (profile['serviceRadiusKm'] ?? 10).toDouble();
      }
    } catch (_) {
      // Profile may not exist yet — that's OK
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    // Pre-fill user fields
    if (!_initialized && authState is Authenticated) {
      _nameController.text = authState.user.name;
      _phoneController.text = authState.user.phone;
      _emailController.text = authState.user.email ?? '';
      _initialized = true;
    }

    final searchQuery = _skillSearchController.text.toLowerCase();
    final filteredSkills = predefinedSkills.where((skill) {
      if (_selectedSkills.contains(skill.key)) return false;
      if (searchQuery.isEmpty) return true;
      return skill.en.toLowerCase().contains(searchQuery) ||
          skill.hi.contains(searchQuery) ||
          skill.key.toLowerCase().contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      body: SafeArea(
        child: Column(
          children: [
            // ── PREMIUM HEADER ──
            SharedHeader(
              backgroundImage: 'assets/images/service_icons/smart_farming.png',
              title: isHindi ? 'प्रोफ़ाइल संपादित करें' : 'Edit Profile',
              subtitle: isHindi ? 'अपनी जानकारी अपडेट करें' : 'Update your information',
              onLeadingPressed: () => _isDetecting || _isSaving
                  ? null
                  : (Navigator.of(context).canPop()
                      ? context.pop()
                      : context.go(RouteNames.laborHome)),
            ),

            // ── FORM ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00897B),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF00897B),
                                        Color(0xFF26A69A),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00897B)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 42,
                                    color: Colors.white,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF57C00),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFF7F6F3),
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Name
                          _FieldLabel(
                            label: isHindi ? 'पूरा नाम' : 'Full Name',
                          ),
                          const SizedBox(height: 8),
                          _StyledField(
                            controller: _nameController,
                            hint: isHindi
                                ? 'अपना नाम दर्ज करें'
                                : 'Enter your name',
                            icon: CupertinoIcons.person,
                            enabled: true,
                          ),

                          const SizedBox(height: 20),

                          // Phone
                          _FieldLabel(
                            label:
                                isHindi ? 'फ़ोन नंबर' : 'Phone Number',
                          ),
                          const SizedBox(height: 8),
                          _StyledField(
                            controller: _phoneController,
                            hint: isHindi ? 'फ़ोन नंबर' : 'Phone number',
                            icon: CupertinoIcons.phone,
                            keyboardType: TextInputType.phone,
                            enabled: false,
                          ),

                          const SizedBox(height: 20),

                          // Email
                          _FieldLabel(
                            label: isHindi ? 'ईमेल' : 'Email',
                          ),
                          const SizedBox(height: 8),
                          _StyledField(
                            controller: _emailController,
                            hint: isHindi ? 'ईमेल पता' : 'Email address',
                            icon: CupertinoIcons.mail,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 24),

                          // ── SKILLS ── (fuzzy search tags)
                          _FieldLabel(
                            label: isHindi ? 'कौशल' : 'Skills',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isHindi
                                ? 'अपने कौशल खोजें और चुनें'
                                : 'Search and select your skills',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Selected skills chips
                          if (_selectedSkills.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedSkills.map((skillKey) {
                                final skill = predefinedSkills
                                    .where((s) => s.key == skillKey)
                                    .firstOrNull;
                                final label = skill != null
                                    ? (isHindi ? skill.hi : skill.en)
                                    : skillKey;
                                return _SkillChip(
                                  label: label,
                                  isSelected: true,
                                  onTap: () {
                                    setState(() =>
                                        _selectedSkills.remove(skillKey));
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Search field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _skillSearchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: isHindi
                                    ? '🔍 कौशल खोजें...'
                                    : '🔍 Search skills...',
                                hintStyle: TextStyle(
                                  color: AppColors.textHint
                                      .withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF00897B),
                                  size: 20,
                                ),
                                suffixIcon:
                                    _skillSearchController.text.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () {
                                              _skillSearchController.clear();
                                              setState(() {});
                                            },
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: AppColors.textHint,
                                            ),
                                          )
                                        : null,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Available skills
                          if (filteredSkills.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: filteredSkills.take(12).map((skill) {
                                return _SkillChip(
                                  label: isHindi ? skill.hi : skill.en,
                                  isSelected: false,
                                  onTap: () {
                                    setState(() {
                                      _selectedSkills.add(skill.key);
                                      _skillSearchController.clear();
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                          if (filteredSkills.isEmpty &&
                              searchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                isHindi
                                    ? 'कोई कौशल नहीं मिला'
                                    : 'No skills found',
                                style: TextStyle(
                                  color: AppColors.textHint.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // ── LOCATION SELECTOR (MAP) ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _FieldLabel(
                                label: isHindi ? 'कार्य स्थान (मैप)' : 'Work Location (Map)',
                              ),
                              TextButton.icon(
                                onPressed: _isDetecting ? null : _detectLocation,
                                icon: _isDetecting
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.my_location_rounded, size: 16),
                                label: Text(
                                  isHindi ? 'GPS से खोजें' : 'Detect GPS',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00897B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // The Map Widget
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: LatLng(_latitude, _longitude),
                                initialZoom: 13.0,
                                onTap: (tapPos, point) {
                                  setState(() {
                                    _latitude = point.latitude;
                                    _longitude = point.longitude;
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.namnam.farmer',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(_latitude, _longitude),
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.topCenter,
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Coordinates Display
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHindi ? 'अक्षांश (Lat)' : 'Latitude',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                      Text(
                                        _latitude.toStringAsFixed(6),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHindi ? 'देशांतर (Lng)' : 'Longitude',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                      Text(
                                        _longitude.toStringAsFixed(6),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Working Radius Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _FieldLabel(
                                label: isHindi ? 'कार्य त्रिज्या' : 'Working Radius',
                              ),
                              Text(
                                '${_serviceRadius.toInt()} km',
                                style: const TextStyle(
                                  color: Color(0xFF00897B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _serviceRadius,
                            min: 1,
                            max: 100,
                            activeColor: const Color(0xFF00897B),
                            onChanged: (val) => setState(() => _serviceRadius = val),
                          ),
                          Text(
                            isHindi 
                              ? 'आप इस दायरे के भीतर किसानों को दिखाई देंगे' 
                              : 'You will be visible to farmers within this radius',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  _isSaving ? null : () => _saveProfile(isHindi),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00897B),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFF00897B).withValues(alpha: 0.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      isHindi
                                          ? 'प्रोफ़ाइल सहेजें'
                                          : 'Save Profile',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile(bool isHindi) async {
    setState(() => _isSaving = true);
    try {
      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();

      await _laborApi.updateProfile({
        'skills': _selectedSkills,
        'name': newName.isNotEmpty ? newName : null,
        'phone': newPhone.isNotEmpty ? newPhone : null,
        'latitude': _latitude != 0 ? _latitude : null,
        'longitude': _longitude != 0 ? _longitude : null,
        'serviceRadiusKm': _serviceRadius.toInt(),
      });

      if (mounted) {
        // Update user state so the new name appears everywhere
        if (newName.isNotEmpty) {
           ref.read(authControllerProvider.notifier).updateCachedUser(name: newName);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi ? 'प्रोफ़ाइल सहेजा गया!' : 'Profile saved!',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF00897B),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        // Refresh the profile provider so the home screen updates immediately
        ref.invalidate(laborProfileProvider);
        
        // Always route to home page explicitly rather than popping, 
        // to ensure the home page rebuilds with fresh data
        context.go(RouteNames.laborHome);
      }
    } catch (e) {
      debugPrint('❌ Labor profile save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'प्रोफ़ाइल सहेजने में त्रुटि: $e'
                  : 'Error saving profile: $e',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }
}

// ── SKILL CHIP ──
class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00897B)
              : const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00695C)
                : const Color(0xFFB2DFDB),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00897B).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF00695C),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.close_rounded,
                size: 15,
                color: Colors.white70,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── FIELD LABEL ──
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── STYLED TEXT FIELD ──
class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textHint.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled
                ? const Color(0xFF00897B)
                : AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF00897B),
              width: 1.5,
            ),
          ),
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

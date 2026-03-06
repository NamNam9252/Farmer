import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../auth/presentation/widgets/custom_auth_field.dart';
import '../../../auth/presentation/widgets/custom_auth_button.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/onboarding_provider.dart';
import '../state/onboarding_state.dart';

class RoleOnboardingScreen extends ConsumerStatefulWidget {
  const RoleOnboardingScreen({super.key});

  @override
  ConsumerState<RoleOnboardingScreen> createState() =>
      _RoleOnboardingScreenState();
}

class _RoleOnboardingScreenState extends ConsumerState<RoleOnboardingScreen> {
  // Farmer Controllers
  final _landAreaController = TextEditingController();
  final _farmerExpController = TextEditingController();

  // Labor Controllers
  final _skillsController = TextEditingController();
  final _laborExpController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _radiusController = TextEditingController();

  // Expert Controllers
  final _specializationsController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _institutionController = TextEditingController();
  final _expertExpController = TextEditingController();

  @override
  void dispose() {
    _landAreaController.dispose();
    _farmerExpController.dispose();
    _skillsController.dispose();
    _laborExpController.dispose();
    _dailyRateController.dispose();
    _radiusController.dispose();
    _specializationsController.dispose();
    _qualificationsController.dispose();
    _institutionController.dispose();
    _expertExpController.dispose();
    super.dispose();
  }

  void _submitProfile(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        final profile = FarmerProfileEntity(
          totalLandArea: double.tryParse(_landAreaController.text),
          experienceYears: int.tryParse(_farmerExpController.text),
        );
        ref
            .read(onboardingControllerProvider.notifier)
            .submitFarmerProfile(profile);
        break;
      case UserRole.labor:
        final profile = LaborProfileEntity(
          skills:
              _skillsController.text.split(',').map((e) => e.trim()).toList(),
          experienceYears: int.tryParse(_laborExpController.text),
          dailyRate: double.tryParse(_dailyRateController.text),
          serviceRadiusKm: double.tryParse(_radiusController.text),
        );
        ref
            .read(onboardingControllerProvider.notifier)
            .submitLaborProfile(profile);
        break;
      case UserRole.expert:
        final profile = ExpertProfileEntity(
          specializations:
              _specializationsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .toList(),
          qualifications: _qualificationsController.text.trim(),
          institution: _institutionController.text.trim(),
          yearsExperience: int.tryParse(_expertExpController.text),
        );
        ref
            .read(onboardingControllerProvider.notifier)
            .submitExpertProfile(profile);
        break;
      default:
        context.go(RouteNames.disease);
    }
  }

  List<Widget> _buildFarmerForm() {
    return [
      const Text(
        'Total Land Area (Acres)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _landAreaController,
        hintText: 'e.g. 5.5',
        prefixIcon: CupertinoIcons.tree,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      const Text(
        'Farming Experience (Years)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _farmerExpController,
        hintText: 'e.g. 10',
        prefixIcon: CupertinoIcons.time,
        keyboardType: TextInputType.number,
      ),
    ];
  }

  List<Widget> _buildLaborForm() {
    return [
      const Text(
        'Skills (Comma separated)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _skillsController,
        hintText: 'e.g. Harvesting, Tractor Driving',
        prefixIcon: CupertinoIcons.hammer,
      ),
      const SizedBox(height: 16),
      const Text(
        'Experience (Years)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _laborExpController,
        hintText: 'e.g. 3',
        prefixIcon: CupertinoIcons.time,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      const Text(
        'Daily Rate (₹)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _dailyRateController,
        hintText: 'e.g. 400',
        prefixIcon: Icons.currency_rupee,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      const Text(
        'Service Radius (Km)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _radiusController,
        hintText: 'e.g. 15',
        prefixIcon: CupertinoIcons.location,
        keyboardType: TextInputType.number,
      ),
    ];
  }

  List<Widget> _buildExpertForm() {
    return [
      const Text(
        'Specializations (Comma separated)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _specializationsController,
        hintText: 'e.g. Soil Science, Pest Control',
        prefixIcon: CupertinoIcons.star,
      ),
      const SizedBox(height: 16),
      const Text(
        'Qualifications',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _qualificationsController,
        hintText: 'e.g. B.Sc Agriculture',
        prefixIcon: CupertinoIcons.book,
      ),
      const SizedBox(height: 16),
      const Text('Institution', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _institutionController,
        hintText: 'e.g. ICAR',
        prefixIcon: CupertinoIcons.building_2_fill,
      ),
      const SizedBox(height: 16),
      const Text(
        'Experience (Years)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CustomAuthField(
        controller: _expertExpController,
        hintText: 'e.g. 5',
        prefixIcon: CupertinoIcons.time,
        keyboardType: TextInputType.number,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OnboardingState>(onboardingControllerProvider, (previous, next) {
      if (next is ProfileSubmitted) {
        context.go(
          RouteNames.disease,
        ); // Replace with Dashboard Home when ready
      } else if (next is OnboardingError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final authState = ref.watch(authControllerProvider);
    final onboardingState = ref.watch(onboardingControllerProvider);
    final isSubmitting = onboardingState is OnboardingLoading;

    UserRole? role;
    if (authState is Authenticated) {
      role = authState.user.role;
    }

    // Skip onboarding for buyer or admin, or if role is null.
    if (role == null || role == UserRole.buyer || role == UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(RouteNames.disease);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us more about your work as a ${role.name}.',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            if (role == UserRole.farmer) ..._buildFarmerForm(),
            if (role == UserRole.labor) ..._buildLaborForm(),
            if (role == UserRole.expert) ..._buildExpertForm(),

            const SizedBox(height: 32),
            CustomAuthButton(
              text: 'Complete Setup',
              isLoading: isSubmitting,
              onPressed: () => _submitProfile(role!),
            ),
          ],
        ),
      ),
    );
  }
}

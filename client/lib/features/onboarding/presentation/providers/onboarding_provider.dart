import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/api/onboarding_api_client.dart';
import '../../data/repository/onboarding_repository_impl.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repository_contract.dart';
import '../state/onboarding_state.dart';

part 'onboarding_provider.g.dart';

@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  return OnboardingRepositoryImpl(OnboardingApi());
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() {
    return const OnboardingInitial();
  }

  Future<void> submitLocation(LocationEntity location) async {
    state = const OnboardingLoading();
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      await repository.submitLocation(location: location);
      state = const LocationSubmitted();
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  Future<void> submitFarmerProfile(FarmerProfileEntity profile) async {
    state = const OnboardingLoading();
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      await repository.submitFarmerProfile(profile: profile);
      state = const ProfileSubmitted();
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  Future<void> submitLaborProfile(LaborProfileEntity profile) async {
    state = const OnboardingLoading();
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      await repository.submitLaborProfile(profile: profile);
      state = const ProfileSubmitted();
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  Future<void> submitExpertProfile(ExpertProfileEntity profile) async {
    state = const OnboardingLoading();
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      await repository.submitExpertProfile(profile: profile);
      state = const ProfileSubmitted();
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }
}

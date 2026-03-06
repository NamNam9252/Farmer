import 'entities/location.dart';
import 'entities/user_profile.dart';

abstract class OnboardingRepository {
  Future<void> submitLocation({required LocationEntity location});
  Future<void> submitFarmerProfile({required FarmerProfileEntity profile});
  Future<void> submitLaborProfile({required LaborProfileEntity profile});
  Future<void> submitExpertProfile({required ExpertProfileEntity profile});
}

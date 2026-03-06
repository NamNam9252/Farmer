import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repository_contract.dart';
import '../api/onboarding_api_client.dart';
import '../models/location_model.dart';
import '../models/user_profile_model.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingApi _api;

  OnboardingRepositoryImpl(this._api);

  @override
  Future<void> submitLocation({required LocationEntity location}) async {
    try {
      final locationModel = LocationModel(
        type: location.type,
        stateId: location.stateId,
        districtId: location.districtId,
        pincodeId: location.pincodeId,
        latitude: location.latitude,
        longitude: location.longitude,
        label: location.label,
        village: location.village,
        addressLine: location.addressLine,
      );

      final response = await _api.submitLocation(locationModel.toJson());
      _checkSuccess(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> submitFarmerProfile({
    required FarmerProfileEntity profile,
  }) async {
    try {
      final profileModel = FarmerProfileModel(
        totalLandArea: profile.totalLandArea,
        experienceYears: profile.experienceYears,
        aadhaarLast4: profile.aadhaarLast4,
      );

      final response = await _api.submitFarmerProfile(profileModel.toJson());
      _checkSuccess(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> submitLaborProfile({required LaborProfileEntity profile}) async {
    try {
      final profileModel = LaborProfileModel(
        skills: profile.skills,
        experienceYears: profile.experienceYears,
        dailyRate: profile.dailyRate,
        serviceRadiusKm: profile.serviceRadiusKm,
      );

      final response = await _api.submitLaborProfile(profileModel.toJson());
      _checkSuccess(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> submitExpertProfile({
    required ExpertProfileEntity profile,
  }) async {
    try {
      final profileModel = ExpertProfileModel(
        specializations: profile.specializations,
        qualifications: profile.qualifications,
        institution: profile.institution,
        yearsExperience: profile.yearsExperience,
      );

      final response = await _api.submitExpertProfile(profileModel.toJson());
      _checkSuccess(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  void _checkSuccess(Response response) {
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );

    if (!apiResponse.success) {
      throw AppError(message: apiResponse.message, type: AppErrorType.server);
    }
  }

  AppError _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      String message = 'Server Error';
      if (data is Map<String, dynamic> && data['message'] != null) {
        message = data['message'];
      }
      return AppError(
        message: message,
        type: AppErrorType.server,
        originalError: e,
      );
    }
    return AppError(
      message: 'Network connection failed',
      type: AppErrorType.network,
      originalError: e,
    );
  }
}

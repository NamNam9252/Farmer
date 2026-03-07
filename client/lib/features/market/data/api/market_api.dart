import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../domain/entities/market_price.dart';
import '../models/market_price_model.dart';

class MarketApi {
  final ApiClient _client = ApiClient.instance;

  Future<List<String>> getCommodities() async {
    try {
      final response =
          await _client.dio.get(AppConstants.marketCommoditiesEndpoint);

      final apiResponse = ApiResponse<List<String>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          final list = data as List<dynamic>;
          return list.map((e) => e.toString()).toList();
        },
      );

      if (!apiResponse.success) {
        throw AppError(
          message: apiResponse.message,
          type: AppErrorType.server,
        );
      }

      return apiResponse.data ?? <String>[];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppError(
        message: e.toString(),
        type: AppErrorType.unknown,
        originalError: e,
      );
    }
  }

  Future<List<String>> getMarkets() async {
    try {
      final response =
          await _client.dio.get(AppConstants.marketMarketsEndpoint);

      final apiResponse = ApiResponse<List<String>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          final list = data as List<dynamic>;
          return list.map((e) => e.toString()).toList();
        },
      );

      if (!apiResponse.success) {
        throw AppError(
          message: apiResponse.message,
          type: AppErrorType.server,
        );
      }

      return apiResponse.data ?? <String>[];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppError(
        message: e.toString(),
        type: AppErrorType.unknown,
        originalError: e,
      );
    }
  }

  Future<List<MarketPrice>> getPrices({
    required String commodity,
    required String market,
    required String date,
  }) async {
    try {
      final response = await _client.dio.get(
        AppConstants.marketPricesEndpoint,
        queryParameters: <String, dynamic>{
          'commodity': commodity,
          'market': market,
          'date': date,
        },
      );

      final apiResponse = ApiResponse<List<MarketPriceModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          final list = data as List<dynamic>;
          return list
              .map(
                (e) => MarketPriceModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        },
      );

      if (!apiResponse.success) {
        throw AppError(
          message: apiResponse.message,
          type: AppErrorType.server,
        );
      }

      final items = apiResponse.data ?? <MarketPriceModel>[];
      return items.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppError(
        message: e.toString(),
        type: AppErrorType.unknown,
        originalError: e,
      );
    }
  }

  AppError _handleDioError(DioException e) {
    String message = 'Network error';
    AppErrorType type = AppErrorType.network;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message = 'Connection timed out. Please check your internet.';
      type = AppErrorType.network;
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Unable to connect to server. Please check your internet.';
      type = AppErrorType.network;
    } else if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        message = data['message'] as String;
      } else {
        message = 'Server error: ${e.response!.statusCode}';
      }

      if (e.response!.statusCode == 401) {
        type = AppErrorType.unauthorized;
      } else {
        type = AppErrorType.server;
      }
    }

    return AppError(
      message: message,
      type: type,
      originalError: e,
    );
  }
}


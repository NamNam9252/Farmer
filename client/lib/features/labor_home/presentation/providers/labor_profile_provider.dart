import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/labor_api.dart';

final laborProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final laborApi = LaborApi();
    final response = await laborApi.getProfile();
    final data = response.data;
    if (data != null && data['success'] == true && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    return null;
  } catch (e) {
    return null;
  }
});

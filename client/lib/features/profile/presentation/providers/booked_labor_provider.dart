import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/labor_home/data/api/labor_api.dart';

final bookedLaborProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final laborApi = LaborApi();
    final response = await laborApi.getFarmerLabor();
    final data = response.data;
    if (data != null && data['success'] == true && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return [];
  } catch (e) {
    return [];
  }
});

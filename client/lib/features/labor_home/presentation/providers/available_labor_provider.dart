import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/labor_api.dart';

final availableLaborProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final laborApi = LaborApi();
    final response = await laborApi.listAvailable(null); // Passing null for districtId for now
    final data = response.data;
    if (data != null && data['success'] == true && data['data'] != null) {
      return data['data'] as List<dynamic>;
    }
    return [];
  } catch (e) {
    return [];
  }
});

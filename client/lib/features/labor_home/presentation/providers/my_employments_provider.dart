import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/labor_api.dart';

final myEmploymentsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final laborApi = LaborApi();
    final response = await laborApi.getMyEmployments();
    final data = response.data;
    if (data != null && data['success'] == true && data['data'] != null) {
      return data['data'] as List<dynamic>;
    }
    return [];
  } catch (e) {
    return [];
  }
});

import '../../../../core/network/api_client.dart';
import '../models/scheme_model.dart';
import '../../../../core/constants/app_constants.dart';

class SchemesApi {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<SchemeModel>> getSchemes() async {
    try {
      final response = await _apiClient.dio.get('/schemes');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((json) => SchemeModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<SchemeModel?> getSchemeById(String id) async {
    try {
      final response = await _apiClient.dio.get('/schemes/$id');
      if (response.data['success'] == true) {
        return SchemeModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}

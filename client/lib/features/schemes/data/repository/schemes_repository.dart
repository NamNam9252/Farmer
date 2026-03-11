import '../api/schemes_api.dart';
import '../models/scheme_model.dart';

class SchemesRepository {
  final SchemesApi _api = SchemesApi();

  Future<List<SchemeModel>> getSchemes() async {
    return _api.getSchemes();
  }

  Future<SchemeModel?> getSchemeById(String id) async {
    return _api.getSchemeById(id);
  }
}

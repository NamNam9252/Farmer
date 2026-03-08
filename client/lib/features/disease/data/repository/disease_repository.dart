import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/disease_api.dart';
import '../models/disease_report_model.dart';
import '../../domain/disease_repository_contract.dart';

class DiseaseRepository implements IDiseaseRepository {
  final DiseaseApi _api = DiseaseApi();

  static const String _reportsKey = 'disease_reports_local';

  @override
  Future<DiseaseReportModel> analyzeDisease({
    required File imageFile,
    required String cropType,
    String language = 'hi',
  }) async {
    final reportFromServer = await _api.analyzeImage(
      imageFile: imageFile,
      cropType: cropType,
      language: language,
    );
    // Use local path for the report so it's viewable on the device
    // Now copyWith returns DiseaseReportModel properly
    final report = reportFromServer.copyWith(imagePath: imageFile.path);
    await _saveReportLocally(report);
    return report;
  }

  @override
  Future<List<DiseaseReportModel>> getLocalReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_reportsKey) ?? [];
    return jsonList
        .map((s) => DiseaseReportModel.fromJsonString(s))
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveReportLocally(DiseaseReportModel report) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_reportsKey) ?? [];
    existing.insert(0, report.toJsonString());
    // Keep max 50 reports
    if (existing.length > 50) {
      existing.removeRange(50, existing.length);
    }
    await prefs.setStringList(_reportsKey, existing);
  }

  @override
  Future<void> deleteReport(String reportId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_reportsKey) ?? [];
    final updated = existing.where((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['id'] != reportId;
    }).toList();
    await prefs.setStringList(_reportsKey, updated);
  }

  @override
  Future<void> clearAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportsKey);
  }
}

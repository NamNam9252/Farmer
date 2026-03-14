import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/disease_api.dart';
import '../models/disease_report_model.dart';
import '../../domain/disease_repository_contract.dart';
import 'package:client/services/offline_model_service.dart';
import 'package:client/utils/connectivity_service.dart';
import '../../domain/entities/disease_report.dart';

class DiseaseRepository implements IDiseaseRepository {
  final DiseaseApi _api = DiseaseApi();
  final OfflineModelService _offlineModel = OfflineModelService();
  final ConnectivityService _connectivity = ConnectivityService();

  static const String _reportsKey = 'disease_reports_local';

  @override
  Future<DiseaseReportModel> analyzeDisease({
    required File imageFile,
    required String cropType,
    String language = 'hi',
  }) async {
    final bool isOnline = await _connectivity.isConnected();

    if (isOnline) {
      try {
        final reportFromServer = await _api.analyzeImage(
          imageFile: imageFile,
          cropType: cropType,
          language: language,
        );
        final report = reportFromServer.copyWith(
          imagePath: imageFile.path,
          isOffline: false,
        );
        await _saveReportLocally(report);
        return report;
      } catch (e) {
        print('API failed, falling back to offline: $e');
      }
    }

    // Offline logic - specific to crop model
    final offlineResult = await _offlineModel.predict(imageFile, cropType: cropType);
    
    final report = DiseaseReportModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imageFile.path,
      diseaseName: offlineResult['diseaseName'] as String,
      diseaseNameHindi: offlineResult['diseaseNameHindi'] as String,
      cropName: offlineResult['plant'] as String,
      confidenceScore: offlineResult['confidence'] as double,
      severity: _parseSeverity(offlineResult['severity'] as String),
      isHealthy: offlineResult['isHealthy'] as bool,
      description: offlineResult['description'] as String,
      descriptionHindi: offlineResult['descriptionHindi'] as String,
      treatments: [offlineResult['treatment'] as String],
      treatmentsHindi: [offlineResult['treatmentHindi'] as String],
      preventions: [],
      preventionsHindi: [],
      productLinks: [],
      createdAt: DateTime.now(),
      isOffline: true,
    );

    await _saveReportLocally(report);
    return report;
  }

  DiseaseSeverity _parseSeverity(String value) {
    switch (value.toLowerCase()) {
      case 'low': return DiseaseSeverity.low;
      case 'medium': return DiseaseSeverity.medium;
      case 'high': return DiseaseSeverity.high;
      default: return DiseaseSeverity.none;
    }
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

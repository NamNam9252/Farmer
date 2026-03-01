import 'dart:io';
import 'entities/disease_report.dart';

abstract class IDiseaseRepository {
  Future<DiseaseReport> analyzeDisease({
    required File imageFile,
    required String cropType,
    String language = 'hi',
  });

  Future<List<DiseaseReport>> getLocalReports();

  Future<void> deleteReport(String reportId);

  Future<void> clearAllReports();
}

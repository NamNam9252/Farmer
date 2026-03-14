import 'package:flutter/material.dart';

enum DiseaseSeverity { none, low, medium, high }

extension DiseaseSeverityExt on DiseaseSeverity {
  String get label {
    switch (this) {
      case DiseaseSeverity.none:
        return 'None';
      case DiseaseSeverity.low:
        return 'Low';
      case DiseaseSeverity.medium:
        return 'Medium';
      case DiseaseSeverity.high:
        return 'High';
    }
  }

  String get labelHindi {
    switch (this) {
      case DiseaseSeverity.none:
        return 'नहीं';
      case DiseaseSeverity.low:
        return 'कम';
      case DiseaseSeverity.medium:
        return 'मध्यम';
      case DiseaseSeverity.high:
        return 'अधिक';
    }
  }
}

class ProductLink {
  final String name;
  final String nameHindi;
  final String platform;
  final String url;
  final String priceRange;

  const ProductLink({
    required this.name,
    required this.nameHindi,
    required this.platform,
    required this.url,
    required this.priceRange,
  });

  Color get platformColor {
    switch (platform.toLowerCase()) {
      case 'bighaat':
        return const Color(0xFF2E7D32);
      case 'agribegri':
        return const Color(0xFF1565C0);
      case 'krishisevak':
        return const Color(0xFFE65100);
      case 'dehaat':
        return const Color(0xFF6A1B9A);
      case 'agrostar':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF455A64);
    }
  }
}

class DiseaseReport {
  final String id;
  final String imagePath;
  final String diseaseName;
  final String diseaseNameHindi;
  final String cropName;
  final double confidenceScore;
  final DiseaseSeverity severity;
  final bool isHealthy;
  final String description;
  final String descriptionHindi;
  final List<String> treatments;
  final List<String> treatmentsHindi;
  final List<String> preventions;
  final List<String> preventionsHindi;
  final List<ProductLink> productLinks;
  final DateTime createdAt;
  final bool isOffline;

  const DiseaseReport({
    required this.id,
    required this.imagePath,
    required this.diseaseName,
    required this.diseaseNameHindi,
    required this.cropName,
    required this.confidenceScore,
    required this.severity,
    required this.isHealthy,
    required this.description,
    required this.descriptionHindi,
    required this.treatments,
    required this.treatmentsHindi,
    required this.preventions,
    required this.preventionsHindi,
    required this.productLinks,
    required this.createdAt,
    this.isOffline = false,
  });

  DiseaseReport copyWith({
    String? id,
    String? imagePath,
    String? diseaseName,
    String? diseaseNameHindi,
    String? cropName,
    double? confidenceScore,
    DiseaseSeverity? severity,
    bool? isHealthy,
    String? description,
    String? descriptionHindi,
    List<String>? treatments,
    List<String>? treatmentsHindi,
    List<String>? preventions,
    List<String>? preventionsHindi,
    List<ProductLink>? productLinks,
    DateTime? createdAt,
    bool? isOffline,
  }) {
    return DiseaseReport(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      diseaseName: diseaseName ?? this.diseaseName,
      diseaseNameHindi: diseaseNameHindi ?? this.diseaseNameHindi,
      cropName: cropName ?? this.cropName,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      severity: severity ?? this.severity,
      isHealthy: isHealthy ?? this.isHealthy,
      description: description ?? this.description,
      descriptionHindi: descriptionHindi ?? this.descriptionHindi,
      treatments: treatments ?? this.treatments,
      treatmentsHindi: treatmentsHindi ?? this.treatmentsHindi,
      preventions: preventions ?? this.preventions,
      preventionsHindi: preventionsHindi ?? this.preventionsHindi,
      productLinks: productLinks ?? this.productLinks,
      createdAt: createdAt ?? this.createdAt,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

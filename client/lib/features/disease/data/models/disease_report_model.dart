import 'dart:convert';
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

  factory ProductLink.fromJson(Map<String, dynamic> json) => ProductLink(
        name: json['name'] as String? ?? '',
        nameHindi: json['nameHindi'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        url: json['url'] as String? ?? '',
        priceRange: json['priceRange'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'nameHindi': nameHindi,
        'platform': platform,
        'url': url,
        'priceRange': priceRange,
      };

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

class DiseaseReportModel {
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

  const DiseaseReportModel({
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
  });

  factory DiseaseReportModel.fromJson(Map<String, dynamic> json) {
    return DiseaseReportModel(
      id: json['id'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      diseaseName: json['diseaseName'] as String? ?? 'Unknown',
      diseaseNameHindi: json['diseaseNameHindi'] as String? ?? 'अज्ञात',
      cropName: json['cropName'] as String? ?? '',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      severity: _parseSeverity(json['severity'] as String?),
      isHealthy: json['isHealthy'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      descriptionHindi: json['descriptionHindi'] as String? ?? '',
      treatments: List<String>.from(json['treatments'] as List? ?? []),
      treatmentsHindi: List<String>.from(json['treatmentsHindi'] as List? ?? []),
      preventions: List<String>.from(json['preventions'] as List? ?? []),
      preventionsHindi: List<String>.from(json['preventionsHindi'] as List? ?? []),
      productLinks: (json['productLinks'] as List? ?? [])
          .map((e) => ProductLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'diseaseName': diseaseName,
        'diseaseNameHindi': diseaseNameHindi,
        'cropName': cropName,
        'confidenceScore': confidenceScore,
        'severity': severity.name,
        'isHealthy': isHealthy,
        'description': description,
        'descriptionHindi': descriptionHindi,
        'treatments': treatments,
        'treatmentsHindi': treatmentsHindi,
        'preventions': preventions,
        'preventionsHindi': preventionsHindi,
        'productLinks': productLinks.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  static DiseaseReportModel fromJsonString(String jsonString) =>
      DiseaseReportModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  static DiseaseSeverity _parseSeverity(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return DiseaseSeverity.low;
      case 'medium':
        return DiseaseSeverity.medium;
      case 'high':
        return DiseaseSeverity.high;
      default:
        return DiseaseSeverity.none;
    }
  }

  DiseaseReportModel copyWith({
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
  }) {
    return DiseaseReportModel(
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
    );
  }
}

import 'dart:convert';
import '../../domain/entities/disease_report.dart';

class DiseaseReportModel extends DiseaseReport {
  const DiseaseReportModel({
    required super.id,
    required super.imagePath,
    required super.diseaseName,
    required super.diseaseNameHindi,
    required super.cropName,
    required super.confidenceScore,
    required super.severity,
    required super.isHealthy,
    required super.description,
    required super.descriptionHindi,
    required super.treatments,
    required super.treatmentsHindi,
    required super.preventions,
    required super.preventionsHindi,
    required super.productLinks,
    required super.createdAt,
    super.isOffline,
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
          .map((e) => ProductLink(
                name: e['name'] as String? ?? '',
                nameHindi: e['nameHindi'] as String? ?? '',
                platform: e['platform'] as String? ?? '',
                url: e['url'] as String? ?? '',
                priceRange: e['priceRange'] as String? ?? '',
              ))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isOffline: json['isOffline'] as bool? ?? false,
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
        'productLinks': productLinks.map((p) => {
              'name': p.name,
              'nameHindi': p.nameHindi,
              'platform': p.platform,
              'url': p.url,
              'priceRange': p.priceRange,
            }).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isOffline': isOffline,
      };

  String toJsonString() => jsonEncode(toJson());

  @override
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
    bool? isOffline,
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
      isOffline: isOffline ?? this.isOffline,
    );
  }

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
}

enum SchemeCategory {
  subsidy,
  loan,
  insurance,
  training,
  equipment,
  seed,
  irrigation,
  marketSupport,
  other,
}

class SchemeModel {
  final String id;
  final String title;
  final String description;
  final String? eligibility;
  final String? officialLink;
  final String? category;
  final double? maxBenefitAmount;
  final String? benefitUnit;
  final bool isNational;
  final String? stateId;
  final String? districtId;
  final bool isActive;
  final DateTime? deadline;
  final DateTime createdAt;

  SchemeModel({
    required this.id,
    required this.title,
    required this.description,
    this.eligibility,
    this.officialLink,
    this.category,
    this.maxBenefitAmount,
    this.benefitUnit,
    required this.isNational,
    this.stateId,
    this.districtId,
    required this.isActive,
    this.deadline,
    required this.createdAt,
  });

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      eligibility: json['eligibility'],
      officialLink: json['officialLink'],
      category: json['schemeCategory'],
      maxBenefitAmount: json['maxBenefitAmount']?.toDouble(),
      benefitUnit: json['benefitUnit'],
      isNational: json['isNational'] ?? false,
      stateId: json['stateId'],
      districtId: json['districtId'],
      isActive: json['isActive'] ?? true,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

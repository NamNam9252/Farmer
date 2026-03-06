class FarmerProfileEntity {
  final double? totalLandArea;
  final int? experienceYears;
  final String? aadhaarLast4;

  const FarmerProfileEntity({
    this.totalLandArea,
    this.experienceYears,
    this.aadhaarLast4,
  });
}

class LaborProfileEntity {
  final List<String>? skills;
  final int? experienceYears;
  final double? dailyRate;
  final double? serviceRadiusKm;

  const LaborProfileEntity({
    this.skills,
    this.experienceYears,
    this.dailyRate,
    this.serviceRadiusKm,
  });
}

class ExpertProfileEntity {
  final List<String>? specializations;
  final String? qualifications;
  final String? institution;
  final int? yearsExperience;

  const ExpertProfileEntity({
    this.specializations,
    this.qualifications,
    this.institution,
    this.yearsExperience,
  });
}

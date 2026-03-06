import '../../domain/entities/user_profile.dart';

class FarmerProfileModel extends FarmerProfileEntity {
  const FarmerProfileModel({
    super.totalLandArea,
    super.experienceYears,
    super.aadhaarLast4,
  });

  Map<String, dynamic> toJson() {
    return {
      if (totalLandArea != null) 'totalLandArea': totalLandArea,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (aadhaarLast4 != null) 'aadhaarLast4': aadhaarLast4,
    };
  }
}

class LaborProfileModel extends LaborProfileEntity {
  const LaborProfileModel({
    super.skills,
    super.experienceYears,
    super.dailyRate,
    super.serviceRadiusKm,
  });

  Map<String, dynamic> toJson() {
    return {
      if (skills != null) 'skills': skills,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (dailyRate != null) 'dailyRate': dailyRate,
      if (serviceRadiusKm != null) 'serviceRadiusKm': serviceRadiusKm,
    };
  }
}

class ExpertProfileModel extends ExpertProfileEntity {
  const ExpertProfileModel({
    super.specializations,
    super.qualifications,
    super.institution,
    super.yearsExperience,
  });

  Map<String, dynamic> toJson() {
    return {
      if (specializations != null) 'specializations': specializations,
      if (qualifications != null) 'qualifications': qualifications,
      if (institution != null) 'institution': institution,
      if (yearsExperience != null) 'yearsExperience': yearsExperience,
    };
  }
}

class CropRecommendation {
  final int rank;
  final String crop;
  final String cropHindi;
  final String reason;
  final String reasonHindi;
  final String demandLevel;
  final String estimatedCostPerAcre;
  final String estimatedRevenuePerAcre;
  final String estimatedProfitPerAcre;
  final String currentMarketPrice;
  final String bestSeason;
  final String riskLevel;
  final List<String> riskFactors;
  final String growthDuration;

  const CropRecommendation({
    required this.rank,
    required this.crop,
    required this.cropHindi,
    required this.reason,
    required this.reasonHindi,
    required this.demandLevel,
    required this.estimatedCostPerAcre,
    required this.estimatedRevenuePerAcre,
    required this.estimatedProfitPerAcre,
    required this.currentMarketPrice,
    required this.bestSeason,
    required this.riskLevel,
    required this.riskFactors,
    required this.growthDuration,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      rank: json['rank'] as int? ?? 0,
      crop: json['crop'] as String? ?? '',
      cropHindi: json['cropHindi'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      reasonHindi: json['reasonHindi'] as String? ?? '',
      demandLevel: json['demandLevel'] as String? ?? '',
      estimatedCostPerAcre: json['estimatedCostPerAcre'] as String? ?? '',
      estimatedRevenuePerAcre: json['estimatedRevenuePerAcre'] as String? ?? '',
      estimatedProfitPerAcre: json['estimatedProfitPerAcre'] as String? ?? '',
      currentMarketPrice: json['currentMarketPrice'] as String? ?? '',
      bestSeason: json['bestSeason'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? '',
      riskFactors: (json['riskFactors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      growthDuration: json['growthDuration'] as String? ?? '',
    );
  }
}

class CropRecommendationReport {
  final String state;
  final String district;
  final String soilType;
  final String soilTypeHindi;
  final String soilDescription;
  final String soilSource;
  final double temperature;
  final double humidity;
  final double rainProbability;
  final String currentSeason;
  final List<CropRecommendation> recommendations;
  final String summary;
  final String summaryHindi;

  const CropRecommendationReport({
    required this.state,
    required this.district,
    required this.soilType,
    required this.soilTypeHindi,
    required this.soilDescription,
    required this.soilSource,
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.currentSeason,
    required this.recommendations,
    required this.summary,
    required this.summaryHindi,
  });

  factory CropRecommendationReport.fromJson(Map<String, dynamic> json) {
    return CropRecommendationReport(
      state: json['location']?['state'] as String? ?? '',
      district: json['location']?['district'] as String? ?? '',
      soilType: json['soilInfo']?['type'] as String? ?? '',
      soilTypeHindi: json['soilInfo']?['typeHindi'] as String? ?? '',
      soilDescription: json['soilInfo']?['description'] as String? ?? '',
      soilSource: json['soilInfo']?['source'] as String? ?? '',
      temperature: (json['weather']?['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['weather']?['humidity'] as num?)?.toDouble() ?? 0.0,
      rainProbability: (json['weather']?['rainfall_probability'] as num?)?.toDouble() ?? 0.0,
      currentSeason: json['currentSeason'] as String? ?? '',
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => CropRecommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
      summaryHindi: json['summaryHindi'] as String? ?? '',
    );
  }
}

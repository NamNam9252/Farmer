import '../../domain/entities/recommendation.dart';

/// Data model for parsing the backend JSON response.
/// Maps to the domain [Recommendation] entity.
class RecommendationModel {
  final String stage;
  final String action;
  final String reason;
  final String riskLevel;

  const RecommendationModel({
    required this.stage,
    required this.action,
    required this.reason,
    required this.riskLevel,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      stage: json['stage'] as String? ?? '',
      action: json['action'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? 'Low',
    );
  }

  Recommendation toEntity() {
    return Recommendation(
      stage: stage,
      action: action,
      reason: reason,
      riskLevel: riskLevel,
    );
  }
}

/// Pure domain entity for a single advisory recommendation.
/// No Flutter / HTTP imports — portable business model.
class Recommendation {
  final String stage;
  final String action;
  final String reason;
  final String riskLevel; // 'High' | 'Medium' | 'Low'

  const Recommendation({
    required this.stage,
    required this.action,
    required this.reason,
    required this.riskLevel,
  });
}

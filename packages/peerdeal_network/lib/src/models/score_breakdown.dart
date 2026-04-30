class ScoreBreakdown {
  const ScoreBreakdown({
    required this.peerId,
    required this.total,
    required this.reachabilityScore,
    required this.latencyScore,
    required this.stabilityScore,
    required this.anchorSyncScore,
    required this.servingScore,
    required this.penaltyScore,
    this.exclusionReason,
  });

  final String peerId;
  final int total;
  final int reachabilityScore;
  final int latencyScore;
  final int stabilityScore;
  final int anchorSyncScore;
  final int servingScore;
  final int penaltyScore;
  final String? exclusionReason;

  bool get isExcluded => exclusionReason != null;
}

import 'network_confidence.dart';
import 'score_breakdown.dart';

class PrimaryPeerDecision {
  const PrimaryPeerDecision({
    required this.primaryPeerId,
    required this.confidence,
    required this.reason,
    required this.baselineEventIndex,
    required this.expectedAnchorHash,
    required this.requiresTransfer,
    required this.requiresPause,
    required this.rankings,
  });

  final String primaryPeerId;
  final NetworkConfidence confidence;
  final String reason;
  final int baselineEventIndex;
  final String expectedAnchorHash;
  final bool requiresTransfer;
  final bool requiresPause;
  final List<ScoreBreakdown> rankings;
}

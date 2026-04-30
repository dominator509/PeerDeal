import '../models/network_confidence.dart';
import '../models/network_route_class.dart';
import '../models/peer_metric_snapshot.dart';
import '../models/primary_peer_decision.dart';
import '../models/score_breakdown.dart';
import 'confidence_classifier.dart';
import 'primary_peer_election_service.dart';

class DefaultPrimaryPeerElectionService implements PrimaryPeerElectionService {
  const DefaultPrimaryPeerElectionService({
    required this.confidenceClassifier,
  });

  final ConfidenceClassifier confidenceClassifier;

  @override
  PrimaryPeerDecision elect({
    required Iterable<PeerMetricSnapshot> snapshots,
    required int baselineEventIndex,
    required String expectedAnchorHash,
    String? currentPrimaryPeerId,
  }) {
    final items = snapshots.toList(growable: false);
    if (items.isEmpty) {
      return const PrimaryPeerDecision(
        primaryPeerId: 'none',
        confidence: NetworkConfidence.unsafe,
        reason: 'No eligible peers',
        baselineEventIndex: 0,
        expectedAnchorHash: '',
        requiresTransfer: false,
        requiresPause: true,
        rankings: [],
      );
    }

    final rankings = items.map(_score).toList()
      ..sort((a, b) {
        final totalCmp = b.total.compareTo(a.total);
        if (totalCmp != 0) return totalCmp;
        return a.peerId.compareTo(b.peerId);
      });

    final winner = rankings.firstWhere(
      (r) => !r.isExcluded,
      orElse: () => rankings.first,
    );

    final confidence = confidenceClassifier.classify(items);
    final requiresTransfer =
        currentPrimaryPeerId != null && winner.peerId != currentPrimaryPeerId;
    final requiresPause = confidence == NetworkConfidence.recoveryRequired ||
        confidence == NetworkConfidence.unsafe;

    return PrimaryPeerDecision(
      primaryPeerId: winner.peerId,
      confidence: confidence,
      reason: requiresTransfer
          ? 'Better primary peer candidate selected'
          : 'Primary peer remains acceptable',
      baselineEventIndex: baselineEventIndex,
      expectedAnchorHash: expectedAnchorHash,
      requiresTransfer: requiresTransfer,
      requiresPause: requiresPause,
      rankings: rankings,
    );
  }

  ScoreBreakdown _score(PeerMetricSnapshot s) {
    if (!s.anchorAligned) {
      return ScoreBreakdown(
        peerId: s.peerId,
        total: -999,
        reachabilityScore: 0,
        latencyScore: 0,
        stabilityScore: 0,
        anchorSyncScore: 0,
        servingScore: 0,
        penaltyScore: -999,
        exclusionReason: 'Anchor mismatch',
      );
    }

    final reachability = s.reachabilityCount * 10;
    final latency = 300 - s.avgLatencyMs.clamp(0, 300);
    final stability = 100 - (s.disconnectsInWindow * 20);
    final anchor = 100 - (s.eventIndexLag * 20);
    final serving = 100 - s.snapshotServeMs.clamp(0, 100);
    int penalty = 0;

    if (s.backgroundRisk) penalty -= 40;
    if (s.routeClass == NetworkRouteClass.relayFallback) penalty -= 20;
    if (s.ackLagMs > 500) penalty -= 30;

    final total = reachability + latency + stability + anchor + serving + penalty;
    return ScoreBreakdown(
      peerId: s.peerId,
      total: total,
      reachabilityScore: reachability,
      latencyScore: latency,
      stabilityScore: stability,
      anchorSyncScore: anchor,
      servingScore: serving,
      penaltyScore: penalty,
    );
  }
}

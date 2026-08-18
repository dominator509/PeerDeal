import '../models/network_confidence.dart';
import '../models/network_input_limits.dart';
import '../models/network_route_class.dart';
import '../models/peer_metric_snapshot.dart';
import '../models/primary_peer_decision.dart';
import '../models/score_breakdown.dart';
import 'confidence_classifier.dart';
import 'primary_peer_election_service.dart';

class DefaultPrimaryPeerElectionService implements PrimaryPeerElectionService {
  const DefaultPrimaryPeerElectionService({
    required this.confidenceClassifier,
    this.maxSnapshots = NetworkInputLimits.defaultMaxPeerMetrics,
  });

  final ConfidenceClassifier confidenceClassifier;
  final int maxSnapshots;

  @override
  PrimaryPeerDecision elect({
    required Iterable<PeerMetricSnapshot> snapshots,
    required int baselineEventIndex,
    required String expectedAnchorHash,
    String? currentPrimaryPeerId,
  }) {
    _validatePositiveLimit(maxSnapshots, 'maxSnapshots');
    final validCurrentPrimaryPeerId = _validPeerIdOrNull(currentPrimaryPeerId);
    final boundedSnapshots = <PeerMetricSnapshot>[];
    for (final snapshot in snapshots) {
      if (boundedSnapshots.length >= maxSnapshots) {
        return PrimaryPeerDecision(
          primaryPeerId: validCurrentPrimaryPeerId ?? 'none',
          confidence: NetworkConfidence.unsafe,
          reason: 'Peer metric window exceeds the configured limit',
          baselineEventIndex: baselineEventIndex,
          expectedAnchorHash: expectedAnchorHash,
          requiresTransfer: false,
          requiresPause: true,
          rankings: const <ScoreBreakdown>[],
        );
      }
      if (!snapshot.hasValidMeasurements) {
        return PrimaryPeerDecision(
          primaryPeerId: validCurrentPrimaryPeerId ?? 'none',
          confidence: NetworkConfidence.unsafe,
          reason: 'Peer metric measurement is invalid',
          baselineEventIndex: baselineEventIndex,
          expectedAnchorHash: expectedAnchorHash,
          requiresTransfer: false,
          requiresPause: true,
          rankings: const <ScoreBreakdown>[],
        );
      }
      boundedSnapshots.add(snapshot);
    }
    final items = boundedSnapshots
        .where((snapshot) => _isValidPeerId(snapshot.peerId))
        .toList(growable: false);
    if (items.isEmpty) {
      return PrimaryPeerDecision(
        primaryPeerId: 'none',
        confidence: NetworkConfidence.unsafe,
        reason: 'No eligible peers',
        baselineEventIndex: baselineEventIndex,
        expectedAnchorHash: expectedAnchorHash,
        requiresTransfer: false,
        requiresPause: true,
        rankings: const <ScoreBreakdown>[],
      );
    }

    final rankings = items.map(_score).toList()
      ..sort((a, b) {
        final totalCmp = b.total.compareTo(a.total);
        if (totalCmp != 0) return totalCmp;
        return a.peerId.compareTo(b.peerId);
      });

    final confidence = confidenceClassifier.classify(items);
    final winner = _firstEligibleRanking(rankings);
    if (winner == null) {
      return PrimaryPeerDecision(
        primaryPeerId: validCurrentPrimaryPeerId ?? 'none',
        confidence: confidence,
        reason: 'No anchor-aligned peers',
        baselineEventIndex: baselineEventIndex,
        expectedAnchorHash: expectedAnchorHash,
        requiresTransfer: false,
        requiresPause: true,
        rankings: rankings,
      );
    }

    final requiresTransfer =
        validCurrentPrimaryPeerId != null &&
        winner.peerId != validCurrentPrimaryPeerId;
    final requiresPause =
        confidence == NetworkConfidence.recoveryRequired ||
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
    if (s.routeClass.isRelay) penalty -= 20;
    if (s.ackLagMs > 500) penalty -= 30;

    final total =
        reachability + latency + stability + anchor + serving + penalty;
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

  ScoreBreakdown? _firstEligibleRanking(List<ScoreBreakdown> rankings) {
    for (final ranking in rankings) {
      if (!ranking.isExcluded) return ranking;
    }
    return null;
  }

  String? _validPeerIdOrNull(String? peerId) {
    if (peerId == null || !_isValidPeerId(peerId)) return null;
    return peerId;
  }

  bool _isValidPeerId(String peerId) {
    if (peerId.isEmpty || peerId.trim() != peerId) return false;
    return peerId.runes.every((rune) => rune > 0x1f && rune != 0x7f);
  }
}

void _validatePositiveLimit(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
}

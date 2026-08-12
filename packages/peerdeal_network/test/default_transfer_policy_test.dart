import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('builds transfer plan for valid primary handoff', () {
    const policy = DefaultTransferPolicy();

    final plan = policy.buildPlan(
      currentPrimaryPeerId: 'peer_a',
      decision: PrimaryPeerDecision(
        primaryPeerId: 'peer_b',
        confidence: NetworkConfidence.high,
        reason: 'better_peer',
        baselineEventIndex: 42,
        expectedAnchorHash: 'anchor_42',
        requiresTransfer: true,
        requiresPause: false,
        rankings: [],
      ),
    );

    expect(plan, isNotNull);
    expect(plan!.fromPeerId, 'peer_a');
    expect(plan.toPeerId, 'peer_b');
    expect(plan.freezeOperationalEvents, isTrue);
  });

  test('does not build plan from malformed current primary peer id', () {
    const policy = DefaultTransferPolicy();

    final plan = policy.buildPlan(
      currentPrimaryPeerId: ' peer_a',
      decision: PrimaryPeerDecision(
        primaryPeerId: 'peer_b',
        confidence: NetworkConfidence.high,
        reason: 'better_peer',
        baselineEventIndex: 42,
        expectedAnchorHash: 'anchor_42',
        requiresTransfer: true,
        requiresPause: false,
        rankings: [],
      ),
    );

    expect(plan, isNull);
  });

  test('does not build plan to malformed or unresolved target peer id', () {
    const policy = DefaultTransferPolicy();

    for (final targetPeerId in [
      'peer_b\nsecret',
      'peer::b',
      'none',
      'unresolved',
    ]) {
      final plan = policy.buildPlan(
        currentPrimaryPeerId: 'peer_a',
        decision: PrimaryPeerDecision(
          primaryPeerId: targetPeerId,
          confidence: NetworkConfidence.high,
          reason: 'better_peer',
          baselineEventIndex: 42,
          expectedAnchorHash: 'anchor_42',
          requiresTransfer: true,
          requiresPause: false,
          rankings: const [],
        ),
      );

      expect(plan, isNull, reason: targetPeerId);
    }
  });
}

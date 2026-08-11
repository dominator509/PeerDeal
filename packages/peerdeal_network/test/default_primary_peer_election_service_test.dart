import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('fails closed when the peer-metric window exceeds its limit', () {
    const service = DefaultPrimaryPeerElectionService(
      confidenceClassifier: DefaultConfidenceClassifier(),
      maxSnapshots: 1,
    );
    final decision = service.elect(
      snapshots: List<PeerMetricSnapshot>.generate(
        2,
        (index) => PeerMetricSnapshot(
          peerId: 'peer_$index',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 20,
          ackLagMs: 30,
          disconnectsInWindow: 0,
          reachabilityCount: 2,
          eventIndexLag: 0,
          anchorAligned: true,
          snapshotServeMs: 10,
        ),
      ),
      baselineEventIndex: 5,
      expectedAnchorHash: 'anchor_5',
    );

    expect(decision.primaryPeerId, 'none');
    expect(decision.confidence, NetworkConfidence.unsafe);
    expect(decision.requiresPause, isTrue);
    expect(decision.rankings, isEmpty);
    expect(decision.reason, 'Peer metric window exceeds the configured limit');
  });

  test('elects best aligned peer deterministically', () {
    const service = DefaultPrimaryPeerElectionService(
      confidenceClassifier: DefaultConfidenceClassifier(),
    );

    final decision = service.elect(
      snapshots: const [
        PeerMetricSnapshot(
          peerId: 'peer_a',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 100,
          ackLagMs: 150,
          disconnectsInWindow: 0,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: true,
          snapshotServeMs: 25,
        ),
        PeerMetricSnapshot(
          peerId: 'peer_b',
          routeClass: NetworkRouteClass.relayFallback,
          avgLatencyMs: 240,
          ackLagMs: 320,
          disconnectsInWindow: 1,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: true,
          snapshotServeMs: 40,
        ),
      ],
      baselineEventIndex: 99,
      expectedAnchorHash: 'anchor_99',
      currentPrimaryPeerId: 'peer_b',
    );

    expect(decision.primaryPeerId, 'peer_a');
    expect(decision.requiresTransfer, isTrue);
  });

  test('excludes anchor-mismatched peer', () {
    const service = DefaultPrimaryPeerElectionService(
      confidenceClassifier: DefaultConfidenceClassifier(),
    );

    final decision = service.elect(
      snapshots: const [
        PeerMetricSnapshot(
          peerId: 'peer_a',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 20,
          ackLagMs: 30,
          disconnectsInWindow: 0,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: false,
          snapshotServeMs: 10,
        ),
        PeerMetricSnapshot(
          peerId: 'peer_b',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 50,
          ackLagMs: 60,
          disconnectsInWindow: 0,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: true,
          snapshotServeMs: 12,
        ),
      ],
      baselineEventIndex: 12,
      expectedAnchorHash: 'anchor_12',
    );

    expect(decision.primaryPeerId, 'peer_b');
  });

  test('fails closed when all candidate anchors mismatch', () {
    const service = DefaultPrimaryPeerElectionService(
      confidenceClassifier: DefaultConfidenceClassifier(),
    );

    final decision = service.elect(
      snapshots: const [
        PeerMetricSnapshot(
          peerId: 'peer_a',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 20,
          ackLagMs: 30,
          disconnectsInWindow: 0,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: false,
          snapshotServeMs: 10,
        ),
        PeerMetricSnapshot(
          peerId: 'peer_b',
          routeClass: NetworkRouteClass.lanDirect,
          avgLatencyMs: 10,
          ackLagMs: 20,
          disconnectsInWindow: 0,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: false,
          snapshotServeMs: 8,
        ),
      ],
      baselineEventIndex: 12,
      expectedAnchorHash: 'anchor_12',
      currentPrimaryPeerId: 'peer_a',
    );

    expect(decision.primaryPeerId, 'peer_a');
    expect(decision.confidence, NetworkConfidence.recoveryRequired);
    expect(decision.requiresTransfer, isFalse);
    expect(decision.requiresPause, isTrue);
    expect(decision.reason, 'No anchor-aligned peers');
    expect(decision.rankings.every((ranking) => ranking.isExcluded), isTrue);
  });

  test('drops malformed peer metrics before electing primary', () {
    const service = DefaultPrimaryPeerElectionService(
      confidenceClassifier: DefaultConfidenceClassifier(),
    );

    final decision = service.elect(
      snapshots: const [
        PeerMetricSnapshot(
          peerId: ' peer_padded',
          routeClass: NetworkRouteClass.lanDirect,
          avgLatencyMs: 1,
          ackLagMs: 1,
          disconnectsInWindow: 0,
          reachabilityCount: 99,
          eventIndexLag: 0,
          anchorAligned: true,
          snapshotServeMs: 1,
        ),
        PeerMetricSnapshot(
          peerId: 'peer_valid',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 100,
          ackLagMs: 150,
          disconnectsInWindow: 0,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: true,
          snapshotServeMs: 25,
        ),
      ],
      baselineEventIndex: 99,
      expectedAnchorHash: 'anchor_99',
    );

    expect(decision.primaryPeerId, 'peer_valid');
    expect(decision.rankings.map((ranking) => ranking.peerId), ['peer_valid']);
  });

  test('ignores malformed current primary peer id', () {
    const service = DefaultPrimaryPeerElectionService(
      confidenceClassifier: DefaultConfidenceClassifier(),
    );

    final decision = service.elect(
      snapshots: const [
        PeerMetricSnapshot(
          peerId: 'peer_a',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 100,
          ackLagMs: 150,
          disconnectsInWindow: 0,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: true,
          snapshotServeMs: 25,
        ),
      ],
      baselineEventIndex: 99,
      expectedAnchorHash: 'anchor_99',
      currentPrimaryPeerId: 'peer_current\nsecret',
    );

    expect(decision.primaryPeerId, 'peer_a');
    expect(decision.requiresTransfer, isFalse);
  });

  test('fails closed when every peer metric identity is malformed', () {
    const service = DefaultPrimaryPeerElectionService(
      confidenceClassifier: DefaultConfidenceClassifier(),
    );

    final decision = service.elect(
      snapshots: const [
        PeerMetricSnapshot(
          peerId: '',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 20,
          ackLagMs: 30,
          disconnectsInWindow: 0,
          reachabilityCount: 4,
          eventIndexLag: 0,
          anchorAligned: true,
          snapshotServeMs: 10,
        ),
      ],
      baselineEventIndex: 12,
      expectedAnchorHash: 'anchor_12',
      currentPrimaryPeerId: ' peer_padded',
    );

    expect(decision.primaryPeerId, 'none');
    expect(decision.confidence, NetworkConfidence.unsafe);
    expect(decision.requiresPause, isTrue);
    expect(decision.rankings, isEmpty);
    expect(decision.baselineEventIndex, 12);
    expect(decision.expectedAnchorHash, 'anchor_12');
  });
}

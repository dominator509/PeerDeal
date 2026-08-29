import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('operational peer identity rejects reserved route sentinels', () {
    for (final peerId in ['none', 'unresolved', 'peer::reserved']) {
      expect(
        NetworkInputLimits.isOperationalPeerIdentity(peerId),
        isFalse,
        reason: peerId,
      );
    }
    expect(
      NetworkInputLimits.isOperationalPeerIdentity('session::scope'),
      isFalse,
    );
    expect(NetworkInputLimits.isSafePeerIdentity('session::scope'), isTrue);
  });

  test('routing boundaries reject reserved peer sentinels', () async {
    final bootstrap = await const BasicBootstrapCandidateProvider()
        .resolveCandidates(
          BootstrapResolutionRequest(
            sessionId: 'session_1',
            tableId: 'table_1',
            preferLan: true,
            relayAllowed: true,
            peerIds: const ['none', 'unresolved', 'peer::reserved', 'peer_ok'],
          ),
        );
    expect(bootstrap.map((candidate) => candidate.peerId), ['peer_ok']);

    final path = const BasicSessionPathSelector().selectPath(
      candidates: const [
        BootstrapCandidate(
          peerId: 'none',
          routeClass: NetworkRouteClass.lanDirect,
          reachable: true,
          priority: 20,
        ),
        BootstrapCandidate(
          peerId: 'peer_ok',
          routeClass: NetworkRouteClass.remoteDirect,
          reachable: true,
          priority: 10,
        ),
      ],
      preferLan: true,
      relayAllowed: true,
      electedPrimaryPeerId: 'unresolved',
    );
    expect(path.primaryPeerId, 'peer_ok');
    expect(path.routeClass, NetworkRouteClass.remoteDirect);

    final decision =
        const DefaultPrimaryPeerElectionService(
          confidenceClassifier: DefaultConfidenceClassifier(),
        ).elect(
          snapshots: const [
            PeerMetricSnapshot(
              peerId: 'none',
              routeClass: NetworkRouteClass.lanDirect,
              avgLatencyMs: 1,
              ackLagMs: 1,
              disconnectsInWindow: 0,
              reachabilityCount: 4,
              eventIndexLag: 0,
              anchorAligned: true,
            ),
            PeerMetricSnapshot(
              peerId: 'peer_ok',
              routeClass: NetworkRouteClass.remoteDirect,
              avgLatencyMs: 20,
              ackLagMs: 30,
              disconnectsInWindow: 0,
              reachabilityCount: 2,
              eventIndexLag: 0,
              anchorAligned: true,
            ),
          ],
          baselineEventIndex: 1,
          expectedAnchorHash: 'anchor_1',
          currentPrimaryPeerId: 'unresolved',
        );
    expect(decision.primaryPeerId, 'peer_ok');
    expect(decision.rankings.map((ranking) => ranking.peerId), ['peer_ok']);
  });

  test('endpoint parser rejects reserved peer sentinels', () {
    for (final value in [
      'none@host',
      'unresolved@host',
      'peer::reserved@host',
    ]) {
      expect(DiscoveredPeerEndpointParser.parse(value), isNull, reason: value);
    }
  });

  final oversizedPeerId = List<String>.filled(257, 'p').join();

  test('network identity predicate requires bounded strict UTF-8 text', () {
    expect(NetworkInputLimits.isSafePeerIdentity('peer_é'), isTrue);
    expect(NetworkInputLimits.isSafePeerIdentity('peer_\u0085'), isFalse);
    expect(NetworkInputLimits.isSafePeerIdentity(oversizedPeerId), isFalse);
    expect(
      NetworkInputLimits.isSafePeerIdentity(String.fromCharCode(0xd800)),
      isFalse,
    );
  });

  test('bootstrap resolution drops C1 and oversized peer identities', () async {
    final result = await const BasicBootstrapCandidateProvider()
        .resolveCandidates(
          BootstrapResolutionRequest(
            sessionId: 'session_1',
            tableId: 'table_1',
            preferLan: true,
            relayAllowed: true,
            peerIds: <String>['peer_\u0085', oversizedPeerId, 'peer_valid'],
          ),
        );

    expect(result.map((candidate) => candidate.peerId), ['peer_valid']);
  });

  test('path selection ignores unsafe candidates and primary overrides', () {
    final result = const BasicSessionPathSelector().selectPath(
      candidates: <BootstrapCandidate>[
        BootstrapCandidate(
          peerId: 'peer_\u0085',
          routeClass: NetworkRouteClass.lanDirect,
          reachable: true,
          priority: 20,
        ),
        BootstrapCandidate(
          peerId: 'peer_valid',
          routeClass: NetworkRouteClass.remoteDirect,
          reachable: true,
          priority: 10,
        ),
      ],
      preferLan: true,
      relayAllowed: true,
      electedPrimaryPeerId: oversizedPeerId,
    );

    expect(result.primaryPeerId, 'peer_valid');
    expect(result.routeClass, NetworkRouteClass.remoteDirect);
  });

  test('primary election ignores unsafe metric identities', () {
    final decision =
        const DefaultPrimaryPeerElectionService(
          confidenceClassifier: DefaultConfidenceClassifier(),
        ).elect(
          snapshots: <PeerMetricSnapshot>[
            PeerMetricSnapshot(
              peerId: 'peer_\u0085',
              routeClass: NetworkRouteClass.remoteDirect,
              avgLatencyMs: 1,
              ackLagMs: 1,
              disconnectsInWindow: 0,
              reachabilityCount: 99,
              eventIndexLag: 0,
              anchorAligned: true,
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
            ),
          ],
          baselineEventIndex: 1,
          expectedAnchorHash: 'anchor_1',
          currentPrimaryPeerId: oversizedPeerId,
        );

    expect(decision.primaryPeerId, 'peer_valid');
  });

  test('relay and transfer policies reject unsafe operational identities', () {
    const currentPath = SessionPathDescriptor(
      routeClass: NetworkRouteClass.remoteDirect,
      primaryPeerId: 'peer_\u0085',
      usesRelay: false,
      transportAgnostic: true,
      reason: 'current',
    );
    const fallbackPath = SessionPathDescriptor(
      routeClass: NetworkRouteClass.relayFallback,
      primaryPeerId: 'peer_valid',
      usesRelay: true,
      transportAgnostic: true,
      reason: 'fallback',
    );

    final transition = const BasicRelayFallbackService().planTransition(
      currentPath: currentPath,
      fallbackPath: fallbackPath,
      liveHandInProgress: true,
    );
    final transfer = const DefaultTransferPolicy().buildPlan(
      currentPrimaryPeerId: 'peer_valid',
      decision: PrimaryPeerDecision(
        primaryPeerId: oversizedPeerId,
        confidence: NetworkConfidence.high,
        reason: 'unsafe target',
        baselineEventIndex: 1,
        expectedAnchorHash: 'anchor_1',
        requiresTransfer: true,
        requiresPause: false,
        rankings: const <ScoreBreakdown>[],
      ),
    );

    expect(transition.transitionNeeded, isFalse);
    expect(transition.reason, 'invalid_peer_identity');
    expect(transfer, isNull);
  });

  test('endpoint parser rejects C1 and oversized peer identities', () {
    expect(DiscoveredPeerEndpointParser.parse('peer_\u0085@host'), isNull);
    expect(DiscoveredPeerEndpointParser.parse('$oversizedPeerId@host'), isNull);
  });

  test('transport frame validation rejects oversized identities', () {
    final result = const BasicTransportFrameValidator().validate(
      TransportFrame(
        sessionId: oversizedPeerId,
        fromPeerId: 'peer_a',
        toPeerId: 'peer_b',
        sequence: 1,
        payload: <int>[1],
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SESSION_MALFORMED'));
  });
}

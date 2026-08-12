import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('bootstrap request and result own and freeze collections', () {
    final peerIds = <String>['peer_a'];
    final candidates = <BootstrapCandidate>[
      const BootstrapCandidate(
        peerId: 'peer_a',
        routeClass: NetworkRouteClass.lanDirect,
        reachable: true,
        priority: 1,
      ),
    ];
    final request = BootstrapResolutionRequest(
      sessionId: 'session_1',
      tableId: 'table_1',
      preferLan: true,
      relayAllowed: true,
      peerIds: peerIds,
    );
    final result = BootstrapResolutionResult(
      candidates: candidates,
      selectedPath: const SessionPathDescriptor(
        routeClass: NetworkRouteClass.lanDirect,
        primaryPeerId: 'peer_a',
        usesRelay: false,
        transportAgnostic: false,
        reason: 'test',
      ),
      routeChanged: false,
    );

    peerIds.clear();
    candidates.clear();

    expect(request.peerIds, <String>['peer_a']);
    expect(result.candidates, hasLength(1));
    expect(() => request.peerIds.clear(), throwsUnsupportedError);
    expect(() => result.candidates.clear(), throwsUnsupportedError);
  });

  test('LAN discovery owns and freezes endpoint collections', () {
    final peerIds = <String>['peer_a'];
    final interfaces = <String>['wifi'];
    final result = LanDiscoveryResult(
      discoveryEnabled: true,
      foundPeerIds: peerIds,
      interfaceHints: interfaces,
      permissionSatisfied: true,
    );

    peerIds.add('peer_b');
    interfaces.clear();

    expect(result.foundPeerIds, <String>['peer_a']);
    expect(result.interfaceHints, <String>['wifi']);
    expect(() => result.foundPeerIds.add('peer_c'), throwsUnsupportedError);
    expect(() => result.interfaceHints.clear(), throwsUnsupportedError);
  });

  test('transport frame owns and freezes payload bytes', () {
    final payload = <int>[1, 2, 3];
    final frame = TransportFrame(
      sessionId: 'session_1',
      fromPeerId: 'peer_a',
      toPeerId: 'peer_b',
      sequence: 1,
      payload: payload,
    );

    payload.add(4);

    expect(frame.payload, <int>[1, 2, 3]);
    expect(() => frame.payload.add(5), throwsUnsupportedError);
  });

  test('transport results and peer decisions own and freeze collections', () {
    final validationWarnings = <String>['invalid'];
    final sendWarnings = <String>['send_failed'];
    final receiveWarnings = <String>['receive_failed'];
    final rankings = <ScoreBreakdown>[
      const ScoreBreakdown(
        peerId: 'peer_a',
        total: 10,
        reachabilityScore: 2,
        latencyScore: 2,
        stabilityScore: 2,
        anchorSyncScore: 2,
        servingScore: 2,
        penaltyScore: 0,
      ),
    ];
    final validation = TransportFrameValidationResult(
      isValid: false,
      warnings: validationWarnings,
    );
    final send = TransportFrameSendResult(
      sent: false,
      reasonCode: 'ERR_SEND',
      warnings: sendWarnings,
    );
    final receive = TransportFrameReceiveResult(
      accepted: false,
      reasonCode: 'ERR_RECEIVE',
      warnings: receiveWarnings,
    );
    final decision = PrimaryPeerDecision(
      primaryPeerId: 'peer_a',
      confidence: NetworkConfidence.high,
      reason: 'aligned',
      baselineEventIndex: 1,
      expectedAnchorHash: 'anchor_1',
      requiresTransfer: false,
      requiresPause: false,
      rankings: rankings,
    );

    validationWarnings.clear();
    sendWarnings.clear();
    receiveWarnings.clear();
    rankings.clear();

    expect(validation.warnings, <String>['invalid']);
    expect(send.warnings, <String>['send_failed']);
    expect(receive.warnings, <String>['receive_failed']);
    expect(decision.rankings, hasLength(1));
    expect(() => validation.warnings.clear(), throwsUnsupportedError);
    expect(() => send.warnings.clear(), throwsUnsupportedError);
    expect(() => receive.warnings.clear(), throwsUnsupportedError);
    expect(() => decision.rankings.clear(), throwsUnsupportedError);
  });
}

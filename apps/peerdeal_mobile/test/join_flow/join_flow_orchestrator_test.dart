import 'dart:async';

import 'package:peerdeal_mobile/join_flow/fakes.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_adapters.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_orchestrator.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('returns ack required when disclosures are not accepted', () async {
    final sink = RecordingJoinEventSink();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(allAccepted: false),
      roleAuthorizer: FakeRoleAuthorizer(),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(),
      eventSink: sink,
    );

    final result = await orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
      ),
    );

    expect(result.resultCode, 'ACK_REQUIRED');
    expect(result.state, JoinFlowState.ackRequired);
  });

  test('returns joined when all gates pass', () async {
    final sink = RecordingJoinEventSink();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(allAccepted: true),
      roleAuthorizer: FakeRoleAuthorizer(allow: true),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(acceptJoin: true),
      eventSink: sink,
    );

    final result = await orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
      ),
    );

    expect(result.resultCode, 'OK_JOINED');
    expect(result.state, JoinFlowState.joined);
    expect(result.resolvedInvite?.tableId, 'tbl_001');
    expect(result.resolvedInvite?.sessionId, 'sess_001');
    expect(result.sessionContext?.remotePeerId, 'peer_a');
    expect(result.sessionContext?.localSeat, 1);
  });

  test('hands selected endpoint metadata into the session context', () async {
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(allAccepted: true),
      roleAuthorizer: FakeRoleAuthorizer(allow: true),
      bootstrapCoordinator: FakeBootstrapCoordinator(
        selectedCandidate: const BootstrapCandidate(
          peerId: 'peer_a',
          routeClass: NetworkRouteClass.lanDirect,
          reachable: true,
          priority: 1,
          host: '192.168.1.10',
          port: 40442,
        ),
      ),
      governanceCommitter: FakeGovernanceCommitter(acceptJoin: true),
      eventSink: RecordingJoinEventSink(),
    );

    final result = await orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
      ),
    );

    expect(result.sessionContext?.bootstrapCandidate?.peerId, 'peer_a');
    expect(result.sessionContext?.bootstrapCandidate?.host, '192.168.1.10');
    expect(result.sessionContext?.bootstrapCandidate?.port, 40442);
  });

  test('cancels before governance when bootstrap is cancelled', () async {
    final cancellation = Completer<void>();
    final bootstrap = _BlockingCancellableBootstrapCoordinator();
    final committer = _CountingGovernanceCommitter();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(allAccepted: true),
      roleAuthorizer: FakeRoleAuthorizer(allow: true),
      bootstrapCoordinator: bootstrap,
      governanceCommitter: committer,
      eventSink: RecordingJoinEventSink(),
    );

    final resultFuture = orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
      ),
      cancellation: cancellation.future,
    );
    await bootstrap.started.future;
    cancellation.complete();

    final result = await resultFuture;

    expect(result.resultCode, 'ERR_JOIN_FLOW_CANCELLED');
    expect(result.state, JoinFlowState.joinRejected);
    expect(committer.joinCalls, 0);
  });

  test('returns joined when event sink throws', () async {
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(allAccepted: true),
      roleAuthorizer: FakeRoleAuthorizer(allow: true),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(acceptJoin: true),
      eventSink: _ThrowingJoinEventSink(),
    );

    final result = await orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
      ),
    );

    expect(result.resultCode, 'OK_JOINED');
    expect(result.state, JoinFlowState.joined);
  });

  test('rejects unsupported invite protocol before negotiation', () async {
    final sink = RecordingJoinEventSink();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(protocolVersion: '2.0.0'),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(allAccepted: true),
      roleAuthorizer: FakeRoleAuthorizer(allow: true),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(acceptJoin: true),
      eventSink: sink,
    );

    final result = await orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
      ),
    );

    expect(result.resultCode, 'ERR_PROTOCOL_INCOMPATIBLE');
    expect(result.state, JoinFlowState.joinRejected);
    expect(result.diagnostics.single.toJson(), {
      'code': 'ERR_PROTOCOL_INCOMPATIBLE',
      'message': 'Invite protocol version is not supported.',
      'expected': '<redacted>',
      'actual': '<redacted>',
    });
    expect(sink.log, isNot(contains('preflightPending:PREFLIGHT_PENDING')));
    expect(sink.diagnosticsLog.last.single, {
      'code': 'ERR_PROTOCOL_INCOMPATIBLE',
      'message': 'Invite protocol version is not supported.',
      'expected': '<redacted>',
      'actual': '<redacted>',
    });
  });

  test(
    'rejects unsupported rejoin protocol before governance commit',
    () async {
      final sink = RecordingJoinEventSink();
      final orchestrator = JoinFlowOrchestrator(
        inviteResolver: FakeInviteResolver(protocolVersion: '2.0.0'),
        joinNegotiator: FakeJoinNegotiator(),
        disclosureCoordinator: FakeDisclosureCoordinator(),
        roleAuthorizer: FakeRoleAuthorizer(),
        bootstrapCoordinator: FakeBootstrapCoordinator(),
        governanceCommitter: FakeGovernanceCommitter(acceptRejoin: true),
        eventSink: sink,
      );

      final result = await orchestrator.runRejoin(
        const InviteContext(
          inviteCode: 'ABC123',
          requestedRole: RequestedRole.player,
          rejoinToken: 'rj_001',
        ),
      );

      expect(result.resultCode, 'ERR_PROTOCOL_INCOMPATIBLE');
      expect(result.state, JoinFlowState.joinRejected);
      expect(result.diagnostics.single.toJson(), {
        'code': 'ERR_PROTOCOL_INCOMPATIBLE',
        'message': 'Invite protocol version is not supported.',
        'expected': '<redacted>',
        'actual': '<redacted>',
      });
    },
  );

  test('returns rejoined when rejoin commit succeeds', () async {
    final sink = RecordingJoinEventSink();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(),
      roleAuthorizer: FakeRoleAuthorizer(),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(acceptRejoin: true),
      eventSink: sink,
    );

    final result = await orchestrator.runRejoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
        rejoinToken: 'rj_001',
      ),
    );

    expect(result.resultCode, 'OK_REJOINED');
    expect(result.state, JoinFlowState.rejoined);
    expect(result.resolvedInvite?.tableId, 'tbl_001');
    expect(result.resolvedInvite?.sessionId, 'sess_001');
    expect(result.sessionContext?.remotePeerId, 'peer_a');
    expect(result.sessionContext?.localSeat, 1);
  });

  test(
    'does not create a rejoin session context without governance peer',
    () async {
      final orchestrator = JoinFlowOrchestrator(
        inviteResolver: FakeInviteResolver(),
        joinNegotiator: FakeJoinNegotiator(),
        disclosureCoordinator: FakeDisclosureCoordinator(),
        roleAuthorizer: FakeRoleAuthorizer(),
        bootstrapCoordinator: FakeBootstrapCoordinator(),
        governanceCommitter: FakeGovernanceCommitter(rejoinPeerId: null),
        eventSink: RecordingJoinEventSink(),
      );

      final result = await orchestrator.runRejoin(
        const InviteContext(
          inviteCode: 'ABC123',
          requestedRole: RequestedRole.player,
          rejoinToken: 'rj_001',
        ),
      );

      expect(result.status, JoinDecisionStatus.okRejoined);
      expect(result.sessionContext, isNull);
    },
  );

  test('rejects first join when invite resolution throws', () async {
    final sink = RecordingJoinEventSink();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: _ThrowingInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(),
      roleAuthorizer: FakeRoleAuthorizer(),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(),
      eventSink: sink,
    );

    final result = await orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
      ),
    );

    expect(result.state, JoinFlowState.joinRejected);
    expect(result.status, JoinDecisionStatus.negotiationFailed);
    expect(result.resultCode, 'ERR_INVITE_RESOLUTION_FAILED');
    expect(result.diagnostics.single.toJson(), {
      'code': 'ERR_INVITE_RESOLUTION_FAILED',
      'message': 'Invite resolution failed.',
    });
    expect(sink.log.last, 'joinRejected:ERR_INVITE_RESOLUTION_FAILED');
  });

  test('rejects padded invite context before invite resolution', () async {
    final sink = RecordingJoinEventSink();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: _ThrowingInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(),
      roleAuthorizer: FakeRoleAuthorizer(),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(),
      eventSink: sink,
    );

    final result = await orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: ' ABC123',
        requestedRole: RequestedRole.player,
      ),
    );

    expect(result.state, JoinFlowState.joinRejected);
    expect(result.status, JoinDecisionStatus.rejected);
    expect(result.resultCode, 'ERR_INVITE_CONTEXT_INVALID');
    expect(sink.log.last, 'joinRejected:ERR_INVITE_CONTEXT_INVALID');
  });

  test('preserves adapter failure outcome when event sink throws', () async {
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: _ThrowingInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(),
      roleAuthorizer: FakeRoleAuthorizer(),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(),
      eventSink: _ThrowingJoinEventSink(),
    );

    final result = await orchestrator.runFirstJoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
      ),
    );

    expect(result.state, JoinFlowState.joinRejected);
    expect(result.status, JoinDecisionStatus.negotiationFailed);
    expect(result.resultCode, 'ERR_INVITE_RESOLUTION_FAILED');
    expect(result.diagnostics.single.toJson(), {
      'code': 'ERR_INVITE_RESOLUTION_FAILED',
      'message': 'Invite resolution failed.',
    });
  });

  test('rejects rejoin when governance commit throws', () async {
    final sink = RecordingJoinEventSink();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(),
      roleAuthorizer: FakeRoleAuthorizer(),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: _ThrowingRejoinCommitter(),
      eventSink: sink,
    );

    final result = await orchestrator.runRejoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
        rejoinToken: 'rj_001',
      ),
    );

    expect(result.state, JoinFlowState.joinRejected);
    expect(result.status, JoinDecisionStatus.rejoinRejected);
    expect(result.resultCode, 'ERR_REJOIN_COMMIT_FAILED');
    expect(result.diagnostics.single.toJson(), {
      'code': 'ERR_REJOIN_COMMIT_FAILED',
      'message': 'Rejoin commit failed.',
    });
    expect(sink.log.last, 'joinRejected:ERR_REJOIN_COMMIT_FAILED');
  });

  test('rejects padded rejoin token before invite resolution', () async {
    final sink = RecordingJoinEventSink();
    final orchestrator = JoinFlowOrchestrator(
      inviteResolver: _ThrowingInviteResolver(),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(),
      roleAuthorizer: FakeRoleAuthorizer(),
      bootstrapCoordinator: FakeBootstrapCoordinator(),
      governanceCommitter: FakeGovernanceCommitter(acceptRejoin: true),
      eventSink: sink,
    );

    final result = await orchestrator.runRejoin(
      const InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
        rejoinToken: ' rj_001',
      ),
    );

    expect(result.state, JoinFlowState.joinRejected);
    expect(result.status, JoinDecisionStatus.rejoinRejected);
    expect(result.resultCode, 'ERR_REJOIN_TOKEN_REQUIRED');
    expect(sink.log.last, 'joinRejected:ERR_REJOIN_TOKEN_REQUIRED');
  });
}

class _ThrowingInviteResolver implements InviteResolver {
  @override
  Future<ResolvedInvite> resolveInvite(InviteContext context) {
    throw StateError('transport unavailable');
  }
}

class _ThrowingRejoinCommitter extends FakeGovernanceCommitter {
  @override
  Future<GovernanceCommitResult> commitRejoin({
    required ResolvedInvite resolvedInvite,
    required String rejoinToken,
  }) {
    throw StateError('governance unavailable');
  }
}

class _ThrowingJoinEventSink implements JoinEventSink {
  @override
  Future<void> emitState({
    required JoinFlowState state,
    required String resultCode,
    List<ProtocolDiagnostic> diagnostics = const <ProtocolDiagnostic>[],
    String? message,
  }) {
    throw StateError('event sink unavailable');
  }
}

class _BlockingCancellableBootstrapCoordinator
    implements BootstrapCoordinator, CancellableBootstrapCoordinator {
  final Completer<void> started = Completer<void>();

  @override
  Future<BootstrapPlan> buildPlan({
    required ResolvedInvite resolvedInvite,
    required RoleGrant roleGrant,
    Future<void>? cancellation,
  }) async {
    started.complete();
    if (cancellation != null) await cancellation;
    return BootstrapPlan(
      requiresBootstrap: true,
      peerCandidates: <String>['peer_a'],
      relayFallbackAllowed: true,
      selectedPeerId: 'peer_a',
    );
  }
}

class _CountingGovernanceCommitter extends FakeGovernanceCommitter {
  int joinCalls = 0;

  @override
  Future<GovernanceCommitResult> commitJoin({
    required ResolvedInvite resolvedInvite,
    required RoleGrant roleGrant,
    required BootstrapPlan bootstrapPlan,
  }) async {
    joinCalls += 1;
    return super.commitJoin(
      resolvedInvite: resolvedInvite,
      roleGrant: roleGrant,
      bootstrapPlan: bootstrapPlan,
    );
  }
}

import 'package:peerdeal_desktop/join_flow/fakes.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_adapters.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_models.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_orchestrator.dart';
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
  });

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

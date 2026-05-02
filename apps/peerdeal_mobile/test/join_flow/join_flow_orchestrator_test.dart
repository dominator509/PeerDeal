import 'package:peerdeal_mobile/join_flow/fakes.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_orchestrator.dart';
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
}

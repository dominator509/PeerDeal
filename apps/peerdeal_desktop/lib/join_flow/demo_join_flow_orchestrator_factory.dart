import 'fakes.dart';
import 'join_flow_adapters.dart';
import 'join_flow_orchestrator.dart';
import 'join_flow_route.dart';
import 'native_join_bootstrap_coordinator.dart';

class DemoJoinFlowOrchestratorFactory {
  const DemoJoinFlowOrchestratorFactory({
    BootstrapCoordinator? bootstrapCoordinator,
  }) : _bootstrapCoordinator = bootstrapCoordinator;

  final BootstrapCoordinator? _bootstrapCoordinator;

  JoinFlowOrchestrator create(JoinFlowDemoMode mode) {
    return JoinFlowOrchestrator(
      inviteResolver: FakeInviteResolver(
        protocolVersion: mode == JoinFlowDemoMode.unsupportedProtocol
            ? '2.0.0'
            : '1.0.0',
      ),
      joinNegotiator: FakeJoinNegotiator(),
      disclosureCoordinator: FakeDisclosureCoordinator(
        allAccepted: mode != JoinFlowDemoMode.ackRequired,
      ),
      roleAuthorizer: FakeRoleAuthorizer(
        allow: mode != JoinFlowDemoMode.roleDenied,
      ),
      bootstrapCoordinator:
          _bootstrapCoordinator ??
          NativeJoinBootstrapCoordinator.methodChannel(),
      governanceCommitter: FakeGovernanceCommitter(
        acceptJoin: true,
        acceptRejoin: true,
      ),
      eventSink: RecordingJoinEventSink(),
    );
  }
}

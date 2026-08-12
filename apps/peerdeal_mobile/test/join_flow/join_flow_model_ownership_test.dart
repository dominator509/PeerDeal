import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

void main() {
  test('role grants and bootstrap plans own authorization collections', () {
    final permissions = <String>['participate'];
    final peerCandidates = <String>['peer_a'];
    final roleGrant = RoleGrant(
      grantedRole: RequestedRole.player,
      permissions: permissions,
    );
    final plan = BootstrapPlan(
      requiresBootstrap: true,
      peerCandidates: peerCandidates,
      relayFallbackAllowed: true,
    );

    permissions.clear();
    peerCandidates.clear();

    expect(roleGrant.permissions, ['participate']);
    expect(plan.peerCandidates, ['peer_a']);
    expect(() => roleGrant.permissions.add('admin'), throwsUnsupportedError);
    expect(() => plan.peerCandidates.clear(), throwsUnsupportedError);
  });

  test('join outcomes own diagnostics', () {
    final diagnostics = <ProtocolDiagnostic>[
      const ProtocolDiagnostic(code: 'ERR_JOIN', message: 'rejected'),
    ];
    final outcome = JoinFlowOutcome(
      state: JoinFlowState.joinRejected,
      status: JoinDecisionStatus.rejected,
      resultCode: 'ERR_JOIN',
      diagnostics: diagnostics,
    );

    diagnostics.clear();

    expect(outcome.diagnostics, hasLength(1));
    expect(() => outcome.diagnostics.clear(), throwsUnsupportedError);
  });
}

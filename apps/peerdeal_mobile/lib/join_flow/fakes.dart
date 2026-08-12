import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'join_flow_adapters.dart';
import 'join_flow_models.dart';

class RecordingJoinEventSink implements JoinEventSink {
  final List<String> log = <String>[];
  final List<List<Map<String, Object?>>> diagnosticsLog =
      <List<Map<String, Object?>>>[];

  @override
  Future<void> emitState({
    required JoinFlowState state,
    required String resultCode,
    List<ProtocolDiagnostic> diagnostics = const <ProtocolDiagnostic>[],
    String? message,
  }) async {
    log.add('${state.name}:$resultCode');
    diagnosticsLog.add(
      diagnostics.map((diagnostic) => diagnostic.toJson()).toList(),
    );
  }
}

class FakeInviteResolver implements InviteResolver {
  FakeInviteResolver({this.protocolVersion = '1.0.0'});

  final String protocolVersion;

  @override
  Future<ResolvedInvite> resolveInvite(InviteContext context) async {
    return ResolvedInvite(
      inviteId: 'inv_001',
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      modeType: 'open_table',
      protocolVersion: protocolVersion,
      requiresReceiptAck: true,
      requiresRetentionAck: true,
      requiresCaptureAck: true,
    );
  }
}

class FakeJoinNegotiator implements JoinNegotiator {
  FakeJoinNegotiator({this.compatible = true});

  final bool compatible;

  @override
  Future<NegotiationResult> negotiate({
    required InviteContext context,
    required ResolvedInvite resolvedInvite,
  }) async {
    return NegotiationResult(
      compatible: compatible,
      requiresBootstrap: true,
      reasonCode: compatible ? null : 'ERR_PROTOCOL_INCOMPATIBLE',
    );
  }
}

class FakeDisclosureCoordinator implements DisclosureCoordinator {
  FakeDisclosureCoordinator({this.allAccepted = true});

  final bool allAccepted;

  @override
  Future<DisclosureAcks> collectAcks({
    required ResolvedInvite resolvedInvite,
    required RequestedRole requestedRole,
  }) async {
    return DisclosureAcks(
      receiptAck: allAccepted,
      retentionAck: allAccepted,
      captureAck: allAccepted,
      roleScopeAck: allAccepted,
    );
  }
}

class FakeRoleAuthorizer implements RoleAuthorizer {
  FakeRoleAuthorizer({this.allow = true});

  final bool allow;

  @override
  Future<RoleGrant?> authorize({
    required ResolvedInvite resolvedInvite,
    required RequestedRole requestedRole,
  }) async {
    if (!allow) return null;
    return RoleGrant(
      grantedRole: requestedRole,
      permissions: const <String>['participate', 'chat'],
    );
  }
}

class FakeBootstrapCoordinator implements BootstrapCoordinator {
  @override
  Future<BootstrapPlan> buildPlan({
    required ResolvedInvite resolvedInvite,
    required RoleGrant roleGrant,
  }) async {
    return BootstrapPlan(
      requiresBootstrap: true,
      peerCandidates: <String>['peer_a', 'peer_b'],
      relayFallbackAllowed: true,
      selectedPeerId: 'peer_a',
    );
  }
}

class FakeGovernanceCommitter implements GovernanceCommitter {
  FakeGovernanceCommitter({
    this.acceptJoin = true,
    this.acceptRejoin = true,
    this.rejoinPeerId = 'peer_a',
  });

  final bool acceptJoin;
  final bool acceptRejoin;
  final String? rejoinPeerId;

  @override
  Future<GovernanceCommitResult> commitJoin({
    required ResolvedInvite resolvedInvite,
    required RoleGrant roleGrant,
    required BootstrapPlan bootstrapPlan,
  }) async {
    return GovernanceCommitResult(
      accepted: acceptJoin,
      reasonCode: acceptJoin ? null : 'ERR_GOVERNANCE_DENIED',
      assignedSeat: acceptJoin ? 1 : null,
    );
  }

  @override
  Future<GovernanceCommitResult> commitRejoin({
    required ResolvedInvite resolvedInvite,
    required String rejoinToken,
  }) async {
    return GovernanceCommitResult(
      accepted: acceptRejoin,
      reasonCode: acceptRejoin ? null : 'ERR_REJOIN_REJECTED',
      assignedSeat: acceptRejoin ? 1 : null,
      assignedPeerId: acceptRejoin ? rejoinPeerId : null,
    );
  }
}

import 'join_flow_models.dart';

abstract class InviteResolver {
  Future<ResolvedInvite> resolveInvite(InviteContext context);
}

abstract class JoinNegotiator {
  Future<NegotiationResult> negotiate({
    required InviteContext context,
    required ResolvedInvite resolvedInvite,
  });
}

abstract class DisclosureCoordinator {
  Future<DisclosureAcks> collectAcks({
    required ResolvedInvite resolvedInvite,
    required RequestedRole requestedRole,
  });
}

abstract class RoleAuthorizer {
  Future<RoleGrant?> authorize({
    required ResolvedInvite resolvedInvite,
    required RequestedRole requestedRole,
  });
}

abstract class BootstrapCoordinator {
  Future<BootstrapPlan> buildPlan({
    required ResolvedInvite resolvedInvite,
    required RoleGrant roleGrant,
  });
}

abstract class GovernanceCommitter {
  Future<GovernanceCommitResult> commitJoin({
    required ResolvedInvite resolvedInvite,
    required RoleGrant roleGrant,
    required BootstrapPlan bootstrapPlan,
  });

  Future<GovernanceCommitResult> commitRejoin({
    required ResolvedInvite resolvedInvite,
    required String rejoinToken,
  });
}

abstract class JoinEventSink {
  Future<void> emitState({
    required JoinFlowState state,
    required String resultCode,
    String? message,
  });
}

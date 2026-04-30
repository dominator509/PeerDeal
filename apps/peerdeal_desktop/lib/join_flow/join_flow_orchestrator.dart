import 'join_flow_adapters.dart';
import 'join_flow_models.dart';

class JoinFlowOrchestrator {
  JoinFlowOrchestrator({
    required InviteResolver inviteResolver,
    required JoinNegotiator joinNegotiator,
    required DisclosureCoordinator disclosureCoordinator,
    required RoleAuthorizer roleAuthorizer,
    required BootstrapCoordinator bootstrapCoordinator,
    required GovernanceCommitter governanceCommitter,
    required JoinEventSink eventSink,
  })  : _inviteResolver = inviteResolver,
        _joinNegotiator = joinNegotiator,
        _disclosureCoordinator = disclosureCoordinator,
        _roleAuthorizer = roleAuthorizer,
        _bootstrapCoordinator = bootstrapCoordinator,
        _governanceCommitter = governanceCommitter,
        _eventSink = eventSink;

  final InviteResolver _inviteResolver;
  final JoinNegotiator _joinNegotiator;
  final DisclosureCoordinator _disclosureCoordinator;
  final RoleAuthorizer _roleAuthorizer;
  final BootstrapCoordinator _bootstrapCoordinator;
  final GovernanceCommitter _governanceCommitter;
  final JoinEventSink _eventSink;

  Future<JoinFlowOutcome> runFirstJoin(InviteContext context) async {
    await _eventSink.emitState(
      state: JoinFlowState.inviteUnresolved,
      resultCode: 'JOIN_STARTED',
    );

    final resolvedInvite = await _inviteResolver.resolveInvite(context);
    await _eventSink.emitState(
      state: JoinFlowState.inviteResolved,
      resultCode: 'INVITE_RESOLVED',
    );

    await _eventSink.emitState(
      state: JoinFlowState.preflightPending,
      resultCode: 'PREFLIGHT_PENDING',
    );

    final negotiation = await _joinNegotiator.negotiate(
      context: context,
      resolvedInvite: resolvedInvite,
    );

    if (!negotiation.compatible) {
      await _eventSink.emitState(
        state: JoinFlowState.joinRejected,
        resultCode: negotiation.reasonCode ?? 'ERR_NEGOTIATION_FAILED',
      );
      return JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.negotiationFailed,
        resultCode: negotiation.reasonCode ?? 'ERR_NEGOTIATION_FAILED',
      );
    }

    await _eventSink.emitState(
      state: JoinFlowState.negotiating,
      resultCode: 'NEGOTIATION_OK',
    );

    final acks = await _disclosureCoordinator.collectAcks(
      resolvedInvite: resolvedInvite,
      requestedRole: context.requestedRole,
    );

    if (!acks.allRequiredAccepted) {
      await _eventSink.emitState(
        state: JoinFlowState.ackRequired,
        resultCode: 'ACK_REQUIRED',
      );
      return const JoinFlowOutcome(
        state: JoinFlowState.ackRequired,
        status: JoinDecisionStatus.ackRequired,
        resultCode: 'ACK_REQUIRED',
      );
    }

    await _eventSink.emitState(
      state: JoinFlowState.rolePending,
      resultCode: 'DISCLOSURES_ACCEPTED',
    );

    final roleGrant = await _roleAuthorizer.authorize(
      resolvedInvite: resolvedInvite,
      requestedRole: context.requestedRole,
    );

    if (roleGrant == null) {
      await _eventSink.emitState(
        state: JoinFlowState.joinRejected,
        resultCode: 'ERR_ROLE_DENIED',
      );
      return const JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.roleDenied,
        resultCode: 'ERR_ROLE_DENIED',
      );
    }

    final bootstrapPlan = await _bootstrapCoordinator.buildPlan(
      resolvedInvite: resolvedInvite,
      roleGrant: roleGrant,
    );

    await _eventSink.emitState(
      state: JoinFlowState.bootstrapPending,
      resultCode: bootstrapPlan.requiresBootstrap
          ? 'BOOTSTRAP_REQUIRED'
          : 'BOOTSTRAP_SKIPPED',
    );

    final commit = await _governanceCommitter.commitJoin(
      resolvedInvite: resolvedInvite,
      roleGrant: roleGrant,
      bootstrapPlan: bootstrapPlan,
    );

    if (!commit.accepted) {
      await _eventSink.emitState(
        state: JoinFlowState.joinRejected,
        resultCode: commit.reasonCode ?? 'ERR_GOVERNANCE_DENIED',
      );
      return JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.governanceDenied,
        resultCode: commit.reasonCode ?? 'ERR_GOVERNANCE_DENIED',
      );
    }

    await _eventSink.emitState(
      state: JoinFlowState.joined,
      resultCode: 'OK_JOINED',
    );

    return const JoinFlowOutcome(
      state: JoinFlowState.joined,
      status: JoinDecisionStatus.okJoined,
      resultCode: 'OK_JOINED',
    );
  }

  Future<JoinFlowOutcome> runRejoin(InviteContext context) async {
    final rejoinToken = context.rejoinToken;
    if (rejoinToken == null || rejoinToken.isEmpty) {
      await _eventSink.emitState(
        state: JoinFlowState.joinRejected,
        resultCode: 'ERR_REJOIN_TOKEN_REQUIRED',
      );
      return const JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.rejoinRejected,
        resultCode: 'ERR_REJOIN_TOKEN_REQUIRED',
      );
    }

    await _eventSink.emitState(
      state: JoinFlowState.rejoinPending,
      resultCode: 'REJOIN_STARTED',
    );

    final resolvedInvite = await _inviteResolver.resolveInvite(context);
    final commit = await _governanceCommitter.commitRejoin(
      resolvedInvite: resolvedInvite,
      rejoinToken: rejoinToken,
    );

    if (!commit.accepted) {
      await _eventSink.emitState(
        state: JoinFlowState.joinRejected,
        resultCode: commit.reasonCode ?? 'ERR_REJOIN_REJECTED',
      );
      return JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.rejoinRejected,
        resultCode: commit.reasonCode ?? 'ERR_REJOIN_REJECTED',
      );
    }

    await _eventSink.emitState(
      state: JoinFlowState.rejoined,
      resultCode: 'OK_REJOINED',
    );

    return const JoinFlowOutcome(
      state: JoinFlowState.rejoined,
      status: JoinDecisionStatus.okRejoined,
      resultCode: 'OK_REJOINED',
    );
  }
}

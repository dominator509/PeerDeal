import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

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
    DiagnosticsScrubber diagnosticsScrubber =
        const DefaultDiagnosticsScrubber(),
    ProtocolCatalog protocolCatalog = const ProtocolCatalog(),
  }) : _inviteResolver = inviteResolver,
       _joinNegotiator = joinNegotiator,
       _disclosureCoordinator = disclosureCoordinator,
       _roleAuthorizer = roleAuthorizer,
       _bootstrapCoordinator = bootstrapCoordinator,
       _governanceCommitter = governanceCommitter,
       _eventSink = eventSink,
       _diagnosticsScrubber = diagnosticsScrubber,
       _protocolCatalog = protocolCatalog;

  final InviteResolver _inviteResolver;
  final JoinNegotiator _joinNegotiator;
  final DisclosureCoordinator _disclosureCoordinator;
  final RoleAuthorizer _roleAuthorizer;
  final BootstrapCoordinator _bootstrapCoordinator;
  final GovernanceCommitter _governanceCommitter;
  final JoinEventSink _eventSink;
  final DiagnosticsScrubber _diagnosticsScrubber;
  final ProtocolCatalog _protocolCatalog;

  Future<JoinFlowOutcome> runFirstJoin(InviteContext context) async {
    final invalidContext = await _invalidInviteContextOutcome(context);
    if (invalidContext != null) return invalidContext;

    await _safeEmitState(
      state: JoinFlowState.inviteUnresolved,
      resultCode: 'JOIN_STARTED',
    );

    final ResolvedInvite resolvedInvite;
    try {
      resolvedInvite = await _inviteResolver.resolveInvite(context);
    } on Object {
      return _adapterFailureOutcome(
        resultCode: 'ERR_INVITE_RESOLUTION_FAILED',
        status: JoinDecisionStatus.negotiationFailed,
        message: 'Invite resolution failed.',
      );
    }
    await _safeEmitState(
      state: JoinFlowState.inviteResolved,
      resultCode: 'INVITE_RESOLVED',
    );

    if (!_protocolCatalog.supportsProtocolVersion(
      resolvedInvite.protocolVersion,
    )) {
      final diagnostics = _protocolIncompatibleDiagnostics(
        resolvedInvite.protocolVersion,
      );
      await _safeEmitState(
        state: JoinFlowState.joinRejected,
        resultCode: ProtocolResultCodes.errProtocolIncompatible,
        diagnostics: diagnostics,
      );
      return JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.negotiationFailed,
        resultCode: ProtocolResultCodes.errProtocolIncompatible,
        diagnostics: diagnostics,
      );
    }

    await _safeEmitState(
      state: JoinFlowState.preflightPending,
      resultCode: 'PREFLIGHT_PENDING',
    );

    final NegotiationResult negotiation;
    try {
      negotiation = await _joinNegotiator.negotiate(
        context: context,
        resolvedInvite: resolvedInvite,
      );
    } on Object {
      return _adapterFailureOutcome(
        resultCode: 'ERR_NEGOTIATION_FAILED',
        status: JoinDecisionStatus.negotiationFailed,
        message: 'Join negotiation failed.',
      );
    }

    if (!negotiation.compatible) {
      await _safeEmitState(
        state: JoinFlowState.joinRejected,
        resultCode: negotiation.reasonCode ?? 'ERR_NEGOTIATION_FAILED',
      );
      return JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.negotiationFailed,
        resultCode: negotiation.reasonCode ?? 'ERR_NEGOTIATION_FAILED',
      );
    }

    await _safeEmitState(
      state: JoinFlowState.negotiating,
      resultCode: 'NEGOTIATION_OK',
    );

    final DisclosureAcks acks;
    try {
      acks = await _disclosureCoordinator.collectAcks(
        resolvedInvite: resolvedInvite,
        requestedRole: context.requestedRole,
      );
    } on Object {
      return _adapterFailureOutcome(
        resultCode: 'ERR_DISCLOSURE_ACK_FAILED',
        status: JoinDecisionStatus.rejected,
        message: 'Disclosure acknowledgement failed.',
      );
    }

    if (!acks.allRequiredAccepted) {
      await _safeEmitState(
        state: JoinFlowState.ackRequired,
        resultCode: 'ACK_REQUIRED',
      );
      return const JoinFlowOutcome(
        state: JoinFlowState.ackRequired,
        status: JoinDecisionStatus.ackRequired,
        resultCode: 'ACK_REQUIRED',
      );
    }

    await _safeEmitState(
      state: JoinFlowState.rolePending,
      resultCode: 'DISCLOSURES_ACCEPTED',
    );

    final RoleGrant? roleGrant;
    try {
      roleGrant = await _roleAuthorizer.authorize(
        resolvedInvite: resolvedInvite,
        requestedRole: context.requestedRole,
      );
    } on Object {
      return _adapterFailureOutcome(
        resultCode: 'ERR_ROLE_AUTHORIZATION_FAILED',
        status: JoinDecisionStatus.roleDenied,
        message: 'Role authorization failed.',
      );
    }

    if (roleGrant == null) {
      await _safeEmitState(
        state: JoinFlowState.joinRejected,
        resultCode: 'ERR_ROLE_DENIED',
      );
      return const JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.roleDenied,
        resultCode: 'ERR_ROLE_DENIED',
      );
    }

    final BootstrapPlan bootstrapPlan;
    try {
      bootstrapPlan = await _bootstrapCoordinator.buildPlan(
        resolvedInvite: resolvedInvite,
        roleGrant: roleGrant,
      );
    } on Object {
      return _adapterFailureOutcome(
        resultCode: 'ERR_BOOTSTRAP_FAILED',
        status: JoinDecisionStatus.bootstrapRequired,
        message: 'Bootstrap planning failed.',
      );
    }

    await _safeEmitState(
      state: JoinFlowState.bootstrapPending,
      resultCode: bootstrapPlan.requiresBootstrap
          ? 'BOOTSTRAP_REQUIRED'
          : 'BOOTSTRAP_SKIPPED',
    );

    final GovernanceCommitResult commit;
    try {
      commit = await _governanceCommitter.commitJoin(
        resolvedInvite: resolvedInvite,
        roleGrant: roleGrant,
        bootstrapPlan: bootstrapPlan,
      );
    } on Object {
      return _adapterFailureOutcome(
        resultCode: 'ERR_GOVERNANCE_COMMIT_FAILED',
        status: JoinDecisionStatus.governanceDenied,
        message: 'Governance commit failed.',
      );
    }

    if (!commit.accepted) {
      await _safeEmitState(
        state: JoinFlowState.joinRejected,
        resultCode: commit.reasonCode ?? 'ERR_GOVERNANCE_DENIED',
      );
      return JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.governanceDenied,
        resultCode: commit.reasonCode ?? 'ERR_GOVERNANCE_DENIED',
      );
    }

    await _safeEmitState(state: JoinFlowState.joined, resultCode: 'OK_JOINED');

    return JoinFlowOutcome(
      state: JoinFlowState.joined,
      status: JoinDecisionStatus.okJoined,
      resultCode: 'OK_JOINED',
      resolvedInvite: resolvedInvite,
      sessionContext: _sessionContext(
        invite: resolvedInvite,
        bootstrapPlan: bootstrapPlan,
        commit: commit,
      ),
    );
  }

  Future<JoinFlowOutcome> runRejoin(InviteContext context) async {
    final invalidContext = await _invalidInviteContextOutcome(
      context,
      rejoinRequired: true,
    );
    if (invalidContext != null) return invalidContext;

    final rejoinToken = context.rejoinToken;

    await _safeEmitState(
      state: JoinFlowState.rejoinPending,
      resultCode: 'REJOIN_STARTED',
    );

    final ResolvedInvite resolvedInvite;
    try {
      resolvedInvite = await _inviteResolver.resolveInvite(context);
    } on Object {
      return _adapterFailureOutcome(
        resultCode: 'ERR_INVITE_RESOLUTION_FAILED',
        status: JoinDecisionStatus.rejoinRejected,
        message: 'Invite resolution failed.',
      );
    }
    if (!_protocolCatalog.supportsProtocolVersion(
      resolvedInvite.protocolVersion,
    )) {
      final diagnostics = _protocolIncompatibleDiagnostics(
        resolvedInvite.protocolVersion,
      );
      await _safeEmitState(
        state: JoinFlowState.joinRejected,
        resultCode: ProtocolResultCodes.errProtocolIncompatible,
        diagnostics: diagnostics,
      );
      return JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.rejoinRejected,
        resultCode: ProtocolResultCodes.errProtocolIncompatible,
        diagnostics: diagnostics,
      );
    }

    final GovernanceCommitResult commit;
    try {
      commit = await _governanceCommitter.commitRejoin(
        resolvedInvite: resolvedInvite,
        rejoinToken: rejoinToken!,
      );
    } on Object {
      return _adapterFailureOutcome(
        resultCode: 'ERR_REJOIN_COMMIT_FAILED',
        status: JoinDecisionStatus.rejoinRejected,
        message: 'Rejoin commit failed.',
      );
    }

    if (!commit.accepted) {
      await _safeEmitState(
        state: JoinFlowState.joinRejected,
        resultCode: commit.reasonCode ?? 'ERR_REJOIN_REJECTED',
      );
      return JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.rejoinRejected,
        resultCode: commit.reasonCode ?? 'ERR_REJOIN_REJECTED',
      );
    }

    await _safeEmitState(
      state: JoinFlowState.rejoined,
      resultCode: 'OK_REJOINED',
    );

    return JoinFlowOutcome(
      state: JoinFlowState.rejoined,
      status: JoinDecisionStatus.okRejoined,
      resultCode: 'OK_REJOINED',
      resolvedInvite: resolvedInvite,
      sessionContext: _sessionContext(invite: resolvedInvite, commit: commit),
    );
  }

  JoinFlowSessionContext? _sessionContext({
    required ResolvedInvite invite,
    required GovernanceCommitResult commit,
    BootstrapPlan? bootstrapPlan,
  }) {
    final remotePeerId = bootstrapPlan?.selectedPeerId;
    final localSeat = commit.assignedSeat;
    if (remotePeerId == null || !_isExactNonEmpty(remotePeerId)) {
      return null;
    }
    if (localSeat == null || localSeat < 1) return null;
    return JoinFlowSessionContext(
      invite: invite,
      remotePeerId: remotePeerId,
      localSeat: localSeat,
    );
  }

  Future<JoinFlowOutcome?> _invalidInviteContextOutcome(
    InviteContext context, {
    bool rejoinRequired = false,
  }) async {
    if (!_isExactNonEmpty(context.inviteCode)) {
      const resultCode = 'ERR_INVITE_CONTEXT_INVALID';
      const diagnostics = <ProtocolDiagnostic>[
        ProtocolDiagnostic(
          code: resultCode,
          message: 'Invite context is invalid.',
        ),
      ];
      await _safeEmitState(
        state: JoinFlowState.joinRejected,
        resultCode: resultCode,
        diagnostics: diagnostics,
        message: 'Invite context is invalid.',
      );
      return const JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.rejected,
        resultCode: resultCode,
        diagnostics: diagnostics,
        message: 'Invite context is invalid.',
      );
    }

    final rejoinToken = context.rejoinToken;
    if (rejoinRequired &&
        (rejoinToken == null || !_isExactNonEmpty(rejoinToken))) {
      const resultCode = 'ERR_REJOIN_TOKEN_REQUIRED';
      await _safeEmitState(
        state: JoinFlowState.joinRejected,
        resultCode: resultCode,
      );
      return const JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.rejoinRejected,
        resultCode: resultCode,
      );
    }

    return null;
  }

  static bool _isExactNonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed == value;
  }

  List<ProtocolDiagnostic> _protocolIncompatibleDiagnostics(
    String actualProtocolVersion,
  ) {
    return _diagnosticsScrubber.scrubProtocolDiagnostics(<ProtocolDiagnostic>[
      ProtocolDiagnostic(
        code: ProtocolResultCodes.errProtocolIncompatible,
        message: 'Invite protocol version is not supported.',
        expected: currentProtocolVersion.toWire(),
        actual: actualProtocolVersion,
      ),
    ]);
  }

  Future<JoinFlowOutcome> _adapterFailureOutcome({
    required String resultCode,
    required JoinDecisionStatus status,
    required String message,
  }) async {
    final diagnostics = _diagnosticsScrubber.scrubProtocolDiagnostics(
      <ProtocolDiagnostic>[
        ProtocolDiagnostic(code: resultCode, message: message),
      ],
    );
    await _safeEmitState(
      state: JoinFlowState.joinRejected,
      resultCode: resultCode,
      diagnostics: diagnostics,
      message: message,
    );
    return JoinFlowOutcome(
      state: JoinFlowState.joinRejected,
      status: status,
      resultCode: resultCode,
      diagnostics: diagnostics,
      message: message,
    );
  }

  Future<void> _safeEmitState({
    required JoinFlowState state,
    required String resultCode,
    List<ProtocolDiagnostic> diagnostics = const <ProtocolDiagnostic>[],
    String? message,
  }) async {
    try {
      await _eventSink.emitState(
        state: state,
        resultCode: resultCode,
        diagnostics: diagnostics,
        message: message,
      );
    } on Object {
      return;
    }
  }
}

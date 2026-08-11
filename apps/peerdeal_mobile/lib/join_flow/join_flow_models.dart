import 'package:peerdeal_protocol/peerdeal_protocol.dart';

enum JoinFlowState {
  inviteUnresolved,
  inviteResolved,
  preflightPending,
  negotiating,
  ackRequired,
  rolePending,
  bootstrapPending,
  joinReady,
  joined,
  joinRejected,
  rejoinPending,
  rejoined,
}

enum RequestedRole { player, spectator, cohost }

enum JoinDecisionStatus {
  okJoinReady,
  okJoined,
  okRejoined,
  ackRequired,
  negotiationFailed,
  roleDenied,
  governanceDenied,
  bootstrapRequired,
  rejoinRejected,
  rejected,
}

class InviteContext {
  const InviteContext({
    required this.inviteCode,
    required this.requestedRole,
    this.rejoinToken,
  });

  final String inviteCode;
  final RequestedRole requestedRole;
  final String? rejoinToken;
}

class ResolvedInvite {
  const ResolvedInvite({
    required this.inviteId,
    required this.tableId,
    required this.sessionId,
    required this.modeType,
    required this.protocolVersion,
    required this.requiresReceiptAck,
    required this.requiresRetentionAck,
    required this.requiresCaptureAck,
  });

  final String inviteId;
  final String tableId;
  final String sessionId;
  final String modeType;
  final String protocolVersion;
  final bool requiresReceiptAck;
  final bool requiresRetentionAck;
  final bool requiresCaptureAck;
}

/// Runtime facts required to hand an accepted join to a production session.
///
/// Peer selection and seat assignment are not invite fields. They must be
/// supplied by the accepted bootstrap and governance boundaries.
class JoinFlowSessionContext {
  const JoinFlowSessionContext({
    required this.invite,
    required this.remotePeerId,
    required this.localSeat,
  });

  final ResolvedInvite invite;
  final String remotePeerId;
  final int localSeat;
}

class DisclosureAcks {
  const DisclosureAcks({
    required this.receiptAck,
    required this.retentionAck,
    required this.captureAck,
    required this.roleScopeAck,
  });

  final bool receiptAck;
  final bool retentionAck;
  final bool captureAck;
  final bool roleScopeAck;

  bool get allRequiredAccepted =>
      receiptAck && retentionAck && captureAck && roleScopeAck;
}

class NegotiationResult {
  const NegotiationResult({
    required this.compatible,
    required this.requiresBootstrap,
    this.reasonCode,
  });

  final bool compatible;
  final bool requiresBootstrap;
  final String? reasonCode;
}

class RoleGrant {
  const RoleGrant({required this.grantedRole, required this.permissions});

  final RequestedRole grantedRole;
  final List<String> permissions;
}

class BootstrapPlan {
  const BootstrapPlan({
    required this.requiresBootstrap,
    required this.peerCandidates,
    required this.relayFallbackAllowed,
    this.selectedPeerId,
  });

  final bool requiresBootstrap;
  final List<String> peerCandidates;
  final bool relayFallbackAllowed;
  final String? selectedPeerId;
}

class GovernanceCommitResult {
  const GovernanceCommitResult({
    required this.accepted,
    this.reasonCode,
    this.assignedSeat,
    this.assignedPeerId,
  });

  final bool accepted;
  final String? reasonCode;
  final int? assignedSeat;
  final String? assignedPeerId;
}

class JoinFlowOutcome {
  const JoinFlowOutcome({
    required this.state,
    required this.status,
    required this.resultCode,
    this.diagnostics = const <ProtocolDiagnostic>[],
    this.message,
    this.resolvedInvite,
    this.sessionContext,
  });

  final JoinFlowState state;
  final JoinDecisionStatus status;
  final String resultCode;
  final List<ProtocolDiagnostic> diagnostics;
  final String? message;
  final ResolvedInvite? resolvedInvite;
  final JoinFlowSessionContext? sessionContext;
}

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
  });

  final bool requiresBootstrap;
  final List<String> peerCandidates;
  final bool relayFallbackAllowed;
}

class GovernanceCommitResult {
  const GovernanceCommitResult({required this.accepted, this.reasonCode});

  final bool accepted;
  final String? reasonCode;
}

class JoinFlowOutcome {
  const JoinFlowOutcome({
    required this.state,
    required this.status,
    required this.resultCode,
    this.diagnostics = const <ProtocolDiagnostic>[],
    this.message,
  });

  final JoinFlowState state;
  final JoinDecisionStatus status;
  final String resultCode;
  final List<ProtocolDiagnostic> diagnostics;
  final String? message;
}

class PrimaryPeerTransferPlan {
  const PrimaryPeerTransferPlan({
    required this.fromPeerId,
    required this.toPeerId,
    required this.reason,
    required this.requiresPause,
    required this.freezeOperationalEvents,
  });

  final String fromPeerId;
  final String toPeerId;
  final String reason;
  final bool requiresPause;
  final bool freezeOperationalEvents;
}

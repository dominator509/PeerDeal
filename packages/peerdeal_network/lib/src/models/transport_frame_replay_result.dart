enum TransportFrameReplayDisposition {
  accepted,
  duplicate,
  stale,
  scopeLimit,
  invalid,
}

class TransportFrameReplayResult {
  const TransportFrameReplayResult._({
    required this.disposition,
    required this.reasonCode,
  });

  const TransportFrameReplayResult.accepted()
    : this._(
        disposition: TransportFrameReplayDisposition.accepted,
        reasonCode: 'OK_TRANSPORT_FRAME_REPLAY_ALLOWED',
      );

  const TransportFrameReplayResult.rejected({
    required TransportFrameReplayDisposition disposition,
    required String reasonCode,
  }) : this._(disposition: disposition, reasonCode: reasonCode);

  final TransportFrameReplayDisposition disposition;
  final String reasonCode;

  bool get isAccepted =>
      disposition == TransportFrameReplayDisposition.accepted;
  bool get isRejected => !isAccepted;
}

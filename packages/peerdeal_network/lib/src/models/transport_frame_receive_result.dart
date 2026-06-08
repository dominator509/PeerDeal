class TransportFrameReceiveResult {
  const TransportFrameReceiveResult({
    required this.accepted,
    required this.reasonCode,
    this.warnings = const <String>[],
  });

  const TransportFrameReceiveResult.accepted()
    : accepted = true,
      reasonCode = 'OK_TRANSPORT_FRAME_RECEIVED',
      warnings = const <String>[];

  const TransportFrameReceiveResult.rejected({
    required this.reasonCode,
    this.warnings = const <String>[],
  }) : accepted = false;

  final bool accepted;
  final String reasonCode;
  final List<String> warnings;
}

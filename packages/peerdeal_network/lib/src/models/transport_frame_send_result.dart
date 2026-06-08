class TransportFrameSendResult {
  const TransportFrameSendResult({
    required this.sent,
    required this.reasonCode,
    this.warnings = const <String>[],
  });

  const TransportFrameSendResult.sent()
    : sent = true,
      reasonCode = 'OK_TRANSPORT_FRAME_SENT',
      warnings = const <String>[];

  const TransportFrameSendResult.rejected({
    required this.reasonCode,
    this.warnings = const <String>[],
  }) : sent = false;

  final bool sent;
  final String reasonCode;
  final List<String> warnings;
}

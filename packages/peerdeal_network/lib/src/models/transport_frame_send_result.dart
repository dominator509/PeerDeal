class TransportFrameSendResult {
  TransportFrameSendResult({
    required this.sent,
    required this.reasonCode,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  const TransportFrameSendResult.sent()
    : sent = true,
      reasonCode = 'OK_TRANSPORT_FRAME_SENT',
      warnings = const <String>[];

  TransportFrameSendResult.rejected({
    required this.reasonCode,
    List<String> warnings = const <String>[],
  }) : sent = false,
       warnings = List<String>.unmodifiable(warnings);

  final bool sent;
  final String reasonCode;
  final List<String> warnings;
}

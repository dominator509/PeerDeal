class TransportFrameReceiveResult {
  TransportFrameReceiveResult({
    required this.accepted,
    required this.reasonCode,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  const TransportFrameReceiveResult.accepted()
    : accepted = true,
      reasonCode = 'OK_TRANSPORT_FRAME_RECEIVED',
      warnings = const <String>[];

  TransportFrameReceiveResult.rejected({
    required this.reasonCode,
    List<String> warnings = const <String>[],
  }) : accepted = false,
       warnings = List<String>.unmodifiable(warnings);

  final bool accepted;
  final String reasonCode;
  final List<String> warnings;
}

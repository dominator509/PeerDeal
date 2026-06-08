class TransportFrame {
  const TransportFrame({
    required this.sessionId,
    required this.fromPeerId,
    required this.toPeerId,
    required this.sequence,
    required this.payload,
  });

  final String sessionId;
  final String fromPeerId;
  final String toPeerId;
  final int sequence;
  final List<int> payload;
}

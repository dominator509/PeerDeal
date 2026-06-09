class NativeTransportCapability {
  const NativeTransportCapability({
    required this.available,
    required this.sendSupported,
    required this.receiveSupported,
    required this.maxPayloadBytes,
    required this.notes,
    this.warning,
  });

  const NativeTransportCapability.unavailable({this.warning})
    : available = false,
      sendSupported = false,
      receiveSupported = false,
      maxPayloadBytes = 0,
      notes = 'unavailable';

  final bool available;
  final bool sendSupported;
  final bool receiveSupported;
  final int maxPayloadBytes;
  final String notes;
  final String? warning;
}

class NativeTransportFrame {
  const NativeTransportFrame({
    required this.sessionId,
    required this.senderPeerId,
    required this.recipientPeerId,
    required this.sequence,
    required this.payloadBytes,
  });

  final String sessionId;
  final String senderPeerId;
  final String recipientPeerId;
  final int sequence;
  final List<int> payloadBytes;

  bool get isUsable =>
      sessionId.trim().isNotEmpty &&
      sessionId.trim() == sessionId &&
      senderPeerId.trim().isNotEmpty &&
      senderPeerId.trim() == senderPeerId &&
      recipientPeerId.trim().isNotEmpty &&
      recipientPeerId.trim() == recipientPeerId &&
      senderPeerId != recipientPeerId &&
      sequence >= 1 &&
      payloadBytes.isNotEmpty;
}

class NativeTransportSendResult {
  const NativeTransportSendResult({required this.isSuccess, this.warning});

  const NativeTransportSendResult.failure({required this.warning})
    : isSuccess = false;

  final bool isSuccess;
  final String? warning;
}

class NativeTransportReceiveSnapshot {
  const NativeTransportReceiveSnapshot({
    required this.available,
    required this.frames,
    this.warning,
  });

  const NativeTransportReceiveSnapshot.unavailable({this.warning})
    : available = false,
      frames = const <NativeTransportFrame>[];

  final bool available;
  final List<NativeTransportFrame> frames;
  final String? warning;
}

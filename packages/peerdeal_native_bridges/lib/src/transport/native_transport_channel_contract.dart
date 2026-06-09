import 'native_transport_bridge_models.dart';

class NativeTransportChannelContract {
  const NativeTransportChannelContract._();

  static const channelName = 'peerdeal/native_bridges/transport';
  static const getCapabilityMethod = 'getCapability';
  static const sendFrameMethod = 'sendFrame';
  static const receiveFramesMethod = 'receiveFrames';

  static NativeTransportCapability decodeCapability(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const NativeTransportCapability.unavailable(
        warning: 'Native transport capability is unavailable.',
      );
    }

    return NativeTransportCapability(
      available: _boolValue(payload['available']),
      sendSupported: _boolValue(payload['sendSupported']),
      receiveSupported: _boolValue(payload['receiveSupported']),
      maxPayloadBytes: _nonNegativeIntValue(payload['maxPayloadBytes']),
      notes: _stringValue(payload['notes']) ?? 'unavailable',
      warning: _stringValue(payload['warning']),
    );
  }

  static Map<String, Object?> encodeFrame(NativeTransportFrame frame) {
    return <String, Object?>{
      'sessionId': frame.sessionId,
      'senderPeerId': frame.senderPeerId,
      'recipientPeerId': frame.recipientPeerId,
      'sequence': frame.sequence,
      'payloadBytes': frame.payloadBytes,
    };
  }

  static NativeTransportSendResult decodeSendResult(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const NativeTransportSendResult.failure(
        warning: 'Native transport send result is unavailable.',
      );
    }

    return NativeTransportSendResult(
      isSuccess: _boolValue(payload['success']),
      warning:
          _stringValue(payload['warning']) ??
          (_boolValue(payload['success'])
              ? null
              : 'Native transport send failed.'),
    );
  }

  static NativeTransportReceiveSnapshot decodeReceiveSnapshot(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const NativeTransportReceiveSnapshot.unavailable(
        warning: 'Native transport receive snapshot is unavailable.',
      );
    }

    final frames = _listValue(payload['frames'])
        .map(_decodeFrame)
        .whereType<NativeTransportFrame>()
        .toList(growable: false);

    return NativeTransportReceiveSnapshot(
      available: _boolValue(payload['available']),
      frames: frames,
      warning: _stringValue(payload['warning']),
    );
  }

  static NativeTransportFrame? _decodeFrame(Object? value) {
    if (value is! Map) return null;
    final json = <String, Object?>{
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };

    final payloadBytes = _byteListValue(json['payloadBytes']);
    final frame = NativeTransportFrame(
      sessionId: _stringValue(json['sessionId']) ?? '',
      senderPeerId: _stringValue(json['senderPeerId']) ?? '',
      recipientPeerId: _stringValue(json['recipientPeerId']) ?? '',
      sequence: _positiveIntValue(json['sequence']),
      payloadBytes: payloadBytes,
    );
    return frame.isUsable ? frame : null;
  }

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static int _nonNegativeIntValue(Object? value) =>
      value is int && value >= 0 ? value : 0;

  static int _positiveIntValue(Object? value) =>
      value is int && value >= 1 ? value : 0;

  static String? _stringValue(Object? value) => value is String ? value : null;

  static List<dynamic> _listValue(Object? value) =>
      value is List<dynamic> ? value : const <dynamic>[];

  static List<int> _byteListValue(Object? value) {
    final values = _listValue(value);
    final bytes = <int>[];
    for (final value in values) {
      if (value is! int || value < 0 || value > 255) {
        return const <int>[];
      }
      bytes.add(value);
    }
    return bytes;
  }
}

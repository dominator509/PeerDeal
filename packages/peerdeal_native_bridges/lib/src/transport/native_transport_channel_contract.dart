import 'native_transport_bridge_models.dart';
import '../native_bridge_payload_limits.dart';

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
      maxPayloadBytes: _payloadLimitValue(payload['maxPayloadBytes']),
      notes:
          _boundedStringValue(
            payload['notes'],
            NativeBridgePayloadLimits.maxDiagnosticBytes,
          ) ??
          'unavailable',
      warning: _boundedStringValue(
        payload['warning'],
        NativeBridgePayloadLimits.maxDiagnosticBytes,
      ),
    );
  }

  static Map<String, Object?> encodeFrame(NativeTransportFrame frame) {
    if (!frame.isUsable) return const <String, Object?>{};
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
          _boundedStringValue(
            payload['warning'],
            NativeBridgePayloadLimits.maxDiagnosticBytes,
          ) ??
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

    final framePayloads = payload['frames'];
    if (framePayloads is! List<dynamic> ||
        framePayloads.length > NativeBridgePayloadLimits.maxTransportFrames) {
      return const NativeTransportReceiveSnapshot.unavailable(
        warning: 'Native transport receive snapshot is unavailable.',
      );
    }

    final frames = framePayloads
        .map(_decodeFrame)
        .whereType<NativeTransportFrame>()
        .toList(growable: false);

    return NativeTransportReceiveSnapshot(
      available: _boolValue(payload['available']),
      frames: frames,
      warning: _boundedStringValue(
        payload['warning'],
        NativeBridgePayloadLimits.maxDiagnosticBytes,
      ),
    );
  }

  static NativeTransportFrame? _decodeFrame(Object? value) {
    if (value is! Map<Object?, Object?>) return null;

    final payloadBytes = _byteListValue(value['payloadBytes']);
    final frame = NativeTransportFrame(
      sessionId:
          _boundedStringValue(
            value['sessionId'],
            NativeBridgePayloadLimits.maxTransportIdentityBytes,
          ) ??
          '',
      senderPeerId:
          _boundedStringValue(
            value['senderPeerId'],
            NativeBridgePayloadLimits.maxTransportIdentityBytes,
          ) ??
          '',
      recipientPeerId:
          _boundedStringValue(
            value['recipientPeerId'],
            NativeBridgePayloadLimits.maxTransportIdentityBytes,
          ) ??
          '',
      sequence: _positiveIntValue(value['sequence']),
      payloadBytes: payloadBytes,
    );
    return frame.isUsable ? frame : null;
  }

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static int _payloadLimitValue(Object? value) =>
      value is int &&
          value >= 1 &&
          value <= NativeBridgePayloadLimits.maxTransportPayloadBytes
      ? value
      : 0;

  static int _positiveIntValue(Object? value) =>
      value is int && value >= 1 ? value : 0;

  static String? _boundedStringValue(Object? value, int maxBytes) {
    if (value is! String ||
        !NativeBridgePayloadLimits.isWithinUtf8Limit(value, maxBytes)) {
      return null;
    }
    return value;
  }

  static List<int> _byteListValue(Object? value) {
    if (value is! List<dynamic> ||
        value.length > NativeBridgePayloadLimits.maxTransportPayloadBytes) {
      return const <int>[];
    }
    final values = value;
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

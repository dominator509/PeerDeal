import '../contracts/transport_frame_validator.dart';
import '../models/network_input_limits.dart';
import '../models/transport_frame.dart';
import '../models/transport_frame_validation_result.dart';

class BasicTransportFrameValidator implements TransportFrameValidator {
  const BasicTransportFrameValidator({this.maxPayloadBytes = 64 * 1024});

  final int maxPayloadBytes;

  @override
  TransportFrameValidationResult validate(TransportFrame frame) {
    if (maxPayloadBytes < 1) {
      throw ArgumentError.value(
        maxPayloadBytes,
        'maxPayloadBytes',
        'Transport payload limit must be positive.',
      );
    }

    final warnings = <String>[];

    if (frame.sessionId.trim().isEmpty) {
      warnings.add('ERR_TRANSPORT_FRAME_SESSION_REQUIRED');
    } else if (!_isSafeIdentity(frame.sessionId)) {
      warnings.add('ERR_TRANSPORT_FRAME_SESSION_MALFORMED');
    }
    if (frame.fromPeerId.trim().isEmpty) {
      warnings.add('ERR_TRANSPORT_FRAME_SENDER_REQUIRED');
    } else if (!_isOperationalPeerId(frame.fromPeerId)) {
      warnings.add('ERR_TRANSPORT_FRAME_SENDER_MALFORMED');
    }
    if (frame.toPeerId.trim().isEmpty) {
      warnings.add('ERR_TRANSPORT_FRAME_RECIPIENT_REQUIRED');
    } else if (!_isOperationalPeerId(frame.toPeerId)) {
      warnings.add('ERR_TRANSPORT_FRAME_RECIPIENT_MALFORMED');
    }
    if (frame.fromPeerId == frame.toPeerId) {
      warnings.add('ERR_TRANSPORT_FRAME_SELF_SEND');
    }
    if (frame.sequence < 1) {
      warnings.add('ERR_TRANSPORT_FRAME_SEQUENCE_INVALID');
    }
    if (frame.payload.isEmpty) {
      warnings.add('ERR_TRANSPORT_FRAME_PAYLOAD_REQUIRED');
    }
    if (frame.payload.length > maxPayloadBytes) {
      warnings.add('ERR_TRANSPORT_FRAME_PAYLOAD_TOO_LARGE');
    }
    if (frame.payload.any((byte) => byte < 0 || byte > 255)) {
      warnings.add('ERR_TRANSPORT_FRAME_PAYLOAD_BYTE_INVALID');
    }

    if (warnings.isEmpty) {
      return const TransportFrameValidationResult.valid();
    }

    return TransportFrameValidationResult(
      isValid: false,
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  bool _isSafeIdentity(String value) {
    return NetworkInputLimits.isSafePeerIdentity(value);
  }

  bool _isOperationalPeerId(String value) {
    return NetworkInputLimits.isOperationalPeerIdentity(value);
  }
}

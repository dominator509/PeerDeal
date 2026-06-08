import '../contracts/transport_frame_validator.dart';
import '../models/transport_frame.dart';
import '../models/transport_frame_validation_result.dart';

class BasicTransportFrameValidator implements TransportFrameValidator {
  const BasicTransportFrameValidator({this.maxPayloadBytes = 64 * 1024});

  final int maxPayloadBytes;

  @override
  TransportFrameValidationResult validate(TransportFrame frame) {
    final warnings = <String>[];

    if (frame.sessionId.trim().isEmpty) {
      warnings.add('ERR_TRANSPORT_FRAME_SESSION_REQUIRED');
    }
    if (frame.fromPeerId.trim().isEmpty) {
      warnings.add('ERR_TRANSPORT_FRAME_SENDER_REQUIRED');
    }
    if (frame.toPeerId.trim().isEmpty) {
      warnings.add('ERR_TRANSPORT_FRAME_RECIPIENT_REQUIRED');
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

    if (warnings.isEmpty) {
      return const TransportFrameValidationResult.valid();
    }

    return TransportFrameValidationResult(
      isValid: false,
      warnings: List<String>.unmodifiable(warnings),
    );
  }
}

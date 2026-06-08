import '../models/transport_frame.dart';
import '../models/transport_frame_validation_result.dart';

abstract interface class TransportFrameValidator {
  TransportFrameValidationResult validate(TransportFrame frame);
}

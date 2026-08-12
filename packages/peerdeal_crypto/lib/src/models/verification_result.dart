import 'verification_layer_result.dart';
import 'verification_payload.dart';
import 'verification_reason_code.dart';
import 'verification_state.dart';
import 'verification_summary.dart';

class VerificationResult {
  VerificationResult({
    required this.state,
    required this.reasonCode,
    required List<VerificationLayerResult> layers,
    required this.summary,
    required this.payload,
  }) : layers = List<VerificationLayerResult>.unmodifiable(layers);

  final VerificationState state;
  final VerificationReasonCode reasonCode;
  final List<VerificationLayerResult> layers;
  final VerificationSummary summary;
  final VerificationPayload payload;
}

import 'verification_layer_result.dart';
import 'verification_payload.dart';
import 'verification_reason_code.dart';
import 'verification_state.dart';
import 'verification_summary.dart';

class VerificationResult {
  const VerificationResult({
    required this.state,
    required this.reasonCode,
    required this.layers,
    required this.summary,
    required this.payload,
  });

  final VerificationState state;
  final VerificationReasonCode reasonCode;
  final List<VerificationLayerResult> layers;
  final VerificationSummary summary;
  final VerificationPayload payload;
}

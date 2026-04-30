import '../models/verification_request.dart';
import '../models/verification_result.dart';

abstract interface class VerificationEngine {
  VerificationResult verify(VerificationRequest request);
}

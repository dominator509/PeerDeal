import '../models/conflict_detection_result.dart';
import '../models/recovery_request.dart';

abstract interface class ConflictDetector {
  ConflictDetectionResult detect(RecoveryRequest request);
}

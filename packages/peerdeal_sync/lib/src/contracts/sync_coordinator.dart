import '../models/recovery_request.dart';
import '../models/recovery_result.dart';

abstract interface class SyncCoordinator<TState> {
  RecoveryResult<TState> recover(RecoveryRequest request);
}

import '../models/snapshot_apply_request.dart';
import '../models/snapshot_apply_result.dart';

abstract interface class SnapshotApplier<TState> {
  SnapshotApplyResult<TState> apply(SnapshotApplyRequest request);
}

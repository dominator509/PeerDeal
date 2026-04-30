import '../contracts/conflict_detector.dart';
import '../contracts/snapshot_applier.dart';
import '../contracts/sync_coordinator.dart';
import '../models/reconciliation_result.dart';
import '../models/recovery_request.dart';
import '../models/recovery_result.dart';

class BasicSyncCoordinator<TState> implements SyncCoordinator<TState> {
  BasicSyncCoordinator({
    required this.conflictDetector,
    required this.snapshotApplier,
  });

  final ConflictDetector conflictDetector;
  final SnapshotApplier<TState> snapshotApplier;

  @override
  RecoveryResult<TState> recover(RecoveryRequest request) {
    final detection = conflictDetector.detect(request);

    if (detection.hasFatalConflicts) {
      return RecoveryResult<TState>(
        isSuccess: false,
        state: null,
        finalAppliedEventSeq: null,
        safeCloseRecommended: true,
        conflicts: detection.conflicts,
        reconciliation: const ReconciliationResult(
          canResume: false,
          requiresRecovery: true,
          recommendedAction: 'safe_close',
          notes: <String>['Fatal conflict detected during recovery planning.'],
        ),
      );
    }

    final applyResult = snapshotApplier.apply(
      SnapshotApplyRequest(
        tableId: request.tableId,
        sessionId: request.sessionId,
        protocolVersion: request.protocolVersion,
        snapshot: request.snapshot,
        events: request.events,
      ),
    );

    final recommendedAction = detection.hasConflicts ? 'resume_with_warning' : 'resume';

    return RecoveryResult<TState>(
      isSuccess: true,
      state: applyResult.state,
      finalAppliedEventSeq: applyResult.finalAppliedEventSeq,
      safeCloseRecommended: false,
      conflicts: detection.conflicts,
      warnings: applyResult.warnings,
      reconciliation: ReconciliationResult(
        canResume: true,
        requiresRecovery: detection.hasConflicts || request.snapshot != null,
        recommendedAction: recommendedAction,
        notes: detection.hasConflicts
            ? const <String>['Recovery completed with non-fatal conflicts that should be surfaced.']
            : const <String>['Recovery completed without detected conflicts.'],
      ),
    );
  }
}

import '../contracts/conflict_detector.dart';
import '../contracts/snapshot_applier.dart';
import '../contracts/sync_coordinator.dart';
import '../models/conflict_detection_result.dart';
import '../models/reconciliation_result.dart';
import '../models/recovery_request.dart';
import '../models/recovery_result.dart';
import '../models/snapshot_apply_request.dart';
import '../models/snapshot_apply_result.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';

class BasicSyncCoordinator<TState> implements SyncCoordinator<TState> {
  BasicSyncCoordinator({
    required this.conflictDetector,
    required this.snapshotApplier,
  });

  final ConflictDetector conflictDetector;
  final SnapshotApplier<TState> snapshotApplier;

  @override
  RecoveryResult<TState> recover(RecoveryRequest request) {
    final detection = _tryDetect(request);

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

    final applyRequest = SnapshotApplyRequest(
      tableId: request.tableId,
      sessionId: request.sessionId,
      protocolVersion: request.protocolVersion,
      snapshot: request.snapshot,
      events: request.events,
    );
    late final SnapshotApplyResult<TState> applyResult;
    try {
      applyResult = snapshotApplier.apply(applyRequest);
    } on Object catch (error) {
      return RecoveryResult<TState>(
        isSuccess: false,
        state: null,
        finalAppliedEventSeq: null,
        safeCloseRecommended: true,
        conflicts: <SyncConflict>[
          _dependencyFailureConflict(
            code: 'ERR_SYNC_SNAPSHOT_APPLIER_FAILURE',
            message: 'Recovery snapshot applier failed during application.',
            error: error,
          ),
        ],
        reconciliation: const ReconciliationResult(
          canResume: false,
          requiresRecovery: true,
          recommendedAction: 'safe_close',
          notes: <String>[
            'Fatal conflict detected during snapshot recovery application.',
          ],
        ),
      );
    }

    final recommendedAction = detection.hasConflicts
        ? 'resume_with_warning'
        : 'resume';

    if (!applyResult.isSuccess) {
      return RecoveryResult<TState>(
        isSuccess: false,
        state: null,
        finalAppliedEventSeq: null,
        safeCloseRecommended: true,
        conflicts: applyResult.conflicts,
        warnings: applyResult.warnings,
        reconciliation: const ReconciliationResult(
          canResume: false,
          requiresRecovery: true,
          recommendedAction: 'safe_close',
          notes: <String>[
            'Fatal conflict detected during snapshot recovery application.',
          ],
        ),
      );
    }

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
            ? const <String>[
                'Recovery completed with non-fatal conflicts that should be surfaced.',
              ]
            : const <String>['Recovery completed without detected conflicts.'],
      ),
    );
  }

  ConflictDetectionResult _tryDetect(RecoveryRequest request) {
    try {
      return conflictDetector.detect(request);
    } on Object catch (error) {
      return ConflictDetectionResult(
        conflicts: <SyncConflict>[
          _dependencyFailureConflict(
            code: 'ERR_SYNC_CONFLICT_DETECTOR_FAILURE',
            message: 'Recovery conflict detector failed before application.',
            error: error,
          ),
        ],
      );
    }
  }

  SyncConflict _dependencyFailureConflict({
    required String code,
    required String message,
    required Object error,
  }) {
    return SyncConflict(
      code: code,
      message: message,
      severity: SyncConflictSeverity.fatal,
      actual: error.runtimeType.toString(),
    );
  }
}

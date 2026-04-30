import '../contracts/conflict_detector.dart';
import '../models/conflict_detection_result.dart';
import '../models/recovery_request.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';

class BasicConflictDetector implements ConflictDetector {
  const BasicConflictDetector();

  @override
  ConflictDetectionResult detect(RecoveryRequest request) {
    final conflicts = <SyncConflict>[];

    if (request.snapshot != null) {
      if (request.snapshot!.protocolVersion != request.protocolVersion) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_PROTOCOL_MISMATCH',
            message: 'Snapshot protocol version does not match the recovery request.',
            severity: SyncConflictSeverity.fatal,
            expected: request.protocolVersion,
            actual: request.snapshot!.protocolVersion,
          ),
        );
      }

      if (request.snapshot!.tableId != request.tableId ||
          request.snapshot!.sessionId != request.sessionId) {
        conflicts.add(
          const SyncConflict(
            code: 'ERR_SNAPSHOT_SCOPE_MISMATCH',
            message: 'Snapshot table/session scope does not match the recovery request.',
            severity: SyncConflictSeverity.fatal,
          ),
        );
      }
    }

    for (var i = 1; i < request.events.length; i++) {
      final previous = request.events[i - 1];
      final current = request.events[i];
      if (current.eventSeq <= previous.eventSeq) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_EVENT_SEQUENCE_NON_MONOTONIC',
            message: 'Recovery event window is not strictly monotonic.',
            severity: SyncConflictSeverity.fatal,
            expected: '>${previous.eventSeq}',
            actual: '${current.eventSeq}',
          ),
        );
      }
    }

    if (request.snapshot != null && request.events.isNotEmpty) {
      final firstEventSeq = request.events.first.eventSeq;
      if (firstEventSeq <= request.snapshot!.snapshotBaseEventSeq) {
        conflicts.add(
          SyncConflict(
            code: 'WARN_EVENT_WINDOW_OVERLAPS_SNAPSHOT',
            message: 'Recovery event window overlaps the snapshot base sequence and will be filtered.',
            severity: SyncConflictSeverity.recoverable,
            expected: '>${request.snapshot!.snapshotBaseEventSeq}',
            actual: '$firstEventSeq',
          ),
        );
      }
    }

    if (request.expectedFinalEventSeq != null && request.events.isNotEmpty) {
      final actualFinalSeq = request.events.last.eventSeq;
      if (actualFinalSeq != request.expectedFinalEventSeq) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_FINAL_EVENT_SEQ_MISMATCH',
            message: 'Final event sequence does not match expected recovery baseline.',
            severity: SyncConflictSeverity.recoverable,
            expected: '${request.expectedFinalEventSeq}',
            actual: '$actualFinalSeq',
          ),
        );
      }
    }

    if (request.expectedFinalEventHash != null && request.events.isNotEmpty) {
      final actualFinalHash = request.events.last.eventHash;
      if (actualFinalHash != request.expectedFinalEventHash) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_FINAL_EVENT_HASH_MISMATCH',
            message: 'Final event hash does not match expected recovery baseline.',
            severity: SyncConflictSeverity.fatal,
            expected: request.expectedFinalEventHash,
            actual: actualFinalHash,
          ),
        );
      }
    }

    if (request.snapshot == null && request.events.isEmpty) {
      conflicts.add(
        const SyncConflict(
          code: 'WARN_EMPTY_RECOVERY_WINDOW',
          message: 'Recovery request has no snapshot and no events to apply.',
          severity: SyncConflictSeverity.warning,
        ),
      );
    }

    return ConflictDetectionResult(conflicts: conflicts);
  }
}

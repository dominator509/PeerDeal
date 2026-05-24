import '../contracts/snapshot_applier.dart';
import '../contracts/snapshot_state_projector.dart';
import '../models/snapshot_apply_request.dart';
import '../models/snapshot_apply_result.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';

class BasicSnapshotApplier<TState> implements SnapshotApplier<TState> {
  BasicSnapshotApplier({required this.projector});

  final SnapshotStateProjector<TState> projector;

  @override
  SnapshotApplyResult<TState> apply(SnapshotApplyRequest request) {
    var state = projector.createBaseState(
      tableId: request.tableId,
      sessionId: request.sessionId,
      protocolVersion: request.protocolVersion,
    );

    final conflicts = _validate(request);
    if (conflicts.isNotEmpty) {
      return SnapshotApplyResult<TState>(
        state: state,
        isSuccess: false,
        appliedEventCount: 0,
        finalAppliedEventSeq: null,
        conflicts: conflicts,
      );
    }

    final warnings = <String>[];

    if (request.snapshot != null) {
      state = projector.applySnapshot(
        state: state,
        snapshot: request.snapshot!,
      );
      warnings.add(
        'Recovery used snapshot checkpoint as a reconstruction accelerator.',
      );
    }

    final suffixEvents = request.snapshot == null
        ? request.events
        : request.events
              .where(
                (event) =>
                    event.eventSeq > request.snapshot!.snapshotBaseEventSeq,
              )
              .toList(growable: false);

    for (final event in suffixEvents) {
      state = projector.applyEvent(state: state, event: event);
    }

    return SnapshotApplyResult<TState>(
      state: state,
      appliedEventCount: suffixEvents.length,
      finalAppliedEventSeq: suffixEvents.isEmpty
          ? request.snapshot?.snapshotBaseEventSeq
          : suffixEvents.last.eventSeq,
      warnings: warnings,
    );
  }

  List<SyncConflict> _validate(SnapshotApplyRequest request) {
    final conflicts = <SyncConflict>[];
    final snapshot = request.snapshot;

    if (snapshot != null) {
      if (snapshot.tableId != request.tableId ||
          snapshot.sessionId != request.sessionId) {
        conflicts.add(
          const SyncConflict(
            code: 'ERR_SNAPSHOT_APPLY_SCOPE_MISMATCH',
            message:
                'Snapshot table/session scope does not match the apply request.',
            severity: SyncConflictSeverity.fatal,
          ),
        );
      }
      if (snapshot.protocolVersion != request.protocolVersion) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_APPLY_PROTOCOL_MISMATCH',
            message:
                'Snapshot protocol version does not match the apply request.',
            severity: SyncConflictSeverity.fatal,
            expected: request.protocolVersion,
            actual: snapshot.protocolVersion,
          ),
        );
      }
    }

    for (final event in request.events) {
      if (event.tableId != request.tableId ||
          event.sessionId != request.sessionId) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_APPLY_EVENT_SCOPE_MISMATCH',
            message:
                'Recovery event table/session scope does not match the apply request.',
            severity: SyncConflictSeverity.fatal,
            expected: '${request.tableId}/${request.sessionId}',
            actual: '${event.tableId}/${event.sessionId}',
          ),
        );
      }
      if (event.protocolVersion != request.protocolVersion) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_APPLY_EVENT_PROTOCOL_MISMATCH',
            message:
                'Recovery event protocol version does not match the apply request.',
            severity: SyncConflictSeverity.fatal,
            expected: request.protocolVersion,
            actual: event.protocolVersion,
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
            code: 'ERR_SNAPSHOT_APPLY_EVENT_SEQUENCE_NON_MONOTONIC',
            message: 'Recovery event window is not strictly monotonic.',
            severity: SyncConflictSeverity.fatal,
            expected: '>${previous.eventSeq}',
            actual: '${current.eventSeq}',
          ),
        );
      } else if (current.eventSeq != previous.eventSeq + 1) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_APPLY_EVENT_SEQUENCE_GAP',
            message: 'Recovery event sequence gap detected.',
            severity: SyncConflictSeverity.fatal,
            expected: '${previous.eventSeq + 1}',
            actual: '${current.eventSeq}',
          ),
        );
      }
      if (current.prevEventHash != previous.eventHash) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_APPLY_EVENT_HASH_CHAIN_BREAK',
            message: 'Recovery event hash chain continuity failed.',
            severity: SyncConflictSeverity.fatal,
            expected: previous.eventHash,
            actual: current.prevEventHash,
          ),
        );
      }
    }

    if (snapshot != null && request.events.isNotEmpty) {
      final suffixEvents = request.events
          .where((event) => event.eventSeq > snapshot.snapshotBaseEventSeq)
          .toList(growable: false);
      if (suffixEvents.isNotEmpty) {
        final expectedFirstSeq = snapshot.snapshotBaseEventSeq + 1;
        if (suffixEvents.first.eventSeq != expectedFirstSeq) {
          conflicts.add(
            SyncConflict(
              code: 'ERR_SNAPSHOT_APPLY_SUFFIX_GAP',
              message:
                  'Recovery event window does not continue from the snapshot base sequence.',
              severity: SyncConflictSeverity.fatal,
              expected: '$expectedFirstSeq',
              actual: '${suffixEvents.first.eventSeq}',
            ),
          );
        }
      }
    }

    return conflicts;
  }
}

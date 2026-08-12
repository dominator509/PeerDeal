import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/snapshot_applier.dart';
import '../contracts/snapshot_state_projector.dart';
import '../models/recovery_event_window_limits.dart';
import '../models/recovery_persistence_scope.dart';
import '../models/snapshot_apply_request.dart';
import '../models/snapshot_apply_result.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';

class BasicSnapshotApplier<TState> implements SnapshotApplier<TState> {
  BasicSnapshotApplier({
    required this.projector,
    this.maxEvents = RecoveryEventWindowLimits.defaultMaxEvents,
    this.eventCodec = const EventEnvelopeCodec(
      maxBytes: RecoveryEventWindowLimits.defaultMaxEventBytes,
    ),
    this.snapshotLimits = const CanonicalJsonLimits(
      maxEncodedBytes: RecoveryEventWindowLimits.defaultMaxSnapshotBytes,
    ),
  }) {
    if (maxEvents <= 0) {
      throw ArgumentError.value(
        maxEvents,
        'maxEvents',
        'Recovery snapshot apply event limit must be positive.',
      );
    }
  }

  final SnapshotStateProjector<TState> projector;
  final int maxEvents;
  final EventEnvelopeCodec eventCodec;
  final CanonicalJsonLimits snapshotLimits;

  @override
  SnapshotApplyResult<TState> apply(SnapshotApplyRequest request) {
    final conflicts = _validate(request);
    var state = projector.createBaseState(
      tableId: request.tableId,
      sessionId: request.sessionId,
      protocolVersion: request.protocolVersion,
    );

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
      try {
        state = projector.applySnapshot(
          state: state,
          snapshot: request.snapshot!,
        );
      } on Object catch (error) {
        return SnapshotApplyResult<TState>(
          state: state,
          isSuccess: false,
          appliedEventCount: 0,
          finalAppliedEventSeq: null,
          conflicts: <SyncConflict>[
            _projectorFailureConflict(
              message: 'Snapshot projector failed while applying snapshot.',
              error: error,
            ),
          ],
        );
      }
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

    var appliedEventCount = 0;
    for (final event in suffixEvents) {
      try {
        state = projector.applyEvent(state: state, event: event);
      } on Object catch (error) {
        return SnapshotApplyResult<TState>(
          state: state,
          isSuccess: false,
          appliedEventCount: appliedEventCount,
          finalAppliedEventSeq: appliedEventCount == 0
              ? request.snapshot?.snapshotBaseEventSeq
              : suffixEvents[appliedEventCount - 1].eventSeq,
          conflicts: <SyncConflict>[
            _projectorFailureConflict(
              message:
                  'Snapshot projector failed while applying recovery event.',
              error: error,
            ),
          ],
          warnings: warnings,
        );
      }
      appliedEventCount++;
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

    if (!RecoveryPersistenceScope(
      tableId: request.tableId,
      sessionId: request.sessionId,
      protocolVersion: request.protocolVersion,
    ).hasValidStorageIdentity) {
      return const <SyncConflict>[
        SyncConflict(
          code: 'ERR_SNAPSHOT_APPLY_SCOPE_INVALID',
          message: 'Snapshot apply request scope identity is invalid.',
          severity: SyncConflictSeverity.fatal,
        ),
      ];
    }

    if (request.events.length > maxEvents) {
      return <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_EVENT_COUNT_TOO_LARGE',
          message: 'Recovery event window exceeds the configured limit.',
          severity: SyncConflictSeverity.fatal,
          expected: '$maxEvents',
          actual: '${request.events.length}',
        ),
      ];
    }

    if (snapshot != null) {
      final snapshotEncodingConflict = _snapshotEncodingConflict(snapshot);
      if (snapshotEncodingConflict != null) {
        return <SyncConflict>[snapshotEncodingConflict];
      }
      final snapshotHashConflict = _snapshotHashConflict(snapshot);
      if (snapshotHashConflict != null) {
        return <SyncConflict>[snapshotHashConflict];
      }
    }

    if (snapshot == null && request.events.isEmpty) {
      conflicts.add(
        const SyncConflict(
          code: 'ERR_SNAPSHOT_APPLY_EMPTY_WINDOW',
          message:
              'Snapshot apply request has no snapshot and no events to apply.',
          severity: SyncConflictSeverity.fatal,
        ),
      );
    }

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
      final eventEncodingConflict = _eventEncodingConflict(event);
      if (eventEncodingConflict != null) {
        return <SyncConflict>[eventEncodingConflict];
      }

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

    if (snapshot == null && request.events.isNotEmpty) {
      final firstEventSeq = request.events.first.eventSeq;
      if (firstEventSeq != 1) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_APPLY_EVENT_WINDOW_MISSING_PREFIX',
            message:
                'Snapshot apply event window without a snapshot must start at the first event.',
            severity: SyncConflictSeverity.fatal,
            expected: '1',
            actual: '$firstEventSeq',
          ),
        );
      }
      final firstPrevEventHash = request.events.first.prevEventHash;
      if (firstPrevEventHash != genesisEventHash) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_APPLY_EVENT_WINDOW_GENESIS_HASH_MISMATCH',
            message:
                'Snapshot apply event window without a snapshot must chain from the genesis event hash.',
            severity: SyncConflictSeverity.fatal,
            expected: genesisEventHash,
            actual: firstPrevEventHash,
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

  SyncConflict? _eventEncodingConflict(EventEnvelope event) {
    try {
      eventCodec.encode(event);
      return null;
    } on FormatException catch (error) {
      final isTooLarge =
          error.message == 'Event envelope wire payload is too large.';
      return SyncConflict(
        code: isTooLarge
            ? 'ERR_RECOVERY_EVENT_TOO_LARGE'
            : 'ERR_RECOVERY_EVENT_INVALID',
        message: isTooLarge
            ? 'Recovery event exceeds the configured wire-size limit.'
            : 'Recovery event could not be encoded as a protocol envelope.',
        severity: SyncConflictSeverity.fatal,
        expected: isTooLarge ? '${eventCodec.maxBytes}' : null,
      );
    }
  }

  SyncConflict? _snapshotEncodingConflict(SnapshotEnvelope snapshot) {
    try {
      canonicalJsonEncode(snapshot.toJson(), limits: snapshotLimits);
      return null;
    } on FormatException catch (error) {
      final isTooLarge =
          error.message == 'Canonical JSON payload is too large.';
      return SyncConflict(
        code: isTooLarge
            ? 'ERR_RECOVERY_SNAPSHOT_TOO_LARGE'
            : 'ERR_RECOVERY_SNAPSHOT_INVALID',
        message: isTooLarge
            ? 'Recovery snapshot exceeds the configured canonical limit.'
            : 'Recovery snapshot could not be encoded as canonical protocol JSON.',
        severity: SyncConflictSeverity.fatal,
        expected: isTooLarge ? '${snapshotLimits.maxEncodedBytes}' : null,
      );
    }
  }

  SyncConflict? _snapshotHashConflict(SnapshotEnvelope snapshot) {
    try {
      if (snapshot.snapshotHash == computeCanonicalHash(snapshot.payload)) {
        return null;
      }
    } on Object {
      // Normalize hash computation failures into the same fatal contract.
    }
    return const SyncConflict(
      code: 'ERR_SNAPSHOT_PAYLOAD_HASH_MISMATCH',
      message: 'Snapshot payload hash does not match the snapshot envelope.',
      severity: SyncConflictSeverity.fatal,
    );
  }

  SyncConflict _projectorFailureConflict({
    required String message,
    required Object error,
  }) {
    return SyncConflict(
      code: 'ERR_SNAPSHOT_APPLY_PROJECTOR_FAILURE',
      message: message,
      severity: SyncConflictSeverity.fatal,
      actual: error.runtimeType.toString(),
    );
  }
}

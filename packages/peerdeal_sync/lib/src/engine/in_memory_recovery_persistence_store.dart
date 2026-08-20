import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/recovery_persistence_store.dart';
import '../models/persisted_recovery_window.dart';
import '../models/recovery_persistence_load_result.dart';
import '../models/recovery_persistence_result.dart';
import '../models/recovery_persistence_scope.dart';
import '../models/recovery_event_window_limits.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';

class InMemoryRecoveryPersistenceStore
    implements RecoveryPersistenceStore, RecoveryPersistenceLoadResultStore {
  InMemoryRecoveryPersistenceStore({
    int maxEvents = defaultMaxEvents,
    int maxEventBytes = defaultMaxEventBytes,
    this.eventHashCalculator = computeCanonicalEventHash,
  }) : _maxEvents = maxEvents,
       _eventCodec = EventEnvelopeCodec(maxBytes: maxEventBytes) {
    if (maxEvents <= 0) {
      throw ArgumentError.value(
        maxEvents,
        'maxEvents',
        'Recovery persistence event limit must be positive.',
      );
    }
    if (maxEventBytes <= 0) {
      throw ArgumentError.value(
        maxEventBytes,
        'maxEventBytes',
        'Recovery persistence event byte limit must be positive.',
      );
    }
  }

  static const defaultMaxEvents = RecoveryEventWindowLimits.defaultMaxEvents;
  static const defaultMaxEventBytes =
      RecoveryEventWindowLimits.defaultMaxEventBytes;

  final int _maxEvents;
  final EventHashCalculator eventHashCalculator;
  final EventEnvelopeCodec _eventCodec;
  final Map<String, _RecoveryPersistenceRecord> _records =
      <String, _RecoveryPersistenceRecord>{};

  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) {
    final scopeConflicts = _validateScopeIdentity(scope);
    if (scopeConflicts.isNotEmpty) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: scopeConflicts,
      );
    }

    final conflicts = <SyncConflict>[
      ..._validateSnapshotScope(scope, snapshot),
      ..._validateSnapshotIntegrity(snapshot),
    ];
    if (conflicts.isNotEmpty) {
      return RecoveryPersistenceResult(isSuccess: false, conflicts: conflicts);
    }

    final record = _records.putIfAbsent(
      scope.storageKey,
      _RecoveryPersistenceRecord.new,
    );
    final latestEventSeq = record.events.isEmpty
        ? 0
        : record.events.last.eventSeq;
    if (snapshot.snapshotBaseEventSeq > latestEventSeq) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: <SyncConflict>[
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_AHEAD_OF_EVENTS',
            message:
                'Persisted snapshot base sequence is ahead of stored events.',
            severity: SyncConflictSeverity.fatal,
            expected: '$latestEventSeq',
            actual: '${snapshot.snapshotBaseEventSeq}',
          ),
        ],
      );
    }

    final existingSnapshot = record.snapshot;
    if (existingSnapshot != null) {
      if (snapshot.snapshotBaseEventSeq <
          existingSnapshot.snapshotBaseEventSeq) {
        return RecoveryPersistenceResult(
          isSuccess: false,
          conflicts: <SyncConflict>[
            SyncConflict(
              code: 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_REGRESSION',
              message:
                  'Persisted snapshot would replace a newer snapshot checkpoint.',
              severity: SyncConflictSeverity.fatal,
              expected: '${existingSnapshot.snapshotBaseEventSeq}',
              actual: '${snapshot.snapshotBaseEventSeq}',
            ),
          ],
        );
      }

      if (snapshot.snapshotBaseEventSeq ==
              existingSnapshot.snapshotBaseEventSeq &&
          snapshot.snapshotHash != existingSnapshot.snapshotHash) {
        return RecoveryPersistenceResult(
          isSuccess: false,
          conflicts: <SyncConflict>[
            SyncConflict(
              code: 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_HASH_MISMATCH',
              message:
                  'Persisted snapshot hash changed for an existing checkpoint.',
              severity: SyncConflictSeverity.fatal,
              expected: existingSnapshot.snapshotHash,
              actual: snapshot.snapshotHash,
            ),
          ],
        );
      }
    }

    record.snapshot = snapshot;
    return RecoveryPersistenceResult.success();
  }

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) {
    final scopeConflicts = _validateScopeIdentity(scope);
    if (scopeConflicts.isNotEmpty) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: scopeConflicts,
      );
    }

    if (events.isEmpty) {
      return RecoveryPersistenceResult.success(
        warnings: <String>['No recovery events were appended.'],
      );
    }

    final record = _records[scope.storageKey];
    final storedEvents = record?.events ?? const <EventEnvelope>[];
    final conflicts = _validateEventAppend(scope, storedEvents, events);
    if (conflicts.isNotEmpty) {
      return RecoveryPersistenceResult(isSuccess: false, conflicts: conflicts);
    }

    final target =
        record ??
        _records.putIfAbsent(scope.storageKey, _RecoveryPersistenceRecord.new);
    target.events.addAll(events);
    return RecoveryPersistenceResult.success();
  }

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) {
    final scopeConflicts = _validateScopeIdentity(scope);
    if (scopeConflicts.isNotEmpty) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: scopeConflicts,
      );
    }

    _records.remove(scope.storageKey);
    return RecoveryPersistenceResult.success();
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    if (!scope.hasValidStorageIdentity) {
      return PersistedRecoveryWindow(events: <EventEnvelope>[]);
    }

    final record = _records[scope.storageKey];
    return PersistedRecoveryWindow(
      snapshot: record?.snapshot,
      events: List<EventEnvelope>.unmodifiable(
        record?.events ?? const <EventEnvelope>[],
      ),
    );
  }

  @override
  RecoveryPersistenceLoadResult loadWindowResult(
    RecoveryPersistenceScope scope,
  ) {
    final scopeConflicts = _validateScopeIdentity(scope);
    if (scopeConflicts.isNotEmpty) {
      return RecoveryPersistenceLoadResult.failure(conflicts: scopeConflicts);
    }
    return RecoveryPersistenceLoadResult.success(loadWindow(scope));
  }

  List<SyncConflict> _validateScopeIdentity(RecoveryPersistenceScope scope) {
    if (scope.hasValidStorageIdentity) return const <SyncConflict>[];
    return const <SyncConflict>[
      SyncConflict(
        code: 'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
        message: 'Recovery persistence scope identity is invalid.',
        severity: SyncConflictSeverity.fatal,
      ),
    ];
  }

  List<SyncConflict> _validateSnapshotScope(
    RecoveryPersistenceScope scope,
    SnapshotEnvelope snapshot,
  ) {
    final conflicts = <SyncConflict>[];
    if (snapshot.tableId != scope.tableId ||
        snapshot.sessionId != scope.sessionId) {
      conflicts.add(
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_SCOPE_MISMATCH',
          message: 'Persisted snapshot scope does not match the store scope.',
          severity: SyncConflictSeverity.fatal,
          expected: '${scope.tableId}/${scope.sessionId}',
          actual: '${snapshot.tableId}/${snapshot.sessionId}',
        ),
      );
    }
    if (snapshot.protocolVersion != scope.protocolVersion) {
      conflicts.add(
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_PROTOCOL_MISMATCH',
          message:
              'Persisted snapshot protocol version does not match the store scope.',
          severity: SyncConflictSeverity.fatal,
          expected: scope.protocolVersion,
          actual: snapshot.protocolVersion,
        ),
      );
    }
    return conflicts;
  }

  List<SyncConflict> _validateSnapshotIntegrity(SnapshotEnvelope snapshot) {
    try {
      canonicalJsonEncode(snapshot.toJson());
    } on FormatException catch (error) {
      final isTooLarge =
          error.message == 'Canonical JSON payload is too large.';
      return <SyncConflict>[
        SyncConflict(
          code: isTooLarge
              ? 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_TOO_LARGE'
              : 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_INVALID',
          message: isTooLarge
              ? 'Persisted snapshot exceeds the configured canonical limit.'
              : 'Persisted snapshot could not be encoded as canonical protocol JSON.',
          severity: SyncConflictSeverity.fatal,
        ),
      ];
    } on Object {
      return const <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_INVALID',
          message:
              'Persisted snapshot could not be encoded as canonical protocol JSON.',
          severity: SyncConflictSeverity.fatal,
        ),
      ];
    }

    try {
      if (snapshot.snapshotHash == computeCanonicalHash(snapshot.payload)) {
        return const <SyncConflict>[];
      }
    } on Object {
      // Normalize hash computation failures into the same fatal contract.
    }
    return const <SyncConflict>[
      SyncConflict(
        code: 'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_PAYLOAD_HASH_MISMATCH',
        message: 'Persisted snapshot payload hash does not match the envelope.',
        severity: SyncConflictSeverity.fatal,
      ),
    ];
  }

  List<SyncConflict> _validateEventAppend(
    RecoveryPersistenceScope scope,
    List<EventEnvelope> storedEvents,
    List<EventEnvelope> events,
  ) {
    final totalEventCount = storedEvents.length + events.length;
    if (totalEventCount > _maxEvents) {
      return <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_EVENT_COUNT_TOO_LARGE',
          message:
              'Recovery persistence event window exceeds the configured limit.',
          severity: SyncConflictSeverity.fatal,
          expected: '$_maxEvents',
          actual: '$totalEventCount',
        ),
      ];
    }

    final conflicts = <SyncConflict>[];
    EventEnvelope? previous = storedEvents.isEmpty ? null : storedEvents.last;

    for (final event in events) {
      if (!validateEventEnvelopeIdentity(event).isValid) {
        conflicts.add(
          const SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_EVENT_IDENTITY_INVALID',
            message: 'Persisted event envelope identity is empty or unsafe.',
            severity: SyncConflictSeverity.fatal,
          ),
        );
      }
      try {
        _eventCodec.encode(event);
      } on FormatException catch (error) {
        final isTooLarge =
            error.message == 'Event envelope wire payload is too large.';
        conflicts.add(
          SyncConflict(
            code: isTooLarge
                ? 'ERR_RECOVERY_PERSISTENCE_EVENT_TOO_LARGE'
                : 'ERR_RECOVERY_PERSISTENCE_EVENT_INVALID',
            message: isTooLarge
                ? 'Recovery persistence event exceeds the configured byte limit.'
                : 'Recovery persistence event could not be encoded.',
            severity: SyncConflictSeverity.fatal,
            expected: isTooLarge ? '${_eventCodec.maxBytes}' : null,
          ),
        );
      }
      if (event.tableId != scope.tableId ||
          event.sessionId != scope.sessionId) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_EVENT_SCOPE_MISMATCH',
            message:
                'Persisted event table/session scope does not match the store scope.',
            severity: SyncConflictSeverity.fatal,
            expected: '${scope.tableId}/${scope.sessionId}',
            actual: '${event.tableId}/${event.sessionId}',
          ),
        );
      }
      if (event.protocolVersion != scope.protocolVersion) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_EVENT_PROTOCOL_MISMATCH',
            message:
                'Persisted event protocol version does not match the store scope.',
            severity: SyncConflictSeverity.fatal,
            expected: scope.protocolVersion,
            actual: event.protocolVersion,
          ),
        );
      }

      try {
        final expectedHash = eventHashCalculator(event);
        if (expectedHash != event.eventHash) {
          conflicts.add(
            SyncConflict(
              code: 'ERR_RECOVERY_PERSISTENCE_EVENT_HASH_INVALID',
              message:
                  'Persisted event content hash does not match the envelope.',
              severity: SyncConflictSeverity.fatal,
              expected: expectedHash,
              actual: event.eventHash,
            ),
          );
        }
      } on Object {
        conflicts.add(
          const SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_EVENT_HASH_INVALID',
            message: 'Persisted event content hash could not be calculated.',
            severity: SyncConflictSeverity.fatal,
          ),
        );
      }

      final expectedSeq = previous == null ? 1 : previous.eventSeq + 1;
      if (event.eventSeq != expectedSeq) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_EVENT_SEQUENCE_GAP',
            message: 'Persisted event append would create a sequence gap.',
            severity: SyncConflictSeverity.fatal,
            expected: '$expectedSeq',
            actual: '${event.eventSeq}',
          ),
        );
      }
      if (previous == null && event.prevEventHash != genesisEventHash) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_GENESIS_HASH_MISMATCH',
            message:
                'Persisted first event must chain from the genesis event hash.',
            severity: SyncConflictSeverity.fatal,
            expected: genesisEventHash,
            actual: event.prevEventHash,
          ),
        );
      }
      if (previous != null && event.prevEventHash != previous.eventHash) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_EVENT_HASH_CHAIN_BREAK',
            message: 'Persisted event append would break hash continuity.',
            severity: SyncConflictSeverity.fatal,
            expected: previous.eventHash,
            actual: event.prevEventHash,
          ),
        );
      }

      previous = event;
    }

    return conflicts;
  }
}

class _RecoveryPersistenceRecord {
  SnapshotEnvelope? snapshot;
  final List<EventEnvelope> events = <EventEnvelope>[];
}

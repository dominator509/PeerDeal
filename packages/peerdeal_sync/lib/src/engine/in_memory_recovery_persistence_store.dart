import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/recovery_persistence_store.dart';
import '../models/persisted_recovery_window.dart';
import '../models/recovery_persistence_result.dart';
import '../models/recovery_persistence_scope.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';

class InMemoryRecoveryPersistenceStore implements RecoveryPersistenceStore {
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
    return const RecoveryPersistenceResult.success();
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
      return const RecoveryPersistenceResult.success(
        warnings: <String>['No recovery events were appended.'],
      );
    }

    final record = _records.putIfAbsent(
      scope.storageKey,
      _RecoveryPersistenceRecord.new,
    );
    final conflicts = _validateEventAppend(scope, record.events, events);
    if (conflicts.isNotEmpty) {
      return RecoveryPersistenceResult(isSuccess: false, conflicts: conflicts);
    }

    record.events.addAll(events);
    return const RecoveryPersistenceResult.success();
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    if (!scope.hasValidStorageIdentity) {
      return const PersistedRecoveryWindow(events: <EventEnvelope>[]);
    }

    final record = _records[scope.storageKey];
    return PersistedRecoveryWindow(
      snapshot: record?.snapshot,
      events: List<EventEnvelope>.unmodifiable(
        record?.events ?? const <EventEnvelope>[],
      ),
    );
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

  List<SyncConflict> _validateEventAppend(
    RecoveryPersistenceScope scope,
    List<EventEnvelope> storedEvents,
    List<EventEnvelope> events,
  ) {
    final conflicts = <SyncConflict>[];
    EventEnvelope? previous = storedEvents.isEmpty ? null : storedEvents.last;

    for (final event in events) {
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

import 'dart:convert';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_persistence_writer.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_snapshot_coordinator.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test(
    'skips a queued checkpoint when its persistence predicate is stale',
    () async {
      final store = _ToggleSnapshotStore();
      final typed = _typedSnapshot();
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
        ),
      );
      var shouldPersist = true;

      final resultFuture = coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
        shouldPersist: () => shouldPersist,
      );
      shouldPersist = false;

      final result = await resultFuture;

      expect(result.isSuccess, isTrue);
      expect(store.saveAttempts, 0);
      expect(coordinator.hasPending, isFalse);
    },
  );

  test(
    'checkpoints a typed snapshot and clears pending state on success',
    () async {
      final store = _ToggleSnapshotStore();
      final typed = _typedSnapshot();
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
        ),
      );

      final result = await coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
      );

      expect(result.isSuccess, isTrue);
      expect(coordinator.hasPending, isFalse);
      expect(store.loadWindow(_scope()).snapshot, isNotNull);
    },
  );

  test('persists configured snapshot metadata', () async {
    final store = _ToggleSnapshotStore();
    final typed = _typedSnapshot();
    final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
      persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
        store: store,
      ),
      snapshotType: 'HoldemStateSnapshotV2',
      snapshotVersion: '2.0',
    );

    final result = await coordinator.persist(
      tableState: typed.tableState,
      handState: typed.handState,
      eventCursor: typed.eventCursor,
    );

    final snapshot = store.loadWindow(_scope()).snapshot;
    expect(result.isSuccess, isTrue);
    expect(snapshot?.snapshotType, 'HoldemStateSnapshotV2');
    expect(snapshot?.snapshotVersion, '2.0');
  });

  test('fails closed when the snapshot ID factory throws', () async {
    final store = _ToggleSnapshotStore();
    final typed = _typedSnapshot();
    final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
      persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
        store: store,
      ),
      snapshotIdFactory: (_, _) => throw StateError('snapshot id failed'),
    );

    final result = await coordinator.persist(
      tableState: typed.tableState,
      handState: typed.handState,
      eventCursor: typed.eventCursor,
    );

    expect(result.isSuccess, isFalse);
    expect(result.warnings, ['Holdem snapshot ID could not be created.']);
    expect(coordinator.lastResult, same(result));
    expect(coordinator.hasPending, isFalse);
    expect(store.saveAttempts, 0);
  });

  test('rejects unsafe factory snapshot IDs before queueing', () async {
    for (final snapshotId in <String>[
      'snapshot_${String.fromCharCode(0x85)}',
      'x' * (const CanonicalJsonLimits().maxTextBytes + 1),
    ]) {
      final store = _ToggleSnapshotStore(failuresRemaining: 10);
      final typed = _typedSnapshot();
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
        ),
        snapshotIdFactory: (_, _) => snapshotId,
      );

      final result = await coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
      );

      expect(result.isSuccess, isFalse);
      expect(result.warnings, ['Holdem snapshot identity is invalid.']);
      expect(coordinator.hasPending, isFalse);
      expect(store.saveAttempts, 0);
    }
  });

  test('rejects unsafe configured snapshot metadata before queueing', () async {
    final typed = _typedSnapshot();
    final cases = <({String type, String version, String warning})>[
      (
        type: 'HoldemStateSnapshot',
        version: '2.${String.fromCharCode(0x85)}',
        warning: 'Holdem snapshot version is invalid.',
      ),
      (
        type: 'x' * (const CanonicalJsonLimits().maxTextBytes + 1),
        version: '1.0',
        warning: 'Holdem snapshot type is invalid.',
      ),
    ];
    for (final testCase in cases) {
      final store = _ToggleSnapshotStore(failuresRemaining: 10);
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
        ),
        snapshotType: testCase.type,
        snapshotVersion: testCase.version,
      );

      final result = await coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
      );

      expect(result.isSuccess, isFalse);
      expect(result.warnings, [testCase.warning]);
      expect(coordinator.hasPending, isFalse);
      expect(store.saveAttempts, 0);
    }
  });

  test(
    'rejects an oversized event suffix before copying or persisting',
    () async {
      final store = _ToggleSnapshotStore();
      final typed = _typedSnapshotAfterEvent();
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
          maxRecoveryEvents: 1,
        ),
        maxRecoveryEvents: 1,
      );

      final result = await coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
        events: <EventEnvelope>[_event(), _event()],
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.warnings,
        contains(
          'Holdem snapshot event suffix exceeds the configured recovery event limit.',
        ),
      );
      expect(coordinator.hasPending, isFalse);
      expect(store.saveAttempts, 0);
    },
  );

  test('rejects a non-positive coordinator recovery event limit', () {
    expect(
      () => AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: _ToggleSnapshotStore(),
        ),
        maxRecoveryEvents: 0,
      ),
      throwsArgumentError,
    );
  });

  test('bounds pending checkpoints when the store stays unavailable', () async {
    final store = _ToggleSnapshotStore(failuresRemaining: 10);
    final typed = _typedSnapshot();
    final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
      persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
        store: store,
      ),
      maxPendingCheckpoints: 1,
    );

    final first = await coordinator.persist(
      tableState: typed.tableState,
      handState: typed.handState,
      eventCursor: typed.eventCursor,
    );
    final second = await coordinator.persist(
      tableState: typed.tableState,
      handState: typed.handState,
      eventCursor: typed.eventCursor,
    );

    expect(first.isSuccess, isFalse);
    expect(second.isSuccess, isFalse);
    expect(
      second.warnings,
      contains('Holdem snapshot checkpoint queue is full.'),
    );
    expect(coordinator.hasPending, isTrue);
    expect(store.saveAttempts, 2);
  });

  test('rejects a non-positive pending checkpoint limit', () {
    expect(
      () => AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: _ToggleSnapshotStore(),
        ),
        maxPendingCheckpoints: 0,
      ),
      throwsArgumentError,
    );
  });

  test('rejects a non-positive pending checkpoint byte limit', () {
    expect(
      () => AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: _ToggleSnapshotStore(),
        ),
        maxPendingCheckpointBytes: 0,
      ),
      throwsArgumentError,
    );
  });

  test('bounds queued checkpoints by serialized byte budget', () async {
    final store = _ToggleSnapshotStore(failuresRemaining: 10);
    final typed = _typedSnapshot();
    final checkpointBytes = _serializedCheckpointBytes(typed);
    final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
      persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
        store: store,
      ),
      maxPendingCheckpointBytes: checkpointBytes,
    );

    final first = await coordinator.persist(
      tableState: typed.tableState,
      handState: typed.handState,
      eventCursor: typed.eventCursor,
    );
    final second = await coordinator.persist(
      tableState: typed.tableState,
      handState: typed.handState,
      eventCursor: typed.eventCursor,
    );

    expect(first.isSuccess, isFalse);
    expect(second.isSuccess, isFalse);
    expect(
      second.warnings,
      contains('Holdem snapshot checkpoint byte budget is full.'),
    );
    expect(coordinator.hasPending, isTrue);
    expect(store.saveAttempts, 2);
  });

  test(
    'persists the accepted event suffix before its snapshot checkpoint',
    () async {
      final store = _ToggleSnapshotStore();
      final typed = _typedSnapshotAfterEvent();
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
        ),
      );

      final result = await coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
        events: <EventEnvelope>[_event()],
      );

      final window = store.loadWindow(_scope());
      expect(result.isSuccess, isTrue);
      expect(window.events.map((event) => event.eventSeq), [1]);
      expect(window.snapshot?.snapshotBaseEventSeq, 1);
    },
  );

  test(
    'retries a failed checkpoint before accepting a newer checkpoint',
    () async {
      final store = _ToggleSnapshotStore(failuresRemaining: 1);
      final typed = _typedSnapshot();
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
        ),
      );

      final first = coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
      );
      final second = coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
      );

      expect((await first).isSuccess, isFalse);
      expect((await second).isSuccess, isTrue);
      expect(store.saveAttempts, 3);
      expect(coordinator.hasPending, isFalse);
    },
  );

  test(
    'does not reappend a durable event suffix when snapshot retry succeeds',
    () async {
      final store = _ToggleSnapshotStore(failuresRemaining: 1);
      final typed = _typedSnapshotAfterEvent();
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
        ),
      );

      final first = await coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
        events: <EventEnvelope>[_event()],
      );
      final retry = await coordinator.retryPending();

      final window = store.loadWindow(_scope());
      expect(first.isSuccess, isFalse);
      expect(retry.isSuccess, isTrue);
      expect(store.saveAttempts, 2);
      expect(window.events.map((event) => event.eventSeq), [1]);
      expect(window.snapshot?.snapshotBaseEventSeq, 1);
    },
  );

  test('retains newer checkpoints when an older retry fails again', () async {
    final store = _ToggleSnapshotStore(failuresRemaining: 2);
    final firstTyped = _typedSnapshot();
    final newerTyped = _typedSnapshotAfterEvent();
    final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
      persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
        store: store,
      ),
    );

    final first = coordinator.persist(
      tableState: firstTyped.tableState,
      handState: firstTyped.handState,
      eventCursor: firstTyped.eventCursor,
    );
    final newer = coordinator.persist(
      tableState: newerTyped.tableState,
      handState: newerTyped.handState,
      eventCursor: newerTyped.eventCursor,
      events: <EventEnvelope>[_event()],
    );

    expect((await first).isSuccess, isFalse);
    expect((await newer).isSuccess, isFalse);
    expect(coordinator.hasPending, isTrue);

    store.failuresRemaining = 0;
    final firstRetry = coordinator.retryPending();
    final secondRetry = coordinator.retryPending();
    expect((await firstRetry).isSuccess, isTrue);
    expect((await secondRetry).isSuccess, isTrue);
    expect(store.saveAttempts, 4);
    expect(store.loadWindow(_scope()).snapshot?.snapshotBaseEventSeq, 1);
    expect(coordinator.hasPending, isFalse);
  });

  test(
    'discardPending prevents a terminal route from retrying old state',
    () async {
      final store = _ToggleSnapshotStore(failuresRemaining: 1);
      final typed = _typedSnapshot();
      final coordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
          store: store,
        ),
      );

      final failed = await coordinator.persist(
        tableState: typed.tableState,
        handState: typed.handState,
        eventCursor: typed.eventCursor,
      );
      expect(failed.isSuccess, isFalse);
      expect(coordinator.hasPending, isTrue);

      expect(store.wipe(scope: _scope()).isSuccess, isTrue);
      await coordinator.discardPending();

      expect(coordinator.hasPending, isFalse);
      expect(store.loadWindow(_scope()).snapshot, isNull);
    },
  );
}

class _ToggleSnapshotStore extends InMemoryRecoveryPersistenceStore {
  _ToggleSnapshotStore({this.failuresRemaining = 0});

  int failuresRemaining;
  int saveAttempts = 0;

  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) {
    saveAttempts++;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['temporary snapshot failure'],
      );
    }
    return super.saveSnapshot(scope: scope, snapshot: snapshot);
  }
}

HoldemStateSnapshot _typedSnapshot() {
  return HoldemStateSnapshot(
    tableState: TableState.initial(
      tableId: 'table_001',
      sessionId: 'session_001',
      protocolVersion: '1.0.0',
    ),
    handState: HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.handIdle,
      bettingRound: HoldemBettingRound.none,
      seats: <HoldemSeatState>[],
      currentActorSeat: 0,
      buttonSeat: 0,
      smallBlindSeat: 0,
      bigBlindSeat: 1,
      currentBetToCall: 0,
      minimumRaiseAmount: 1,
    ),
    eventCursor: HoldemEventCursor(
      protocolVersion: '1.0.0',
      tableId: 'table_001',
      sessionId: 'session_001',
      nextEventSeq: 1,
      previousEventHash: genesisEventHash,
      actorRef: 'peer_local',
      eventIdFactory: _eventId,
      emittedAtFactory: _eventTimestamp,
    ),
  );
}

HoldemStateSnapshot _typedSnapshotAfterEvent() {
  final initial = _typedSnapshot();
  return HoldemStateSnapshot(
    tableState: initial.tableState.copyWith(
      eventSequence: 1,
      metadata: const <String, Object?>{'last_event_hash': 'hash_1'},
    ),
    handState: initial.handState,
    eventCursor: HoldemEventCursor(
      protocolVersion: '1.0.0',
      tableId: 'table_001',
      sessionId: 'session_001',
      nextEventSeq: 2,
      previousEventHash: 'hash_1',
      actorRef: 'peer_local',
      eventIdFactory: _eventId,
      emittedAtFactory: _eventTimestamp,
    ),
  );
}

EventEnvelope _event() => EventEnvelope(
  eventId: 'evt_1',
  eventType: 'HoldemActionApplied',
  eventVersion: '1.0',
  protocolVersion: '1.0.0',
  eventSeq: 1,
  tableId: 'table_001',
  sessionId: 'session_001',
  handId: null,
  emittedAt: _eventTimestamp(),
  actorRef: 'peer_local',
  payload: const <String, Object?>{},
  prevEventHash: genesisEventHash,
  eventHash: 'hash_1',
);

String _eventId(String eventType, int eventSeq) => 'evt_${eventType}_$eventSeq';

String _eventTimestamp() => '2026-08-11T00:00:00Z';

RecoveryPersistenceScope _scope() => const RecoveryPersistenceScope(
  tableId: 'table_001',
  sessionId: 'session_001',
  protocolVersion: '1.0.0',
);

int _serializedCheckpointBytes(HoldemStateSnapshot typed) {
  final payload = typed.toJson();
  final snapshot = SnapshotEnvelope(
    snapshotId: 'snapshot_session_001_0',
    snapshotType: 'HoldemStateSnapshot',
    snapshotVersion: '1.0',
    protocolVersion: typed.tableState.protocolVersion,
    tableId: typed.tableState.tableId,
    sessionId: typed.tableState.sessionId,
    snapshotBaseEventSeq: typed.eventCursor.nextEventSeq - 1,
    snapshotHash: computeCanonicalHash(payload),
    payload: payload,
  );
  return utf8
      .encode(
        canonicalJsonEncode(<String, Object?>{
          'snapshot': snapshot.toJson(),
          'events': const <Object?>[],
        }),
      )
      .length;
}

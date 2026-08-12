import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_persistence_writer.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_snapshot_coordinator.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
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
      return const RecoveryPersistenceResult(
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
    handState: const HoldemHandState(
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

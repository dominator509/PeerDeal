import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_persistence_writer.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('appends an event suffix before writing the typed snapshot', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshotAfterEvent();
    final result = AppHoldemProductionSessionPersistenceWriter(store: store)
        .persist(
          snapshotId: 'snapshot_001',
          tableState: state.tableState,
          handState: state.handState,
          eventCursor: state.eventCursor,
          events: <EventEnvelope>[_event()],
        );

    expect(result.isSuccess, isTrue);
    final window = store.loadWindow(_scope());
    expect(window.events.map((event) => event.eventSeq), [1]);
    expect(window.snapshot?.snapshotBaseEventSeq, 1);
  });

  test('writes an initial snapshot without an event suffix', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshot();
    final result = AppHoldemProductionSessionPersistenceWriter(store: store)
        .persist(
          snapshotId: 'snapshot_001',
          tableState: state.tableState,
          handState: state.handState,
          eventCursor: state.eventCursor,
        );

    expect(result.isSuccess, isTrue);
    final window = store.loadWindow(_scope());
    expect(window.events, isEmpty);
    expect(window.snapshot?.snapshotBaseEventSeq, 0);
  });

  test('rejects an unverified already-persisted event suffix', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshotAfterEvent();
    final result = AppHoldemProductionSessionPersistenceWriter(store: store)
        .persist(
          snapshotId: 'snapshot_001',
          tableState: state.tableState,
          handState: state.handState,
          eventCursor: state.eventCursor,
          events: <EventEnvelope>[_event()],
          eventsAlreadyPersisted: true,
        );

    expect(result.isSuccess, isFalse);
    expect(
      result.warnings,
      contains('Holdem persisted event suffix could not be verified.'),
    );
    expect(store.loadWindow(_scope()).snapshot, isNull);
  });

  test(
    'accepts an already-persisted event suffix after exact verification',
    () {
      final store = InMemoryRecoveryPersistenceStore();
      final event = _event();
      expect(
        store
            .appendEvents(scope: _scope(), events: <EventEnvelope>[event])
            .isSuccess,
        isTrue,
      );
      final state = _typedSnapshotAfterEvent();
      final result = AppHoldemProductionSessionPersistenceWriter(store: store)
          .persist(
            snapshotId: 'snapshot_001',
            tableState: state.tableState,
            handState: state.handState,
            eventCursor: state.eventCursor,
            events: <EventEnvelope>[event],
            eventsAlreadyPersisted: true,
          );

      expect(result.isSuccess, isTrue);
      expect(store.loadWindow(_scope()).snapshot?.snapshotBaseEventSeq, 1);
    },
  );

  test('rejects an oversized event suffix before traversal or append', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshotAfterEvent();
    final result =
        AppHoldemProductionSessionPersistenceWriter(
          store: store,
          maxRecoveryEvents: 1,
        ).persist(
          snapshotId: 'snapshot_001',
          tableState: state.tableState,
          handState: state.handState,
          eventCursor: state.eventCursor,
          events: <EventEnvelope>[_event(), _event()],
        );

    expect(result.isSuccess, isFalse);
    expect(
      result.warnings,
      contains(
        'Holdem event-log suffix exceeds the configured recovery event limit.',
      ),
    );
    expect(store.loadWindow(_scope()).events, isEmpty);
    expect(store.loadWindow(_scope()).snapshot, isNull);
  });

  test('rejects a non-positive recovery event limit', () {
    expect(
      () => AppHoldemProductionSessionPersistenceWriter(
        store: InMemoryRecoveryPersistenceStore(),
        maxRecoveryEvents: 0,
      ),
      throwsArgumentError,
    );
  });

  test('rejects an event suffix that does not match resulting state', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshot();
    final result = AppHoldemProductionSessionPersistenceWriter(store: store)
        .persist(
          snapshotId: 'snapshot_001',
          tableState: state.tableState,
          handState: state.handState,
          eventCursor: state.eventCursor,
          events: <EventEnvelope>[_event()],
        );

    expect(result.isSuccess, isFalse);
    expect(
      result.warnings,
      contains('Holdem event-log suffix does not match resulting state.'),
    );
    expect(store.loadWindow(_scope()).events, isEmpty);
    expect(store.loadWindow(_scope()).snapshot, isNull);
  });

  test('preflights snapshot identity before appending an event suffix', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshotAfterEvent();
    final result = AppHoldemProductionSessionPersistenceWriter(store: store)
        .persist(
          snapshotId: ' snapshot_001',
          tableState: state.tableState,
          handState: state.handState,
          eventCursor: state.eventCursor,
          events: <EventEnvelope>[_event()],
        );

    expect(result.isSuccess, isFalse);
    expect(result.warnings, contains('Holdem snapshot identity is invalid.'));
    expect(store.loadWindow(_scope()).events, isEmpty);
    expect(store.loadWindow(_scope()).snapshot, isNull);
  });

  test(
    'preflights snapshot serialization before appending an event suffix',
    () {
      final store = InMemoryRecoveryPersistenceStore();
      final state = _typedSnapshotAfterEvent();
      final malformed = HoldemStateSnapshot(
        tableState: state.tableState.copyWith(
          metadata: <String, Object?>{'unsupported': Object()},
        ),
        handState: state.handState,
        eventCursor: state.eventCursor,
      );

      final result = AppHoldemProductionSessionPersistenceWriter(store: store)
          .persist(
            snapshotId: 'snapshot_001',
            tableState: malformed.tableState,
            handState: malformed.handState,
            eventCursor: malformed.eventCursor,
            events: <EventEnvelope>[_event()],
          );

      expect(result.isSuccess, isFalse);
      expect(
        result.warnings,
        contains('Holdem snapshot serialization is invalid.'),
      );
      expect(store.loadWindow(_scope()).events, isEmpty);
      expect(store.loadWindow(_scope()).snapshot, isNull);
    },
  );

  test('rejects retention events before event-log persistence', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshotAfterEvent();
    final result = AppHoldemProductionSessionPersistenceWriter(store: store)
        .persist(
          snapshotId: 'snapshot_001',
          tableState: state.tableState,
          handState: state.handState,
          eventCursor: state.eventCursor,
          events: <EventEnvelope>[_event(eventType: 'SessionClosed')],
        );

    expect(result.isSuccess, isFalse);
    expect(
      result.warnings,
      contains('Holdem retention events require the close-retention adapter.'),
    );
    expect(store.loadWindow(_scope()).events, isEmpty);
  });

  test('does not write a snapshot when event append is rejected', () {
    final store = InMemoryRecoveryPersistenceStore();
    final event = _event();
    expect(
      store
          .appendEvents(scope: _scope(), events: <EventEnvelope>[event])
          .isSuccess,
      isTrue,
    );
    final state = _typedSnapshotAfterEvent();
    final result = AppHoldemProductionSessionPersistenceWriter(store: store)
        .persist(
          snapshotId: 'snapshot_001',
          tableState: state.tableState,
          handState: state.handState,
          eventCursor: state.eventCursor,
          events: <EventEnvelope>[event],
        );

    expect(result.isSuccess, isFalse);
    expect(store.loadWindow(_scope()).snapshot, isNull);
  });
}

HoldemStateSnapshot _typedSnapshot() {
  return HoldemStateSnapshot(
    tableState: TableState.initial(
      tableId: 'table_001',
      sessionId: 'session_001',
      protocolVersion: '1.0.0',
    ),
    handState: _handState(),
    eventCursor: _cursor(),
  );
}

HoldemStateSnapshot _typedSnapshotAfterEvent() {
  return HoldemStateSnapshot(
    tableState:
        TableState.initial(
          tableId: 'table_001',
          sessionId: 'session_001',
          protocolVersion: '1.0.0',
        ).copyWith(
          eventSequence: 1,
          metadata: <String, Object?>{
            'last_event_hash': _event().eventHash,
          },
        ),
    handState: _handState(),
    eventCursor: _cursor(
      nextEventSeq: 2,
      previousEventHash: _event().eventHash,
    ),
  );
}

HoldemHandState _handState() => HoldemHandState(
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
);

HoldemEventCursor _cursor({
  int nextEventSeq = 1,
  String previousEventHash = genesisEventHash,
}) => HoldemEventCursor(
  protocolVersion: '1.0.0',
  tableId: 'table_001',
  sessionId: 'session_001',
  nextEventSeq: nextEventSeq,
  previousEventHash: previousEventHash,
  actorRef: 'peer_local',
  eventIdFactory: _eventId,
  emittedAtFactory: _eventTimestamp,
);

EventEnvelope _event({String eventType = 'HoldemActionApplied'}) {
  final event = EventEnvelope(
      eventId: 'evt_1',
      eventType: eventType,
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
      eventHash: '',
    );
  return EventEnvelope.fromJson(<String, Object?>{
    ...event.toJson(),
    'event_hash': computeCanonicalEventHash(event),
  });
}

String _eventId(String eventType, int eventSeq) => 'evt_${eventType}_$eventSeq';

String _eventTimestamp() => '2026-08-11T00:00:00Z';

RecoveryPersistenceScope _scope() => const RecoveryPersistenceScope(
  tableId: 'table_001',
  sessionId: 'session_001',
  protocolVersion: '1.0.0',
);

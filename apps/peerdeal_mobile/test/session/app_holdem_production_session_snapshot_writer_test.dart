import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_snapshot_writer.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('writes a typed snapshot with a canonical payload hash', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshot();
    final result = AppHoldemProductionSessionSnapshotWriter(store: store).save(
      snapshotId: 'snapshot_001',
      tableState: state.tableState,
      handState: state.handState,
      eventCursor: state.eventCursor,
    );

    expect(result.isSuccess, isTrue);
    final envelope = store.loadWindow(_scope()).snapshot;
    expect(envelope, isNotNull);
    expect(envelope!.snapshotType, 'HoldemStateSnapshot');
    expect(envelope.snapshotBaseEventSeq, 0);
    expect(envelope.snapshotHash, computeCanonicalHash(envelope.payload));
    expect(envelope.payload, state.toJson());
  });

  test('rejects a state and cursor sequence mismatch before writing', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshot();
    final result = AppHoldemProductionSessionSnapshotWriter(store: store).save(
      snapshotId: 'snapshot_001',
      tableState: state.tableState.copyWith(eventSequence: 1),
      handState: state.handState,
      eventCursor: state.eventCursor,
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.warnings,
      contains('Holdem snapshot state and cursor sequence differ.'),
    );
    expect(store.loadWindow(_scope()).snapshot, isNull);
  });

  test('rejects an inconsistent last-event hash before writing', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshot();
    final result = AppHoldemProductionSessionSnapshotWriter(store: store).save(
      snapshotId: 'snapshot_001',
      tableState: state.tableState.copyWith(
        metadata: const <String, Object?>{'last_event_hash': 'tampered'},
      ),
      handState: state.handState,
      eventCursor: state.eventCursor,
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.warnings,
      contains('Holdem snapshot event hash is inconsistent.'),
    );
    expect(store.loadWindow(_scope()).snapshot, isNull);
  });

  test('rejects unsafe snapshot identity before writing', () {
    final store = InMemoryRecoveryPersistenceStore();
    final state = _typedSnapshot();
    final result = AppHoldemProductionSessionSnapshotWriter(store: store).save(
      snapshotId: ' snapshot_001',
      tableState: state.tableState,
      handState: state.handState,
      eventCursor: state.eventCursor,
    );

    expect(result.isSuccess, isFalse);
    expect(result.warnings, contains('Holdem snapshot identity is invalid.'));
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

String _eventId(String eventType, int eventSeq) => 'evt_${eventType}_$eventSeq';

String _eventTimestamp() => '2026-08-11T00:00:00Z';

RecoveryPersistenceScope _scope() => const RecoveryPersistenceScope(
  tableId: 'table_001',
  sessionId: 'session_001',
  protocolVersion: '1.0.0',
);

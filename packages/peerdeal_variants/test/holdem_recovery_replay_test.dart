import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const adapter = HoldemCoreProjectionAdapter();

  test('replays a valid generic suffix through core and cursor state', () {
    final core = TableState.initial(
      tableId: 'table_001',
      sessionId: 'session_001',
      protocolVersion: '1.0.0',
    );
    final cursor = _cursor();
    final issued = cursor.issue(
      eventType: 'OpenTableSessionOpened',
      eventId: 'evt_open_001',
      emittedAt: '2026-08-10T00:00:01Z',
      actorRef: 'system',
      payload: const <String, Object?>{'mode_type': 'open_table'},
    );

    final result = adapter.replay(
      coreState: core,
      handState: _idleHand(),
      cursor: cursor,
      events: <EventEnvelope>[issued.event],
    );

    expect(result.isApplied, isTrue);
    expect(result.appliedEventCount, 1);
    expect(result.coreState.phase, TablePhase.openReady);
    expect(result.coreState.eventSequence, 1);
    expect(result.handState, _idleHand());
    expect(result.cursor.nextEventSeq, 2);
    expect(result.cursor.previousEventHash, issued.event.eventHash);
  });

  test('rejects a tampered suffix atomically', () {
    final core = TableState.initial(
      tableId: 'table_001',
      sessionId: 'session_001',
      protocolVersion: '1.0.0',
    );
    final hand = _idleHand();
    final cursor = _cursor();
    final issued = cursor.issue(
      eventType: 'OpenTableSessionOpened',
      eventId: 'evt_open_001',
      emittedAt: '2026-08-10T00:00:01Z',
      actorRef: 'system',
      payload: const <String, Object?>{'mode_type': 'open_table'},
    );
    final tampered = EventEnvelope(
      eventId: issued.event.eventId,
      eventType: issued.event.eventType,
      eventVersion: issued.event.eventVersion,
      protocolVersion: issued.event.protocolVersion,
      eventSeq: issued.event.eventSeq,
      tableId: issued.event.tableId,
      sessionId: issued.event.sessionId,
      handId: issued.event.handId,
      emittedAt: issued.event.emittedAt,
      actorRef: issued.event.actorRef,
      payload: issued.event.payload,
      prevEventHash: issued.event.prevEventHash,
      eventHash: 'tampered',
    );

    final result = adapter.replay(
      coreState: core,
      handState: hand,
      cursor: cursor,
      events: <EventEnvelope>[tampered],
    );

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_EVENT_CURSOR_HASH_INVALID');
    expect(result.appliedEventCount, 0);
    expect(result.coreState, same(core));
    expect(result.handState, same(hand));
    expect(result.cursor, same(cursor));
  });
}

HoldemEventCursor _cursor() => HoldemEventCursor(
  protocolVersion: '1.0.0',
  tableId: 'table_001',
  sessionId: 'session_001',
  nextEventSeq: 1,
  previousEventHash: genesisEventHash,
  actorRef: 'peer_local',
  eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
  emittedAtFactory: () => '2026-08-10T00:00:00Z',
);

HoldemHandState _idleHand() => const HoldemHandState(
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

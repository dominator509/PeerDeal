import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const adapter = HoldemCoreProjectionAdapter();
  const reducer = HoldemEventReducer();

  test('accepts adapter events only when the remote cursor chain is exact', () {
    final started = adapter.startHand(
      coreState: _openCoreState(),
      handState: _preflopState(),
      cursor: _cursor(),
    );
    final event = started.events.single;

    final accepted = _cursor().accept(event);
    expect(accepted.isAccepted, isTrue);
    expect(accepted.cursor.nextEventSeq, 3);
    expect(accepted.cursor.previousEventHash, event.eventHash);

    final tampered = EventEnvelope(
      eventId: event.eventId,
      eventType: event.eventType,
      eventVersion: event.eventVersion,
      protocolVersion: event.protocolVersion,
      eventSeq: event.eventSeq,
      tableId: event.tableId,
      sessionId: event.sessionId,
      handId: event.handId,
      emittedAt: event.emittedAt,
      actorRef: event.actorRef,
      payload: event.payload,
      prevEventHash: event.prevEventHash,
      eventHash: 'tampered_hash',
    );
    final rejected = _cursor().accept(tampered);
    expect(rejected.isRejected, isTrue);
    expect(rejected.reasonCode, 'ERR_HOLDEM_EVENT_CURSOR_HASH_INVALID');
    expect(rejected.cursor.nextEventSeq, 2);
  });

  test('reconstructs an adapter-produced action projection', () {
    final initial = _preflopState();
    final started = adapter.startHand(
      coreState: _openCoreState(),
      handState: initial,
      cursor: _cursor(),
    );
    final action = adapter.applyAction(
      coreState: started.coreState,
      handState: started.handState,
      cursor: started.cursor,
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
      dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
      openNextBettingRound: true,
    );

    var remoteState = initial;
    var remoteCursor = _cursor();
    for (final event in <EventEnvelope>[...started.events, ...action.events]) {
      final cursorResult = remoteCursor.accept(event);
      expect(cursorResult.isAccepted, isTrue);
      final reduction = reducer.apply(state: remoteState, event: event);
      expect(reduction.isApplied, isTrue, reason: reduction.reasonCode);
      remoteState = reduction.state;
      remoteCursor = cursorResult.cursor;
    }

    _expectSameHandState(remoteState, action.handState);
    expect(remoteCursor.nextEventSeq, action.cursor.nextEventSeq);
    expect(remoteCursor.previousEventHash, action.cursor.previousEventHash);
  });

  test('reconstructs public showdown and settlement lifecycle', () {
    final initial = _showdownState();
    final started = adapter.startHand(
      coreState: _openCoreState(),
      handState: initial,
      cursor: _cursor(),
    );
    final revealed = adapter.revealShowdown(
      coreState: started.coreState,
      handState: started.handState,
      cursor: started.cursor,
      input: _showdownInput,
    );
    final revealResult = revealed.showdownResult!;
    const coordinator = HoldemShowdownCoordinator();
    final prepared = coordinator.prepareSettlement(
      state: revealed.handState,
      evaluation: revealResult.evaluation,
    );
    final settlement = coordinator.projectSettlement(
      state: prepared.state,
      evaluation: prepared.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'seat-2',
          committed: 100,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );
    final completion = coordinator.completeHand(
      state: prepared.state,
      settlement: settlement,
    );
    final settled = adapter.projectSettlement(
      coreState: revealed.coreState,
      handState: prepared.state,
      settlement: settlement,
      completion: completion,
      cursor: revealed.cursor,
      projectionId: 'projection_001',
      settlementId: 'settlement_001',
    );

    var remoteState = initial;
    var remoteCursor = _cursor();
    final events = <EventEnvelope>[...started.events, ...revealed.events];
    events.addAll(settled.events);
    for (final event in events) {
      final cursorResult = remoteCursor.accept(event);
      expect(cursorResult.isAccepted, isTrue);
      final reduction = reducer.apply(state: remoteState, event: event);
      expect(reduction.isApplied, isTrue, reason: reduction.reasonCode);
      remoteState = reduction.state;
      remoteCursor = cursorResult.cursor;
    }

    expect(remoteState.phase, HoldemHandPhase.handComplete);
    expect(remoteState.boardCards, initial.boardCards);
    expect(remoteCursor.nextEventSeq, settled.cursor.nextEventSeq);
  });

  test('rejects malformed projections without mutating the input state', () {
    final initial = _preflopState();
    final started = adapter.startHand(
      coreState: _openCoreState(),
      handState: initial,
      cursor: _cursor(),
    );
    final action = adapter.applyAction(
      coreState: started.coreState,
      handState: started.handState,
      cursor: started.cursor,
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
      dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
      openNextBettingRound: true,
    );
    final event = action.events.single;
    final malformed = EventEnvelope(
      eventId: event.eventId,
      eventType: event.eventType,
      eventVersion: event.eventVersion,
      protocolVersion: event.protocolVersion,
      eventSeq: event.eventSeq,
      tableId: event.tableId,
      sessionId: event.sessionId,
      handId: event.handId,
      emittedAt: event.emittedAt,
      actorRef: event.actorRef,
      payload: <String, Object?>{...event.payload, 'pot': 999999},
      prevEventHash: event.prevEventHash,
      eventHash: event.eventHash,
    );

    final result = reducer.apply(state: initial, event: malformed);
    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_ACTION_PROJECTION_MISMATCH');
    expect(result.state, same(initial));
  });
}

void _expectSameHandState(HoldemHandState actual, HoldemHandState expected) {
  expect(actual.handId, expected.handId);
  expect(actual.phase, expected.phase);
  expect(actual.bettingRound, expected.bettingRound);
  expect(actual.currentActorSeat, expected.currentActorSeat);
  expect(actual.currentBetToCall, expected.currentBetToCall);
  expect(actual.minimumRaiseAmount, expected.minimumRaiseAmount);
  expect(actual.boardCards, expected.boardCards);
  expect(actual.actedSeatsThisRound, expected.actedSeatsThisRound);
  expect(actual.pot, expected.pot);
  expect(actual.lastAggressorSeat, expected.lastAggressorSeat);
  expect(actual.lastActionSummary, expected.lastActionSummary);
  expect(actual.seats.length, expected.seats.length);
  for (var index = 0; index < actual.seats.length; index += 1) {
    final actualSeat = actual.seats[index];
    final expectedSeat = expected.seats[index];
    expect(actualSeat.seat, expectedSeat.seat);
    expect(actualSeat.stack, expectedSeat.stack);
    expect(actualSeat.inHand, expectedSeat.inHand);
    expect(actualSeat.folded, expectedSeat.folded);
    expect(actualSeat.allIn, expectedSeat.allIn);
    expect(actualSeat.committedThisRound, expectedSeat.committedThisRound);
    expect(actualSeat.committedThisHand, expectedSeat.committedThisHand);
  }
}

TableState _openCoreState() {
  return const CoreReducer().apply(
    TableState.initial(
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      protocolVersion: '1.0.0',
    ),
    const EventEnvelope(
      eventId: 'evt_open',
      eventType: 'OpenTableSessionOpened',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 1,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: null,
      emittedAt: '2026-08-10T00:00:00Z',
      actorRef: 'system',
      payload: <String, Object?>{'mode_type': 'cash'},
      prevEventHash: genesisEventHash,
      eventHash: 'hash_open',
    ),
  );
}

HoldemEventCursor _cursor() {
  return HoldemEventCursor(
    protocolVersion: '1.0.0',
    tableId: 'tbl_001',
    sessionId: 'sess_001',
    nextEventSeq: 2,
    previousEventHash: 'hash_open',
    actorRef: 'system',
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-10T00:00:01Z',
  );
}

HoldemHandState _preflopState() {
  return HoldemHandState(
    handId: 'hand_001',
    phase: HoldemHandPhase.bettingPreflop,
    bettingRound: HoldemBettingRound.preflop,
    currentActorSeat: 1,
    buttonSeat: 1,
    smallBlindSeat: 2,
    bigBlindSeat: 3,
    currentBetToCall: 100,
    minimumRaiseAmount: 100,
    pot: 200,
    seats: <HoldemSeatState>[
      HoldemSeatState(
        seat: 1,
        stack: 1000,
        inHand: true,
        folded: false,
        allIn: false,
      ),
      HoldemSeatState(
        seat: 2,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisRound: 100,
        committedThisHand: 100,
      ),
      HoldemSeatState(
        seat: 3,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisRound: 100,
        committedThisHand: 100,
      ),
    ],
  );
}

HoldemHandState _showdownState() {
  return HoldemHandState(
    handId: 'hand_001',
    phase: HoldemHandPhase.showdownPrep,
    bettingRound: HoldemBettingRound.river,
    currentActorSeat: 1,
    buttonSeat: 1,
    smallBlindSeat: 2,
    bigBlindSeat: 3,
    currentBetToCall: 0,
    minimumRaiseAmount: 100,
    pot: 200,
    boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
    seats: <HoldemSeatState>[
      HoldemSeatState(
        seat: 1,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisHand: 100,
      ),
      HoldemSeatState(
        seat: 2,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisHand: 100,
      ),
    ],
  );
}

final _showdownInput = ShowdownEvaluationInput(
  boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
  seats: <ShowdownSeatInput>[
    ShowdownSeatInput(
      seat: 1,
      holeCards: <String>['8h', '9d'],
      isFolded: false,
    ),
    ShowdownSeatInput(
      seat: 2,
      holeCards: <String>['Ac', '3c'],
      isFolded: false,
    ),
  ],
);

int? _seatFromSeatId(String seatId) => int.tryParse(seatId.split('-').last);

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

  test('rejects a remote raise when a short all-in did not reopen action', () {
    final initial = _preflopState().copyWith(
      currentActorSeat: 2,
      currentBetToCall: 125,
      actedSeatsThisRound: const <int>[2, 3],
      seats: const <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 0,
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
          stack: 0,
          inHand: true,
          folded: false,
          allIn: true,
          committedThisRound: 125,
          committedThisHand: 125,
        ),
      ],
    );
    final event = EventEnvelope(
      eventId: 'evt_raise_after_short_all_in',
      eventType: 'PlayerRaised',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 3,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: 'hand_001',
      emittedAt: '2026-08-10T00:00:03Z',
      actorRef: 'peer_local',
      payload: const <String, Object?>{
        'variant_id': holdemNlheVariantId,
        'action_type': 'raise',
        'actor_seat': 2,
        'amount': 225,
        'contribution': 125,
        'dealt_board_cards': <Object?>[],
        'board_cards': <Object?>[],
        'phase': 'bettingPreflop',
        'betting_round': 'preflop',
        'pot': 325,
        'current_bet_to_call': 225,
        'minimum_raise_amount': 100,
      },
      prevEventHash: 'hash_short_all_in',
      eventHash: 'hash_raise_after_short_all_in',
    );

    final result = reducer.apply(state: initial, event: event);

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_RAISE_NOT_REOPENED');
    expect(result.state, same(initial));
  });

  test('rejects settlement awards that do not conserve the current pot', () {
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
    const coordinator = HoldemShowdownCoordinator();
    final prepared = coordinator.prepareSettlement(
      state: revealed.handState,
      evaluation: revealed.showdownResult!.evaluation,
    );
    final invalid = EventEnvelope(
      eventId: 'evt_invalid_settlement',
      eventType: 'SettlementProjected',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 5,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: 'hand_001',
      emittedAt: '2026-08-10T00:00:05Z',
      actorRef: 'system',
      payload: const <String, Object?>{
        'variant_id': holdemNlheVariantId,
        'projection_id': 'projection_invalid',
        'awards': <Object?>[
          <String, Object?>{'seat_id': 'seat-1', 'amount': 199},
        ],
      },
      prevEventHash: 'hash_invalid',
      eventHash: 'hash_invalid_settlement',
    );

    final result = reducer.apply(state: prepared.state, event: invalid);

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_SETTLEMENT_AWARDS_POT_MISMATCH');
    expect(result.state, same(prepared.state));
  });

  test('rejects control-bearing showdown summaries without mutating state', () {
    final initial = _showdownState();
    final event = EventEnvelope(
      eventId: 'evt_unsafe_showdown',
      eventType: 'ShowdownRevealed',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 3,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: 'hand_001',
      emittedAt: '2026-08-10T00:00:03Z',
      actorRef: 'system',
      payload: const <String, Object?>{
        'variant_id': holdemNlheVariantId,
        'results': <Object?>[
          <String, Object?>{
            'seat': 1,
            'rank_index': 0,
            'summary': 'winner\u0001',
          },
        ],
      },
      prevEventHash: 'hash_showdown',
      eventHash: 'hash_unsafe_showdown',
    );

    final result = reducer.apply(state: initial, event: event);

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_SHOWDOWN_RESULTS_INVALID');
    expect(result.state, same(initial));
  });

  test('rejects control-bearing board and award identities', () {
    final initial = _showdownState();
    final unsafeBoardEvent = EventEnvelope(
      eventId: 'evt_unsafe_board',
      eventType: 'ShowdownStarted',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 2,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: 'hand_001',
      emittedAt: '2026-08-10T00:00:02Z',
      actorRef: 'system',
      payload: const <String, Object?>{
        'variant_id': holdemNlheVariantId,
        'board_cards': <Object?>['Ah', 'Kd', 'Q\u0085s', 'Jc', '2h'],
      },
      prevEventHash: 'hash_showdown_start',
      eventHash: 'hash_unsafe_board',
    );
    final unsafeAwardEvent = EventEnvelope(
      eventId: 'evt_unsafe_award',
      eventType: 'SettlementProjected',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 5,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: 'hand_001',
      emittedAt: '2026-08-10T00:00:05Z',
      actorRef: 'system',
      payload: const <String, Object?>{
        'variant_id': holdemNlheVariantId,
        'projection_id': 'projection_001',
        'awards': <Object?>[
          <String, Object?>{'seat_id': 'seat-1\u0001', 'amount': 200},
        ],
      },
      prevEventHash: 'hash_settlement',
      eventHash: 'hash_unsafe_award',
    );

    final boardResult = reducer.apply(state: initial, event: unsafeBoardEvent);
    final awardResult = reducer.apply(state: initial, event: unsafeAwardEvent);

    expect(boardResult.isRejected, isTrue);
    expect(boardResult.reasonCode, 'ERR_HOLDEM_EVENT_PAYLOAD_INVALID');
    expect(boardResult.state, same(initial));
    expect(awardResult.isRejected, isTrue);
    expect(awardResult.reasonCode, 'ERR_HOLDEM_SETTLEMENT_AWARDS_INVALID');
    expect(awardResult.state, same(initial));
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
    EventEnvelope(
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
    actedSeatsThisRound: <int>[2, 3],
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

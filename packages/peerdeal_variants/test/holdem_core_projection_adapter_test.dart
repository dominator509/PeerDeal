import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

String _acceptFixtureEventHash(EventEnvelope event) => event.eventHash;

void main() {
  const adapter = HoldemCoreProjectionAdapter();
  const showdownCoordinator = HoldemShowdownCoordinator();

  test('cursor rejects oversized and C1 identity text', () {
    final oversizedIdentity = String.fromCharCodes(
      List<int>.filled(HoldemInputLimits.defaultMaxTextBytes + 1, 0x78),
    );

    for (final value in <String>[
      oversizedIdentity,
      'actor_1\u0085',
      String.fromCharCode(0xd800),
    ]) {
      expect(
        () => HoldemEventCursor(
          protocolVersion: '1.0.0',
          tableId: 'table_001',
          sessionId: 'session_001',
          nextEventSeq: 1,
          previousEventHash: 'GENESIS',
          actorRef: value,
          lastEventType: 'HandStarted',
          eventIdFactory: (eventType, eventSeq) => 'event_$eventSeq',
          emittedAtFactory: () => '2026-08-18T00:00:00Z',
        ),
        throwsA(isA<ArgumentError>()),
      );
    }

    expect(
      () => HoldemEventCursor(
        protocolVersion: '1.0.0',
        tableId: 'table_001',
        sessionId: 'session_001',
        nextEventSeq: 1,
        previousEventHash: 'GENESIS',
        actorRef: 'actor_1',
        lastEventType: 'HandStarted\u0085',
        eventIdFactory: (eventType, eventSeq) => 'event_$eventSeq',
        emittedAtFactory: () => '2026-08-18T00:00:00Z',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects invalid hand state before core projection', () {
    final initial = _preflopState();
    final result = adapter.startHand(
      coreState: _openCoreState(),
      handState: initial.copyWith(pot: -1),
      cursor: _cursor(),
    );

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_STATE_INVALID');
    expect(result.events, isEmpty);
  });

  test('rejects invalid hand state before empty recovery replay', () {
    final initial = _preflopState();
    final result = adapter.replay(
      coreState: _openCoreState(),
      handState: initial.copyWith(pot: -1),
      cursor: _cursor(),
      events: const <EventEnvelope>[],
    );

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_STATE_INVALID');
    expect(result.appliedEventCount, 0);
  });

  test('rejects invalid coordinator output before event emission', () {
    const adapter = HoldemCoreProjectionAdapter(
      actionStreetCoordinator: _InvalidStateActionStreetCoordinator(),
    );
    final core = _openCoreState();
    final hand = _preflopState();
    final cursor = _cursor();

    final result = adapter.applyAction(
      coreState: core,
      handState: hand,
      cursor: cursor,
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
    );

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_STATE_INVALID');
    expect(result.events, isEmpty);
    expect(result.coreState, same(core));
    expect(result.handState, same(hand));
    expect(result.cursor, same(cursor));
  });

  test('rejects invalid showdown output before event emission', () {
    const adapter = HoldemCoreProjectionAdapter(
      showdownCoordinator: _InvalidStateShowdownCoordinator(),
    );
    final core = _openCoreState();
    final hand = _showdownState();
    final cursor = _cursor();

    final result = adapter.revealShowdown(
      coreState: core,
      handState: hand,
      cursor: cursor,
      input: _showdownInput,
    );

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_STATE_INVALID');
    expect(result.events, isEmpty);
    expect(result.coreState, same(core));
    expect(result.handState, same(hand));
    expect(result.cursor, same(cursor));
  });

  test('rejects invalid settlement output before event emission', () {
    const adapter = HoldemCoreProjectionAdapter();
    final hand = _showdownState();
    final invalidState = hand.copyWith(pot: -1);
    final evaluation = ShowdownEvaluationResult(
      results: const <RankedShowdownResult>[],
    );
    final settlement = HoldemSettlementProjectionGateResult(
      isProjected: false,
      state: invalidState,
      evaluation: evaluation,
      projection: null,
    );
    final completion = HoldemHandCompletionGateResult(
      isCompleted: false,
      state: invalidState,
      projection: null,
    );
    final core = _openCoreState();
    final cursor = _cursor();

    final result = adapter.projectSettlement(
      coreState: core,
      handState: hand,
      settlement: settlement,
      completion: completion,
      cursor: cursor,
      projectionId: 'projection_001',
      settlementId: 'settlement_001',
    );

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_STATE_INVALID');
    expect(result.events, isEmpty);
    expect(result.coreState, same(core));
    expect(result.handState, same(hand));
    expect(result.cursor, same(cursor));
  });

  test('rejects invalid reducer output during recovery replay', () {
    const adapter = HoldemCoreProjectionAdapter();
    final started = adapter.startHand(
      coreState: _openCoreState(),
      handState: _preflopState(),
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
    );

    final result = adapter.replay(
      coreState: started.coreState,
      handState: started.handState,
      cursor: started.cursor,
      events: action.events,
      eventReducer: const HoldemEventReducer(
        actionStreetCoordinator: _InvalidStateActionStreetCoordinator(),
      ),
    );

    expect(action.isApplied, isTrue);
    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_HOLDEM_STATE_INVALID');
    expect(result.appliedEventCount, 0);
    expect(result.coreState, same(started.coreState));
    expect(result.handState, same(started.handState));
    expect(result.cursor, same(started.cursor));
  });

  test('projects an accepted Holdem action through the core reducer', () {
    final core = _openCoreState();
    final hand = _preflopState();
    final started = adapter.startHand(
      coreState: core,
      handState: hand,
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

    expect(started.isApplied, isTrue);
    expect(action.isApplied, isTrue);
    expect(action.events.map((event) => event.eventType), <String>[
      'PlayerCalled',
    ]);
    expect(action.handState.phase, HoldemHandPhase.bettingFlop);
    expect(action.coreState.eventSequence, 3);
    expect(action.coreState.activeHandId, 'hand_001');
    expect(action.events.single.payload['contribution'], 100);
    expect(action.events.single.eventHash.length, 64);
    expect(action.cursor.nextEventSeq, 4);
    expect(
      action.coreState.metadata['last_event_hash'],
      action.events.single.eventHash,
    );
  });

  test('emits showdown start when the lifecycle reaches showdown prep', () {
    final started = adapter.startHand(
      coreState: _openCoreState(),
      handState: _riverState(),
      cursor: _cursor(),
    );

    final action = adapter.applyAction(
      coreState: started.coreState,
      handState: started.handState.copyWith(
        phase: HoldemHandPhase.bettingRiver,
        bettingRound: HoldemBettingRound.river,
        boardCards: const <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
      ),
      cursor: started.cursor,
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
    );

    expect(action.isApplied, isTrue);
    expect(action.events.map((event) => event.eventType), <String>[
      'PlayerCalled',
      'ShowdownStarted',
    ]);
    expect(action.handState.phase, HoldemHandPhase.showdownPrep);
    expect(action.coreState.eventSequence, 4);
    expect(action.events.last.payload['board_cards'], <String>[
      'Ah',
      'Kd',
      'Qs',
      'Jc',
      '2h',
    ]);
  });

  test('rejects invalid actions without mutating core, variant, or cursor', () {
    final started = adapter.startHand(
      coreState: _openCoreState(),
      handState: _preflopState(),
      cursor: _cursor(),
    );

    final rejected = adapter.applyAction(
      coreState: started.coreState,
      handState: started.handState,
      cursor: started.cursor,
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.check,
      ),
    );

    expect(rejected.isRejected, isTrue);
    expect(rejected.reasonCode, 'ERR_OUT_OF_TURN');
    expect(rejected.events, isEmpty);
    expect(rejected.coreState, same(started.coreState));
    expect(rejected.handState, same(started.handState));
    expect(rejected.cursor, same(started.cursor));
  });

  test(
    'rolls back variant output and cursor when core projection rejects it',
    () {
      final core = _openCoreState();
      final hand = _preflopState();
      final cursor = _cursor();

      final rejected = adapter.applyAction(
        coreState: core,
        handState: hand,
        cursor: cursor,
        action: const HoldemTableAction(
          actorSeat: 1,
          type: HoldemTableActionType.call,
        ),
        dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
      );

      expect(rejected.isRejected, isTrue);
      expect(rejected.reasonCode, 'ERR_HAND_EVENT_WITHOUT_ACTIVE_HAND');
      expect(rejected.events, isEmpty);
      expect(rejected.coreState, same(core));
      expect(rejected.handState, same(hand));
      expect(rejected.cursor, same(cursor));
    },
  );

  test(
    'projects showdown and successful settlement as one core-compatible chain',
    () {
      final started = adapter.startHand(
        coreState: _openCoreState(),
        handState: _showdownState(),
        cursor: _cursor(),
      );
      final revealed = adapter.revealShowdown(
        coreState: started.coreState,
        handState: started.handState,
        cursor: started.cursor,
        input: _showdownInput,
      );

      final revealResult = revealed.showdownResult!;
      final prepared = showdownCoordinator.prepareSettlement(
        state: revealed.handState,
        evaluation: revealResult.evaluation,
      );
      final settlement = showdownCoordinator.projectSettlement(
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
      final completion = showdownCoordinator.completeHand(
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

      expect(revealed.isApplied, isTrue);
      expect(revealed.events.map((event) => event.eventType), <String>[
        'ShowdownStarted',
        'ShowdownRevealed',
      ]);
      expect(settlement.isProjected, isTrue);
      expect(completion.isCompleted, isTrue);
      expect(settled.isApplied, isTrue);
      expect(settled.events.map((event) => event.eventType), <String>[
        'SettlementProjected',
        'HandSettled',
      ]);
      expect(settled.handState.phase, HoldemHandPhase.handComplete);
      expect(settled.coreState.activeHandId, isNull);
      expect(settled.coreState.eventSequence, 6);
      expect(settled.cursor.nextEventSeq, 7);
      expect(settled.events[1].prevEventHash, settled.events[0].eventHash);
    },
  );
}

TableState _openCoreState() {
  return CoreReducer(
    eventHashCalculator: _acceptFixtureEventHash,
  ).apply(
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

HoldemHandState _riverState() {
  return _preflopState().copyWith(
    phase: HoldemHandPhase.bettingRiver,
    bettingRound: HoldemBettingRound.river,
    boardCards: const <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
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

int? _seatFromSeatId(String seatId) {
  return int.tryParse(seatId.split('-').last);
}

class _InvalidStateActionStreetCoordinator
    extends HoldemActionStreetCoordinator {
  const _InvalidStateActionStreetCoordinator();

  @override
  HoldemActionStreetResult applyAndAdvanceIfComplete({
    required HoldemHandState state,
    required HoldemTableAction action,
    List<String> dealtBoardCards = const <String>[],
    bool openNextBettingRound = false,
  }) {
    final result = super.applyAndAdvanceIfComplete(
      state: state,
      action: action,
      dealtBoardCards: dealtBoardCards,
      openNextBettingRound: openNextBettingRound,
    );
    return HoldemActionStreetResult(
      action: result.action,
      street: result.street,
      bettingRound: result.bettingRound,
      uncontestedSettlement: result.uncontestedSettlement,
      state: result.state.copyWith(
        seats: <HoldemSeatState>[
          ...result.state.seats,
          result.state.seats.first,
        ],
      ),
    );
  }
}

class _InvalidStateShowdownCoordinator extends HoldemShowdownCoordinator {
  const _InvalidStateShowdownCoordinator();

  @override
  HoldemShowdownRevealResult reveal({
    required HoldemHandState state,
    required ShowdownEvaluationInput input,
  }) {
    final result = super.reveal(state: state, input: input);
    return HoldemShowdownRevealResult(
      isRevealed: result.isRevealed,
      state: result.state.copyWith(pot: -1),
      evaluation: result.evaluation,
      warnings: result.warnings,
    );
  }
}

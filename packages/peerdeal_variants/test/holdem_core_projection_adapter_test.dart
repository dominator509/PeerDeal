import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const adapter = HoldemCoreProjectionAdapter();
  const showdownCoordinator = HoldemShowdownCoordinator();

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

import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const machine = HoldemStateMachine();

  test('allows canonical preflop to flop transition', () {
    final result = machine.canTransition(
      from: HoldemHandPhase.bettingPreflop,
      to: HoldemHandPhase.dealingFlop,
    );

    expect(result.isAllowed, isTrue);
  });

  test('rejects illegal early showdown transition', () {
    final result = machine.canTransition(
      from: HoldemHandPhase.blindsPosting,
      to: HoldemHandPhase.showdownPrep,
    );

    expect(result.isAllowed, isFalse);
  });

  test('opening flop resets round-local betting state', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingPreflop,
      bettingRound: HoldemBettingRound.preflop,
      currentActorSeat: 2,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 100,
      minimumRaiseAmount: 100,
      seats: <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 100,
          committedThisHand: 100,
        ),
        HoldemSeatState(
          seat: 2,
          stack: 950,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 50,
          committedThisHand: 50,
        ),
      ],
    );

    final result = machine.advanceAfterBettingRound(
      state: state,
      dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
    );
    final next = result.state;

    expect(result.isAdvanced, isTrue);
    expect(result.warnings, isEmpty);
    expect(next.phase, HoldemHandPhase.dealingFlop);
    expect(next.bettingRound, HoldemBettingRound.flop);
    expect(next.currentBetToCall, 0);
    expect(next.boardCards, <String>['Ah', 'Kd', '2c']);
    expect(next.seats.map((seat) => seat.committedThisRound), everyElement(0));
    expect(next.seats.map((seat) => seat.committedThisHand), <int>[100, 50]);
  });

  test('opening turn resets round-local betting state', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingFlop,
      bettingRound: HoldemBettingRound.flop,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 300,
      minimumRaiseAmount: 200,
      boardCards: <String>['Ah', 'Kd', '2c'],
      seats: <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 700,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 200,
          committedThisHand: 300,
        ),
        HoldemSeatState(
          seat: 2,
          stack: 650,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 300,
          committedThisHand: 350,
        ),
      ],
    );

    final result = machine.advanceAfterBettingRound(
      state: state,
      dealtBoardCards: const <String>['Jc'],
    );
    final next = result.state;

    expect(result.isAdvanced, isTrue);
    expect(result.warnings, isEmpty);
    expect(next.phase, HoldemHandPhase.dealingTurn);
    expect(next.bettingRound, HoldemBettingRound.turn);
    expect(next.currentBetToCall, 0);
    expect(next.boardCards, <String>['Ah', 'Kd', '2c', 'Jc']);
    expect(next.seats.map((seat) => seat.committedThisRound), everyElement(0));
    expect(next.seats.map((seat) => seat.committedThisHand), <int>[300, 350]);
  });

  test('opening river resets round-local betting state', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingTurn,
      bettingRound: HoldemBettingRound.turn,
      currentActorSeat: 2,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 500,
      minimumRaiseAmount: 200,
      boardCards: <String>['Ah', 'Kd', '2c', 'Jc'],
      seats: <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 500,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 500,
          committedThisHand: 800,
        ),
        HoldemSeatState(
          seat: 2,
          stack: 650,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 300,
          committedThisHand: 650,
        ),
      ],
    );

    final result = machine.advanceAfterBettingRound(
      state: state,
      dealtBoardCards: const <String>['7s'],
    );
    final next = result.state;

    expect(result.isAdvanced, isTrue);
    expect(result.warnings, isEmpty);
    expect(next.phase, HoldemHandPhase.dealingRiver);
    expect(next.bettingRound, HoldemBettingRound.river);
    expect(next.currentBetToCall, 0);
    expect(next.boardCards, <String>['Ah', 'Kd', '2c', 'Jc', '7s']);
    expect(next.seats.map((seat) => seat.committedThisRound), everyElement(0));
    expect(next.seats.map((seat) => seat.committedThisHand), <int>[800, 650]);
  });

  test('advancing river to showdown prep requires no new board cards', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingRiver,
      bettingRound: HoldemBettingRound.river,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 500,
      minimumRaiseAmount: 200,
      boardCards: <String>['Ah', 'Kd', '2c', 'Jc', '7s'],
      seats: <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 500,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 500,
          committedThisHand: 800,
        ),
        HoldemSeatState(
          seat: 2,
          stack: 650,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 500,
          committedThisHand: 850,
        ),
      ],
    );

    final result = machine.advanceAfterBettingRound(
      state: state,
      dealtBoardCards: const <String>[],
    );

    expect(result.isAdvanced, isTrue);
    expect(result.state.phase, HoldemHandPhase.showdownPrep);
    expect(result.state.boardCards, state.boardCards);
    expect(
      result.state.seats.map((seat) => seat.committedThisRound),
      everyElement(0),
    );
  });

  test('opens flop betting round from dealt flop', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.dealingFlop,
      bettingRound: HoldemBettingRound.flop,
      currentActorSeat: 3,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 0,
      minimumRaiseAmount: 100,
      boardCards: <String>['Ah', 'Kd', '2c'],
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
          stack: 950,
          inHand: true,
          folded: false,
          allIn: false,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 900,
          inHand: true,
          folded: false,
          allIn: false,
        ),
      ],
    );

    final result = machine.openBettingRoundAfterDeal(state: state);

    expect(result.isOpened, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.state.phase, HoldemHandPhase.bettingFlop);
    expect(result.state.bettingRound, HoldemBettingRound.flop);
    expect(result.state.currentActorSeat, 2);
    expect(result.state.currentBetToCall, 0);
    expect(result.state.boardCards, state.boardCards);
  });

  test('opens turn and river betting rounds from dealt board state', () {
    final turnState = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.dealingTurn,
      bettingRound: HoldemBettingRound.turn,
      currentActorSeat: 3,
      buttonSeat: 2,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 0,
      minimumRaiseAmount: 100,
      boardCards: <String>['Ah', 'Kd', '2c', 'Jc'],
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
          stack: 950,
          inHand: true,
          folded: false,
          allIn: false,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 900,
          inHand: true,
          folded: false,
          allIn: false,
        ),
      ],
    );
    final turn = machine.openBettingRoundAfterDeal(state: turnState);

    expect(turn.isOpened, isTrue);
    expect(turn.state.phase, HoldemHandPhase.bettingTurn);
    expect(turn.state.currentActorSeat, 3);

    final riverState = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.dealingRiver,
      bettingRound: HoldemBettingRound.river,
      currentActorSeat: 3,
      buttonSeat: 2,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 0,
      minimumRaiseAmount: 100,
      boardCards: <String>['Ah', 'Kd', '2c', 'Jc', '7s'],
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
          stack: 950,
          inHand: true,
          folded: false,
          allIn: false,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 900,
          inHand: true,
          folded: false,
          allIn: false,
        ),
      ],
    );
    final river = machine.openBettingRoundAfterDeal(state: riverState);

    expect(river.isOpened, isTrue);
    expect(river.state.phase, HoldemHandPhase.bettingRiver);
    expect(river.state.currentActorSeat, 3);
  });

  test('opening betting round skips folded and all-in seats', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.dealingFlop,
      bettingRound: HoldemBettingRound.flop,
      currentActorSeat: 3,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 0,
      minimumRaiseAmount: 100,
      boardCards: <String>['Ah', 'Kd', '2c'],
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
          stack: 950,
          inHand: false,
          folded: true,
          allIn: false,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 0,
          inHand: true,
          folded: false,
          allIn: true,
        ),
        HoldemSeatState(
          seat: 4,
          stack: 900,
          inHand: true,
          folded: false,
          allIn: false,
        ),
      ],
    );

    final result = machine.openBettingRoundAfterDeal(state: state);

    expect(result.isOpened, isTrue);
    expect(result.state.currentActorSeat, 4);
  });

  test('opening betting round fails closed on wrong phase', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingPreflop,
      bettingRound: HoldemBettingRound.preflop,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 0,
      minimumRaiseAmount: 100,
      seats: <HoldemSeatState>[],
    );

    final result = machine.openBettingRoundAfterDeal(state: state);

    expect(result.isOpened, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_BETTING_ROUND_OPEN_PHASE'));
  });

  test('opening betting round fails closed on board count mismatch', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.dealingFlop,
      bettingRound: HoldemBettingRound.flop,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 0,
      minimumRaiseAmount: 100,
      boardCards: <String>['Ah', 'Kd'],
      seats: <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
        ),
      ],
    );

    final result = machine.openBettingRoundAfterDeal(state: state);

    expect(result.isOpened, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_BETTING_ROUND_BOARD_COUNT'));
  });

  test('opening betting round fails closed when no seat can act', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.dealingFlop,
      bettingRound: HoldemBettingRound.flop,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 0,
      minimumRaiseAmount: 100,
      boardCards: <String>['Ah', 'Kd', '2c'],
      seats: <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 0,
          inHand: true,
          folded: false,
          allIn: true,
        ),
        HoldemSeatState(
          seat: 2,
          stack: 0,
          inHand: true,
          folded: false,
          allIn: true,
        ),
      ],
    );

    final result = machine.openBettingRoundAfterDeal(state: state);

    expect(result.isOpened, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_BETTING_ROUND_NO_ACTOR'));
  });

  test('street advance fails closed on wrong board-card count', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingPreflop,
      bettingRound: HoldemBettingRound.preflop,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 100,
      minimumRaiseAmount: 100,
      seats: <HoldemSeatState>[],
    );

    final result = machine.advanceAfterBettingRound(
      state: state,
      dealtBoardCards: const <String>['Ah', 'Kd'],
    );

    expect(result.isAdvanced, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_STREET_CARD_COUNT'));
  });

  test('street advance fails closed on malformed board-card identity', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingPreflop,
      bettingRound: HoldemBettingRound.preflop,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 100,
      minimumRaiseAmount: 100,
      seats: <HoldemSeatState>[],
    );

    final result = machine.advanceAfterBettingRound(
      state: state,
      dealtBoardCards: const <String>['Ah', 'bad', '2c'],
    );

    expect(result.isAdvanced, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_STREET_CARD_FORMAT'));
  });

  test('street advance fails closed on duplicate board-card identity', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingFlop,
      bettingRound: HoldemBettingRound.flop,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 100,
      minimumRaiseAmount: 100,
      boardCards: <String>['Ah', 'Kd', '2c'],
      seats: <HoldemSeatState>[],
    );

    final result = machine.advanceAfterBettingRound(
      state: state,
      dealtBoardCards: const <String>['Ah'],
    );

    expect(result.isAdvanced, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_STREET_DUPLICATE_CARD'));
  });
}

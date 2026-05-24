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
    const state = HoldemHandState(
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
    const state = HoldemHandState(
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
    const state = HoldemHandState(
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
    const state = HoldemHandState(
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

  test('street advance fails closed on wrong board-card count', () {
    const state = HoldemHandState(
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
    const state = HoldemHandState(
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
    const state = HoldemHandState(
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

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

    final next = machine.openNextStreet(state: state);

    expect(next.phase, HoldemHandPhase.dealingFlop);
    expect(next.bettingRound, HoldemBettingRound.flop);
    expect(next.currentBetToCall, 0);
    expect(next.boardCards, <String>['F1', 'F2', 'F3']);
    expect(next.seats.map((seat) => seat.committedThisRound), everyElement(0));
    expect(next.seats.map((seat) => seat.committedThisHand), <int>[100, 50]);
  });
}

import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const applier = HoldemActionApplier();

  HoldemHandState buildState({
    int currentBetToCall = 100,
    int currentActorSeat = 2,
    int pot = 150,
    List<HoldemSeatState> seats = const <HoldemSeatState>[
      HoldemSeatState(
        seat: 1,
        stack: 1000,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisRound: 0,
        committedThisHand: 0,
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
  }) {
    return HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingPreflop,
      bettingRound: HoldemBettingRound.preflop,
      currentActorSeat: currentActorSeat,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: currentBetToCall,
      minimumRaiseAmount: 100,
      pot: pot,
      seats: seats,
    );
  }

  test('applies legal call to stack, commitments, and pot', () {
    final result = applier.apply(
      state: buildState(),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.call,
      ),
    );

    final actor = result.state.findSeat(2)!;

    expect(result.isApplied, isTrue);
    expect(result.validation.isValid, isTrue);
    expect(actor.stack, 900);
    expect(actor.committedThisRound, 100);
    expect(actor.committedThisHand, 100);
    expect(actor.allIn, isFalse);
    expect(result.state.pot, 200);
    expect(result.state.currentBetToCall, 100);
    expect(result.state.lastAggressorSeat, isNull);
    expect(result.state.lastActionSummary, 'seat_2_call_50');
    expect(result.isBettingRoundComplete, isFalse);
    expect(result.nextActorSeat, 1);
    expect(result.state.currentActorSeat, 1);
  });

  test('applies legal raise as total committed amount', () {
    final result = applier.apply(
      state: buildState(),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.raise,
        amount: 250,
      ),
    );

    final actor = result.state.findSeat(2)!;

    expect(result.isApplied, isTrue);
    expect(actor.stack, 750);
    expect(actor.committedThisRound, 250);
    expect(actor.committedThisHand, 250);
    expect(result.state.pot, 350);
    expect(result.state.currentBetToCall, 250);
    expect(result.state.minimumRaiseAmount, 150);
    expect(result.state.lastAggressorSeat, 2);
    expect(result.state.lastActionSummary, 'seat_2_raise_200');
    expect(result.isBettingRoundComplete, isFalse);
    expect(result.nextActorSeat, 3);
    expect(result.state.currentActorSeat, 3);
  });

  test('applies opening bet as next minimum raise size', () {
    final result = applier.apply(
      state: buildState(
        currentBetToCall: 0,
        pot: 0,
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 1000,
            inHand: true,
            folded: false,
            allIn: false,
          ),
          HoldemSeatState(
            seat: 2,
            stack: 1000,
            inHand: true,
            folded: false,
            allIn: false,
          ),
          HoldemSeatState(
            seat: 3,
            stack: 1000,
            inHand: true,
            folded: false,
            allIn: false,
          ),
        ],
      ),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.bet,
        amount: 300,
      ),
    );

    expect(result.isApplied, isTrue);
    expect(result.state.currentBetToCall, 300);
    expect(result.state.minimumRaiseAmount, 300);
    expect(result.state.lastAggressorSeat, 2);
  });

  test('applies fold without changing pot or commitments', () {
    final result = applier.apply(
      state: buildState(),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.fold,
      ),
    );

    final actor = result.state.findSeat(2)!;

    expect(result.isApplied, isTrue);
    expect(actor.inHand, isFalse);
    expect(actor.folded, isTrue);
    expect(actor.stack, 950);
    expect(actor.committedThisRound, 50);
    expect(result.state.pot, 150);
    expect(result.state.lastActionSummary, 'seat_2_fold');
  });

  test('applies short all-in without reopening current bet', () {
    final result = applier.apply(
      state: buildState(
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 1000,
            inHand: true,
            folded: false,
            allIn: false,
          ),
          HoldemSeatState(
            seat: 2,
            stack: 25,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 50,
            committedThisHand: 50,
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
      ),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.allIn,
      ),
    );

    final actor = result.state.findSeat(2)!;

    expect(result.isApplied, isTrue);
    expect(actor.stack, 0);
    expect(actor.allIn, isTrue);
    expect(actor.committedThisRound, 75);
    expect(actor.committedThisHand, 75);
    expect(result.state.pot, 175);
    expect(result.state.currentBetToCall, 100);
    expect(result.state.lastAggressorSeat, isNull);
    expect(result.isBettingRoundComplete, isFalse);
    expect(result.nextActorSeat, 1);
  });

  test('applies short all-in over current bet without full-raise reopen', () {
    final result = applier.apply(
      state: buildState(
        seats: const <HoldemSeatState>[
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
            stack: 75,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 50,
            committedThisHand: 50,
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
      ),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.allIn,
      ),
    );

    final actor = result.state.findSeat(2)!;

    expect(result.isApplied, isTrue);
    expect(actor.stack, 0);
    expect(actor.allIn, isTrue);
    expect(actor.committedThisRound, 125);
    expect(result.state.currentBetToCall, 125);
    expect(result.state.minimumRaiseAmount, 100);
    expect(result.state.lastAggressorSeat, isNull);
    expect(result.nextActorSeat, 3);
  });

  test('marks betting round complete after the final call', () {
    final result = applier.apply(
      state: buildState(
        currentActorSeat: 1,
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
          ),
          HoldemSeatState(
            seat: 3,
            stack: 900,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 100,
          ),
        ],
      ),
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
    );

    expect(result.isApplied, isTrue);
    expect(result.isBettingRoundComplete, isTrue);
    expect(result.nextActorSeat, isNull);
    expect(result.state.currentActorSeat, 1);
  });

  test('marks checked seats and completes a zero-bet round', () {
    final result = applier.apply(
      state: buildState(
        currentBetToCall: 0,
        currentActorSeat: 3,
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 900,
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
          ),
          HoldemSeatState(
            seat: 3,
            stack: 900,
            inHand: true,
            folded: false,
            allIn: false,
          ),
        ],
      ).copyWith(actedSeatsThisRound: const <int>[1, 2]),
      action: const HoldemTableAction(
        actorSeat: 3,
        type: HoldemTableActionType.check,
      ),
    );

    expect(result.isApplied, isTrue);
    expect(result.state.actedSeatsThisRound, <int>[1, 2, 3]);
    expect(result.isBettingRoundComplete, isTrue);
    expect(result.nextActorSeat, isNull);
  });

  test('rejects invalid action without mutating state', () {
    final state = buildState();
    final result = applier.apply(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
    );

    expect(result.isApplied, isFalse);
    expect(result.validation.reasonCode, 'ERR_OUT_OF_TURN');
    expect(result.state, same(state));
  });
}

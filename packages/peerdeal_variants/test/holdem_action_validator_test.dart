import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const validator = BasicHoldemActionValidator();

  HoldemHandState buildState() {
    return const HoldemHandState(
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
          committedThisRound: 0,
        ),
        HoldemSeatState(
          seat: 2,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 50,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 100,
        ),
      ],
    );
  }

  test('rejects out-of-turn action', () {
    final result = validator.validate(
      state: buildState(),
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.reasonCode, 'ERR_OUT_OF_TURN');
  });

  test('rejects check while facing bet', () {
    final result = validator.validate(
      state: buildState(),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.check,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.reasonCode, 'ERR_CHECK_FACES_BET');
  });

  test('accepts legal call', () {
    final result = validator.validate(
      state: buildState(),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.call,
      ),
    );

    expect(result.isValid, isTrue);
  });

  test('rejects raise below minimum total', () {
    final result = validator.validate(
      state: buildState(),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.raise,
        amount: 150,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.reasonCode, 'ERR_RAISE_BELOW_MINIMUM');
  });

  test('accepts opening bet for exact remaining stack', () {
    final state = buildState().copyWith(
      currentBetToCall: 0,
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
          stack: 100,
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
    );

    final result = validator.validate(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.bet,
        amount: 100,
      ),
    );

    expect(result.isValid, isTrue);
  });

  test('rejects opening bet above remaining stack', () {
    final state = buildState().copyWith(
      currentBetToCall: 0,
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
          stack: 100,
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
    );

    final result = validator.validate(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.bet,
        amount: 101,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.reasonCode, 'ERR_BET_EXCEEDS_STACK');
  });

  test('accepts raise for exact remaining stack contribution', () {
    final state = buildState().copyWith(
      currentBetToCall: 100,
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
          stack: 150,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 50,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 100,
        ),
      ],
    );

    final result = validator.validate(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.raise,
        amount: 200,
      ),
    );

    expect(result.isValid, isTrue);
  });

  test('rejects raise above remaining stack contribution', () {
    final state = buildState().copyWith(
      currentBetToCall: 100,
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
          stack: 149,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 50,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 100,
        ),
      ],
    );

    final result = validator.validate(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.raise,
        amount: 200,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.reasonCode, 'ERR_RAISE_EXCEEDS_STACK');
  });

  test('accepts short all-in while facing a bet', () {
    final state = buildState().copyWith(
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
          stack: 25,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 50,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 100,
        ),
      ],
    );

    final result = validator.validate(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.allIn,
      ),
    );

    expect(result.isValid, isTrue);
  });

  test('rejects all-in with zero stack', () {
    final state = buildState().copyWith(
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
          stack: 0,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 50,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 100,
        ),
      ],
    );

    final result = validator.validate(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.allIn,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.reasonCode, 'ERR_STACK_EMPTY');
  });

  test('rejects voluntary action from already all-in actor', () {
    final state = buildState().copyWith(
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
          stack: 0,
          inHand: true,
          folded: false,
          allIn: true,
          committedThisRound: 100,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 100,
        ),
      ],
    );

    final result = validator.validate(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.check,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.reasonCode, 'ERR_ACTOR_ALL_IN');
  });
}

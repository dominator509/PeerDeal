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
}

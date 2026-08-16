import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const flow = HoldemActionFlow();

  HoldemHandState buildState({
    int currentBetToCall = 100,
    List<int> actedSeatsThisRound = const <int>[3],
    List<HoldemSeatState> seats = const <HoldemSeatState>[
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
        stack: 1000,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisRound: 100,
      ),
    ],
  }) {
    return HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingPreflop,
      bettingRound: HoldemBettingRound.preflop,
      currentActorSeat: 2,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: currentBetToCall,
      minimumRaiseAmount: 100,
      seats: seats,
      actedSeatsThisRound: actedSeatsThisRound,
    );
  }

  test('selects next seat still owing chips after an action', () {
    final result = flow.afterAction(state: buildState(), actedSeat: 2);

    expect(result.isBettingRoundComplete, isFalse);
    expect(result.nextActorSeat, 1);
  });

  test('keeps a matched but unacted seat eligible for its option', () {
    final result = flow.afterAction(
      state: buildState(
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 900,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 100,
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
      ).copyWith(actedSeatsThisRound: const <int>[2]),
      actedSeat: 2,
    );

    expect(result.isBettingRoundComplete, isFalse);
    expect(result.nextActorSeat, 3);
  });

  test('marks round complete when all actionable seats match current bet', () {
    final result = flow.afterAction(
      state: buildState(
        actedSeatsThisRound: const <int>[1, 2, 3],
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 900,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 100,
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
      actedSeat: 2,
    );

    expect(result.isBettingRoundComplete, isTrue);
    expect(result.nextActorSeat, isNull);
  });

  test('marks round complete when only one seat remains in hand', () {
    final result = flow.afterAction(
      state: buildState(
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 900,
            inHand: false,
            folded: true,
            allIn: false,
            committedThisRound: 100,
          ),
          HoldemSeatState(
            seat: 2,
            stack: 900,
            inHand: false,
            folded: true,
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
      actedSeat: 2,
    );

    expect(result.isBettingRoundComplete, isTrue);
    expect(result.nextActorSeat, isNull);
  });

  test(
    'tracks checked seats so zero-bet rounds complete deterministically',
    () {
      final result = flow.afterAction(
        state: buildState(
          currentBetToCall: 0,
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
        ).copyWith(actedSeatsThisRound: const <int>[1, 2, 3]),
        actedSeat: 3,
      );

      expect(result.isBettingRoundComplete, isTrue);
      expect(result.nextActorSeat, isNull);
    },
  );

  test('selects next unchecked seat in a zero-bet round', () {
    final result = flow.afterAction(
      state: buildState(
        currentBetToCall: 0,
      ).copyWith(actedSeatsThisRound: const <int>[2]),
      actedSeat: 2,
    );

    expect(result.isBettingRoundComplete, isFalse);
    expect(result.nextActorSeat, 3);
  });

  test('skips folded and all-in seats when choosing next actor', () {
    final result = flow.afterAction(
      state: buildState(
        currentBetToCall: 200,
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 900,
            inHand: false,
            folded: true,
            allIn: false,
            committedThisRound: 0,
          ),
          HoldemSeatState(
            seat: 2,
            stack: 800,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 200,
          ),
          HoldemSeatState(
            seat: 3,
            stack: 0,
            inHand: true,
            folded: false,
            allIn: true,
            committedThisRound: 50,
          ),
          HoldemSeatState(
            seat: 4,
            stack: 900,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 100,
          ),
        ],
      ),
      actedSeat: 2,
    );

    expect(result.isBettingRoundComplete, isFalse);
    expect(result.nextActorSeat, 4);
  });
}

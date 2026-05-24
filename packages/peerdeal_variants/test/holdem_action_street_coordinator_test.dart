import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const coordinator = HoldemActionStreetCoordinator();

  HoldemHandState buildState({
    HoldemHandPhase phase = HoldemHandPhase.bettingPreflop,
    HoldemBettingRound bettingRound = HoldemBettingRound.preflop,
    int currentActorSeat = 1,
    int currentBetToCall = 100,
    List<String> boardCards = const <String>[],
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
  }) {
    return HoldemHandState(
      handId: 'hand_001',
      phase: phase,
      bettingRound: bettingRound,
      currentActorSeat: currentActorSeat,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: currentBetToCall,
      minimumRaiseAmount: 100,
      pot: 200,
      boardCards: boardCards,
      seats: seats,
    );
  }

  test(
    'returns post-action state without advancing when round remains open',
    () {
      final result = coordinator.applyAndAdvanceIfComplete(
        state: buildState(
          currentActorSeat: 2,
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
              stack: 950,
              inHand: true,
              folded: false,
              allIn: false,
              committedThisRound: 50,
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
          actorSeat: 2,
          type: HoldemTableActionType.call,
        ),
        dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
      );

      expect(result.isActionApplied, isTrue);
      expect(result.isBettingRoundComplete, isFalse);
      expect(result.isStreetAdvanced, isFalse);
      expect(result.street, isNull);
      expect(result.state.phase, HoldemHandPhase.bettingPreflop);
      expect(result.state.currentActorSeat, 1);
      expect(result.state.boardCards, isEmpty);
    },
  );

  test('advances street after action completes betting round', () {
    final result = coordinator.applyAndAdvanceIfComplete(
      state: buildState(),
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
      dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
    );

    expect(result.isActionApplied, isTrue);
    expect(result.isBettingRoundComplete, isTrue);
    expect(result.isStreetAdvanced, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.state.phase, HoldemHandPhase.dealingFlop);
    expect(result.state.bettingRound, HoldemBettingRound.flop);
    expect(result.state.currentBetToCall, 0);
    expect(result.state.boardCards, <String>['Ah', 'Kd', '2c']);
    expect(result.state.findSeat(1)!.committedThisHand, 100);
    expect(
      result.state.seats.map((seat) => seat.committedThisRound),
      everyElement(0),
    );
  });

  test(
    'fails closed after completed action when street cards are malformed',
    () {
      final result = coordinator.applyAndAdvanceIfComplete(
        state: buildState(),
        action: const HoldemTableAction(
          actorSeat: 1,
          type: HoldemTableActionType.call,
        ),
        dealtBoardCards: const <String>['Ah', 'bad', '2c'],
      );

      expect(result.isActionApplied, isTrue);
      expect(result.isBettingRoundComplete, isTrue);
      expect(result.isStreetAdvanced, isFalse);
      expect(result.warnings, contains('ERR_HOLDEM_STREET_CARD_FORMAT'));
      expect(result.state.phase, HoldemHandPhase.bettingPreflop);
      expect(result.state.boardCards, isEmpty);
      expect(result.state.findSeat(1)!.committedThisRound, 100);
      expect(result.state.findSeat(1)!.committedThisHand, 100);
    },
  );

  test('does not advance when action validation fails', () {
    final state = buildState(currentActorSeat: 2);
    final result = coordinator.applyAndAdvanceIfComplete(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
      dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
    );

    expect(result.isActionApplied, isFalse);
    expect(result.isBettingRoundComplete, isFalse);
    expect(result.isStreetAdvanced, isFalse);
    expect(result.street, isNull);
    expect(result.state, same(state));
  });

  test(
    'advances river betting completion to showdown prep with no new cards',
    () {
      final result = coordinator.applyAndAdvanceIfComplete(
        state: buildState(
          phase: HoldemHandPhase.bettingRiver,
          bettingRound: HoldemBettingRound.river,
          boardCards: const <String>['Ah', 'Kd', '2c', 'Jc', '7s'],
        ),
        action: const HoldemTableAction(
          actorSeat: 1,
          type: HoldemTableActionType.call,
        ),
      );

      expect(result.isActionApplied, isTrue);
      expect(result.isStreetAdvanced, isTrue);
      expect(result.state.phase, HoldemHandPhase.showdownPrep);
      expect(result.state.boardCards, <String>['Ah', 'Kd', '2c', 'Jc', '7s']);
    },
  );
}

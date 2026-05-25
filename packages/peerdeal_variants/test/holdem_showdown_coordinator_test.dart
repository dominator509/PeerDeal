import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const coordinator = HoldemShowdownCoordinator();

  HoldemHandState buildState({
    HoldemHandPhase phase = HoldemHandPhase.showdownPrep,
    List<String> boardCards = const <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
  }) {
    return HoldemHandState(
      handId: 'hand_001',
      phase: phase,
      bettingRound: HoldemBettingRound.river,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 0,
      minimumRaiseAmount: 100,
      boardCards: boardCards,
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
          stack: 900,
          inHand: true,
          folded: false,
          allIn: false,
        ),
      ],
    );
  }

  const validInput = ShowdownEvaluationInput(
    boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
    seats: <ShowdownSeatInput>[
      ShowdownSeatInput(
        seat: 1,
        holeCards: <String>['Th', '9d'],
        isFolded: false,
      ),
      ShowdownSeatInput(
        seat: 2,
        holeCards: <String>['Ac', '3c'],
        isFolded: false,
      ),
    ],
  );

  test('reveals showdown from prep when evaluation is safe', () {
    final state = buildState();

    final result = coordinator.reveal(state: state, input: validInput);

    expect(result.isRevealed, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.evaluation.warnings, isEmpty);
    expect(result.evaluation.results, hasLength(2));
    expect(result.state.phase, HoldemHandPhase.showdownReveal);
    expect(result.state.boardCards, state.boardCards);
  });

  test('fails closed when reveal is requested from the wrong phase', () {
    final state = buildState(phase: HoldemHandPhase.bettingRiver);

    final result = coordinator.reveal(state: state, input: validInput);

    expect(result.isRevealed, isFalse);
    expect(result.state, same(state));
    expect(result.evaluation.results, isEmpty);
    expect(result.warnings, contains('ERR_HOLDEM_SHOWDOWN_REVEAL_PHASE'));
  });

  test('fails closed when input board differs from state board', () {
    final state = buildState(
      boardCards: const <String>['Ah', 'Kd', 'Qs', 'Jc', '3h'],
    );

    final result = coordinator.reveal(state: state, input: validInput);

    expect(result.isRevealed, isFalse);
    expect(result.state, same(state));
    expect(result.evaluation.results, isEmpty);
    expect(result.warnings, contains('ERR_HOLDEM_SHOWDOWN_BOARD_MISMATCH'));
  });

  test('fails closed when showdown evaluation reports warnings', () {
    final state = buildState();
    const input = ShowdownEvaluationInput(
      boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
      seats: <ShowdownSeatInput>[
        ShowdownSeatInput(
          seat: 1,
          holeCards: <String>['Th', 'bad'],
          isFolded: false,
        ),
        ShowdownSeatInput(
          seat: 2,
          holeCards: <String>['Ac', '3c'],
          isFolded: false,
        ),
      ],
    );

    final result = coordinator.reveal(state: state, input: input);

    expect(result.isRevealed, isFalse);
    expect(result.state, same(state));
    expect(result.evaluation.results, isEmpty);
    expect(result.warnings, contains('ERR_HOLDEM_SHOWDOWN_CARD_FORMAT'));
  });
}

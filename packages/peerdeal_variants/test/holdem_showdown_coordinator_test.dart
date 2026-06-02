import 'package:peerdeal_core/peerdeal_core.dart';
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

  test('prepares settlement from revealed clean showdown evaluation', () {
    final reveal = coordinator.reveal(state: buildState(), input: validInput);

    final result = coordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );

    expect(reveal.isRevealed, isTrue);
    expect(result.isPrepared, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.evaluation, same(reveal.evaluation));
    expect(result.state.phase, HoldemHandPhase.settling);
  });

  test('settlement prep fails closed before showdown reveal', () {
    final evaluation = coordinator
        .reveal(state: buildState(), input: validInput)
        .evaluation;
    final state = buildState();

    final result = coordinator.prepareSettlement(
      state: state,
      evaluation: evaluation,
    );

    expect(result.isPrepared, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_SETTLEMENT_PREP_PHASE'));
  });

  test('settlement prep fails closed on empty evaluation', () {
    final state = buildState(phase: HoldemHandPhase.showdownReveal);
    const evaluation = ShowdownEvaluationResult(
      results: <RankedShowdownResult>[],
    );

    final result = coordinator.prepareSettlement(
      state: state,
      evaluation: evaluation,
    );

    expect(result.isPrepared, isFalse);
    expect(result.state, same(state));
    expect(
      result.warnings,
      contains('ERR_HOLDEM_SETTLEMENT_PREP_EMPTY_EVALUATION'),
    );
  });

  test('settlement prep carries evaluation warnings fail closed', () {
    final state = buildState(phase: HoldemHandPhase.showdownReveal);
    const evaluation = ShowdownEvaluationResult(
      results: <RankedShowdownResult>[],
      warnings: <String>['ERR_HOLDEM_SHOWDOWN_CARD_FORMAT'],
    );

    final result = coordinator.prepareSettlement(
      state: state,
      evaluation: evaluation,
    );

    expect(result.isPrepared, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_SHOWDOWN_CARD_FORMAT'));
    expect(
      result.warnings,
      contains('ERR_HOLDEM_SETTLEMENT_PREP_EMPTY_EVALUATION'),
    );
  });

  test('projects settlement from settling phase and clean evaluation', () {
    final reveal = coordinator.reveal(state: buildState(), input: validInput);
    final prep = coordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );

    final result = coordinator.projectSettlement(
      state: prep.state,
      evaluation: prep.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'seat-2',
          committed: 200,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );

    expect(prep.isPrepared, isTrue);
    expect(result.isProjected, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.state, same(prep.state));
    expect(result.projection, isNotNull);
    expect(result.projection!.settlement, isNotNull);
  });

  test('settlement projection fails closed before settling phase', () {
    final reveal = coordinator.reveal(state: buildState(), input: validInput);

    final result = coordinator.projectSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );

    expect(result.isProjected, isFalse);
    expect(result.projection, isNull);
    expect(result.state, same(reveal.state));
    expect(result.warnings, contains('ERR_HOLDEM_SETTLEMENT_PROJECT_PHASE'));
  });

  test('settlement projection fails closed with empty commitments', () {
    final reveal = coordinator.reveal(state: buildState(), input: validInput);
    final prep = coordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );

    final result = coordinator.projectSettlement(
      state: prep.state,
      evaluation: prep.evaluation,
      commitments: const <PotCommitment>[],
      seatForId: _seatFromSeatId,
    );

    expect(result.isProjected, isFalse);
    expect(result.projection, isNull);
    expect(
      result.warnings,
      contains('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_COMMITMENTS'),
    );
  });

  test('settlement projection reports unawardable slices fail closed', () {
    final reveal = coordinator.reveal(state: buildState(), input: validInput);
    final prep = coordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );

    final result = coordinator.projectSettlement(
      state: prep.state,
      evaluation: prep.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-9',
          committed: 100,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );

    expect(result.isProjected, isFalse);
    expect(result.projection, isNotNull);
    expect(result.projection!.isBlocked, isTrue);
    expect(
      result.warnings,
      contains('ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE'),
    );
  });

  test('projects uncontested settlement from settling phase', () {
    final state = buildState(phase: HoldemHandPhase.settling);

    final result = coordinator.projectUncontestedSettlement(
      state: state,
      winningSeat: 1,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'seat-2',
          committed: 100,
          isEligibleForShowdown: false,
          isFolded: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );

    expect(result.isProjected, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.evaluation.results.single.seat, 1);
    expect(result.evaluation.results.single.summary, 'Uncontested pot');
    expect(result.projection, isNotNull);
    expect(result.projection!.settlement, isNotNull);
    expect(result.projection!.settlement!.totalAwardedAmount, 200);
  });

  test('uncontested settlement projection fails closed without winner', () {
    final state = buildState(phase: HoldemHandPhase.settling);

    final result = coordinator.projectUncontestedSettlement(
      state: state,
      winningSeat: null,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );

    expect(result.isProjected, isFalse);
    expect(result.projection, isNull);
    expect(
      result.warnings,
      contains('ERR_HOLDEM_UNCONTESTED_SETTLEMENT_NO_WINNER'),
    );
    expect(
      result.warnings,
      contains('ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN'),
    );
  });

  test('completes hand after successful settlement projection', () {
    final reveal = coordinator.reveal(state: buildState(), input: validInput);
    final prep = coordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );
    final projection = coordinator.projectSettlement(
      state: prep.state,
      evaluation: prep.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'seat-2',
          committed: 200,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );

    final result = coordinator.completeHand(
      state: prep.state,
      settlement: projection,
    );

    expect(projection.isProjected, isTrue);
    expect(result.isCompleted, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.projection, same(projection.projection));
    expect(result.state.phase, HoldemHandPhase.handComplete);
  });

  test('hand completion fails closed before settling phase', () {
    final reveal = coordinator.reveal(state: buildState(), input: validInput);
    final prep = coordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );
    final projection = coordinator.projectSettlement(
      state: prep.state,
      evaluation: prep.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'seat-2',
          committed: 200,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );
    final wrongPhaseState = prep.state.copyWith(
      phase: HoldemHandPhase.showdownReveal,
    );

    final result = coordinator.completeHand(
      state: wrongPhaseState,
      settlement: projection,
    );

    expect(result.isCompleted, isFalse);
    expect(result.state, same(wrongPhaseState));
    expect(result.warnings, contains('ERR_HOLDEM_HAND_COMPLETE_PHASE'));
  });

  test('hand completion fails closed on blocked settlement projection', () {
    final reveal = coordinator.reveal(state: buildState(), input: validInput);
    final prep = coordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );
    final projection = coordinator.projectSettlement(
      state: prep.state,
      evaluation: prep.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-9',
          committed: 100,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );

    final result = coordinator.completeHand(
      state: prep.state,
      settlement: projection,
    );

    expect(projection.isProjected, isFalse);
    expect(result.isCompleted, isFalse);
    expect(result.state, same(prep.state));
    expect(
      result.warnings,
      contains('ERR_HOLDEM_HAND_COMPLETE_UNPROJECTED_SETTLEMENT'),
    );
    expect(
      result.warnings,
      contains('ERR_HOLDEM_HAND_COMPLETE_BLOCKED_SETTLEMENT'),
    );
  });
}

int? _seatFromSeatId(String seatId) {
  final marker = seatId.split('-').last;
  return int.tryParse(marker);
}

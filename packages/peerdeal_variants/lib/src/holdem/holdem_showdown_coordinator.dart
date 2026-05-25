import 'package:meta/meta.dart';

import '../contracts/showdown_models.dart';
import 'holdem_hand_phase.dart';
import 'holdem_hand_state.dart';
import 'holdem_showdown_evaluator.dart';
import 'holdem_state_machine.dart';

@immutable
class HoldemShowdownRevealResult {
  const HoldemShowdownRevealResult({
    required this.isRevealed,
    required this.state,
    required this.evaluation,
    this.warnings = const <String>[],
  });

  final bool isRevealed;
  final HoldemHandState state;
  final ShowdownEvaluationResult evaluation;
  final List<String> warnings;
}

class HoldemShowdownCoordinator {
  const HoldemShowdownCoordinator({
    this.evaluator = const HoldemShowdownEvaluator(),
    this.stateMachine = const HoldemStateMachine(),
  });

  final HoldemShowdownEvaluator evaluator;
  final HoldemStateMachine stateMachine;

  HoldemShowdownRevealResult reveal({
    required HoldemHandState state,
    required ShowdownEvaluationInput input,
  }) {
    final warnings = <String>[];
    if (state.phase != HoldemHandPhase.showdownPrep) {
      warnings.add('ERR_HOLDEM_SHOWDOWN_REVEAL_PHASE');
    }

    if (!_sameCards(state.boardCards, input.boardCards)) {
      warnings.add('ERR_HOLDEM_SHOWDOWN_BOARD_MISMATCH');
    }

    if (warnings.isNotEmpty) {
      return HoldemShowdownRevealResult(
        isRevealed: false,
        state: state,
        evaluation: const ShowdownEvaluationResult(
          results: <RankedShowdownResult>[],
        ),
        warnings: warnings,
      );
    }

    final evaluation = evaluator.evaluate(input);
    if (evaluation.warnings.isNotEmpty) {
      return HoldemShowdownRevealResult(
        isRevealed: false,
        state: state,
        evaluation: evaluation,
        warnings: evaluation.warnings,
      );
    }

    final transition = stateMachine.canTransition(
      from: state.phase,
      to: HoldemHandPhase.showdownReveal,
    );
    if (!transition.isAllowed) {
      return HoldemShowdownRevealResult(
        isRevealed: false,
        state: state,
        evaluation: evaluation,
        warnings: const <String>['ERR_HOLDEM_SHOWDOWN_REVEAL_TRANSITION'],
      );
    }

    return HoldemShowdownRevealResult(
      isRevealed: true,
      state: state.copyWith(phase: HoldemHandPhase.showdownReveal),
      evaluation: evaluation,
    );
  }

  bool _sameCards(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var i = 0; i < left.length; i += 1) {
      if (left[i] != right[i]) {
        return false;
      }
    }

    return true;
  }
}

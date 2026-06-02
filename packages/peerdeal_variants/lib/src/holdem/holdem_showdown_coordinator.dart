import 'package:meta/meta.dart';
import 'package:peerdeal_core/peerdeal_core.dart';

import '../contracts/showdown_models.dart';
import '../contracts/showdown_settlement_projector.dart';
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

@immutable
class HoldemSettlementPrepResult {
  const HoldemSettlementPrepResult({
    required this.isPrepared,
    required this.state,
    required this.evaluation,
    this.warnings = const <String>[],
  });

  final bool isPrepared;
  final HoldemHandState state;
  final ShowdownEvaluationResult evaluation;
  final List<String> warnings;
}

@immutable
class HoldemSettlementProjectionGateResult {
  const HoldemSettlementProjectionGateResult({
    required this.isProjected,
    required this.state,
    required this.evaluation,
    required this.projection,
    this.warnings = const <String>[],
  });

  final bool isProjected;
  final HoldemHandState state;
  final ShowdownEvaluationResult evaluation;
  final ShowdownSettlementProjectionResult? projection;
  final List<String> warnings;
}

@immutable
class HoldemHandCompletionGateResult {
  const HoldemHandCompletionGateResult({
    required this.isCompleted,
    required this.state,
    required this.projection,
    this.warnings = const <String>[],
  });

  final bool isCompleted;
  final HoldemHandState state;
  final ShowdownSettlementProjectionResult? projection;
  final List<String> warnings;
}

class HoldemShowdownCoordinator {
  const HoldemShowdownCoordinator({
    this.evaluator = const HoldemShowdownEvaluator(),
    this.stateMachine = const HoldemStateMachine(),
    this.settlementProjector = const ShowdownSettlementProjector(),
  });

  final HoldemShowdownEvaluator evaluator;
  final HoldemStateMachine stateMachine;
  final ShowdownSettlementProjector settlementProjector;

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

  HoldemSettlementPrepResult prepareSettlement({
    required HoldemHandState state,
    required ShowdownEvaluationResult evaluation,
  }) {
    final warnings = <String>[];
    if (state.phase != HoldemHandPhase.showdownReveal) {
      warnings.add('ERR_HOLDEM_SETTLEMENT_PREP_PHASE');
    }

    if (evaluation.warnings.isNotEmpty) {
      warnings.addAll(evaluation.warnings);
    }

    if (evaluation.results.isEmpty) {
      warnings.add('ERR_HOLDEM_SETTLEMENT_PREP_EMPTY_EVALUATION');
    }

    if (warnings.isNotEmpty) {
      return HoldemSettlementPrepResult(
        isPrepared: false,
        state: state,
        evaluation: evaluation,
        warnings: warnings,
      );
    }

    final transition = stateMachine.canTransition(
      from: state.phase,
      to: HoldemHandPhase.settling,
    );
    if (!transition.isAllowed) {
      return HoldemSettlementPrepResult(
        isPrepared: false,
        state: state,
        evaluation: evaluation,
        warnings: const <String>['ERR_HOLDEM_SETTLEMENT_PREP_TRANSITION'],
      );
    }

    return HoldemSettlementPrepResult(
      isPrepared: true,
      state: state.copyWith(phase: HoldemHandPhase.settling),
      evaluation: evaluation,
    );
  }

  HoldemSettlementProjectionGateResult projectSettlement({
    required HoldemHandState state,
    required ShowdownEvaluationResult evaluation,
    required List<PotCommitment> commitments,
    required int? Function(String seatId) seatForId,
    SettlementPolicy policy = const SettlementPolicy(),
  }) {
    final warnings = <String>[];
    if (state.phase != HoldemHandPhase.settling) {
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_PHASE');
    }

    if (evaluation.warnings.isNotEmpty) {
      warnings.addAll(evaluation.warnings);
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN');
    }

    if (evaluation.results.isEmpty) {
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_EVALUATION');
      if (!warnings.contains(
        'ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN',
      )) {
        warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN');
      }
    }

    if (commitments.isEmpty) {
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_COMMITMENTS');
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT');
    }

    if (warnings.isNotEmpty) {
      return HoldemSettlementProjectionGateResult(
        isProjected: false,
        state: state,
        evaluation: evaluation,
        projection: null,
        warnings: warnings,
      );
    }

    final projection = settlementProjector.projectAndSettle(
      showdown: evaluation,
      commitments: commitments,
      seatForId: seatForId,
      policy: policy,
    );
    if (projection.isBlocked) {
      return HoldemSettlementProjectionGateResult(
        isProjected: false,
        state: state,
        evaluation: evaluation,
        projection: projection,
        warnings: projection.warnings.isEmpty
            ? const <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE']
            : projection.warnings,
      );
    }

    return HoldemSettlementProjectionGateResult(
      isProjected: true,
      state: state,
      evaluation: evaluation,
      projection: projection,
    );
  }

  HoldemSettlementProjectionGateResult projectUncontestedSettlement({
    required HoldemHandState state,
    required int? winningSeat,
    required List<PotCommitment> commitments,
    required int? Function(String seatId) seatForId,
    SettlementPolicy policy = const SettlementPolicy(),
  }) {
    final warnings = <String>[];
    if (state.phase != HoldemHandPhase.settling) {
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_PHASE');
    }

    if (winningSeat == null) {
      warnings.add('ERR_HOLDEM_UNCONTESTED_SETTLEMENT_NO_WINNER');
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN');
    }

    if (commitments.isEmpty) {
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_COMMITMENTS');
      warnings.add('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT');
    }

    final evaluation = ShowdownEvaluationResult(
      results: winningSeat == null
          ? const <RankedShowdownResult>[]
          : <RankedShowdownResult>[
              RankedShowdownResult(
                seat: winningSeat,
                rankIndex: 0,
                summary: 'Uncontested pot',
              ),
            ],
      warnings: winningSeat == null
          ? const <String>['ERR_HOLDEM_UNCONTESTED_SETTLEMENT_NO_WINNER']
          : const <String>[],
    );

    if (warnings.isNotEmpty) {
      return HoldemSettlementProjectionGateResult(
        isProjected: false,
        state: state,
        evaluation: evaluation,
        projection: null,
        warnings: warnings,
      );
    }

    final projection = settlementProjector.projectUncontestedAndSettle(
      winningSeat: winningSeat!,
      commitments: commitments,
      seatForId: seatForId,
      policy: policy,
    );
    if (projection.isBlocked) {
      return HoldemSettlementProjectionGateResult(
        isProjected: false,
        state: state,
        evaluation: evaluation,
        projection: projection,
        warnings: projection.warnings.isEmpty
            ? const <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE']
            : projection.warnings,
      );
    }

    return HoldemSettlementProjectionGateResult(
      isProjected: true,
      state: state,
      evaluation: evaluation,
      projection: projection,
    );
  }

  HoldemHandCompletionGateResult completeHand({
    required HoldemHandState state,
    required HoldemSettlementProjectionGateResult settlement,
  }) {
    final warnings = <String>[];
    if (state.phase != HoldemHandPhase.settling) {
      warnings.add('ERR_HOLDEM_HAND_COMPLETE_PHASE');
    }

    if (!settlement.isProjected) {
      warnings.add('ERR_HOLDEM_HAND_COMPLETE_UNPROJECTED_SETTLEMENT');
    }

    if (settlement.warnings.isNotEmpty) {
      warnings.addAll(settlement.warnings);
    }

    if (settlement.projection == null || settlement.projection!.isBlocked) {
      warnings.add('ERR_HOLDEM_HAND_COMPLETE_BLOCKED_SETTLEMENT');
    }

    if (warnings.isNotEmpty) {
      return HoldemHandCompletionGateResult(
        isCompleted: false,
        state: state,
        projection: settlement.projection,
        warnings: warnings,
      );
    }

    final transition = stateMachine.canTransition(
      from: state.phase,
      to: HoldemHandPhase.handComplete,
    );
    if (!transition.isAllowed) {
      return HoldemHandCompletionGateResult(
        isCompleted: false,
        state: state,
        projection: settlement.projection,
        warnings: const <String>['ERR_HOLDEM_HAND_COMPLETE_TRANSITION'],
      );
    }

    return HoldemHandCompletionGateResult(
      isCompleted: true,
      state: state.copyWith(phase: HoldemHandPhase.handComplete),
      projection: settlement.projection,
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

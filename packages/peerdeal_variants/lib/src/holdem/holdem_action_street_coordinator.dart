import 'package:meta/meta.dart';

import 'holdem_action_applier.dart';
import 'holdem_hand_phase.dart';
import 'holdem_hand_state.dart';
import 'holdem_state_machine.dart';
import 'holdem_table_action.dart';

@immutable
class HoldemActionStreetResult {
  const HoldemActionStreetResult({
    required this.action,
    required this.state,
    this.street,
    this.bettingRound,
    this.uncontestedSettlement,
  });

  final HoldemActionApplicationResult action;
  final HoldemStreetAdvanceResult? street;
  final HoldemBettingRoundOpenResult? bettingRound;
  final HoldemUncontestedSettlementResult? uncontestedSettlement;
  final HoldemHandState state;

  bool get isActionApplied => action.isApplied;

  bool get isBettingRoundComplete => action.isBettingRoundComplete;

  bool get isStreetAdvanced => street?.isAdvanced ?? false;

  bool get isBettingRoundOpened => bettingRound?.isOpened ?? false;

  bool get isUncontestedSettlementReady {
    return uncontestedSettlement?.isReady ?? false;
  }

  List<String> get warnings {
    return List<String>.unmodifiable(<String>[
      ...?street?.warnings,
      ...?bettingRound?.warnings,
      ...?uncontestedSettlement?.warnings,
    ]);
  }
}

@immutable
class HoldemUncontestedSettlementResult {
  HoldemUncontestedSettlementResult({
    required this.isReady,
    required this.state,
    required this.winningSeat,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  final bool isReady;
  final HoldemHandState state;
  final int? winningSeat;
  final List<String> warnings;
}

class HoldemActionStreetCoordinator {
  const HoldemActionStreetCoordinator({
    this.applier = const HoldemActionApplier(),
    this.stateMachine = const HoldemStateMachine(),
  });

  final HoldemActionApplier applier;
  final HoldemStateMachine stateMachine;

  HoldemActionStreetResult applyAndAdvanceIfComplete({
    required HoldemHandState state,
    required HoldemTableAction action,
    List<String> dealtBoardCards = const <String>[],
    bool openNextBettingRound = false,
  }) {
    final actionResult = applier.apply(state: state, action: action);
    if (!actionResult.isApplied || !actionResult.isBettingRoundComplete) {
      return HoldemActionStreetResult(
        action: actionResult,
        state: actionResult.state,
      );
    }

    final uncontestedSettlement = _settleIfUncontested(actionResult.state);
    if (uncontestedSettlement != null) {
      return HoldemActionStreetResult(
        action: actionResult,
        uncontestedSettlement: uncontestedSettlement,
        state: uncontestedSettlement.state,
      );
    }

    final streetResult = stateMachine.advanceAfterBettingRound(
      state: actionResult.state,
      dealtBoardCards: dealtBoardCards,
    );
    if (!openNextBettingRound ||
        !streetResult.isAdvanced ||
        !_canOpenBettingRound(streetResult.state.phase)) {
      return HoldemActionStreetResult(
        action: actionResult,
        street: streetResult,
        state: streetResult.state,
      );
    }

    final bettingRoundResult = stateMachine.openBettingRoundAfterDeal(
      state: streetResult.state,
    );
    return HoldemActionStreetResult(
      action: actionResult,
      street: streetResult,
      bettingRound: bettingRoundResult,
      state: bettingRoundResult.state,
    );
  }

  bool _canOpenBettingRound(HoldemHandPhase phase) {
    return switch (phase) {
      HoldemHandPhase.dealingFlop ||
      HoldemHandPhase.dealingTurn ||
      HoldemHandPhase.dealingRiver => true,
      _ => false,
    };
  }

  HoldemUncontestedSettlementResult? _settleIfUncontested(
    HoldemHandState state,
  ) {
    final activeSeats = state.seats
        .where((seat) => seat.inHand && !seat.folded)
        .toList(growable: false);
    if (activeSeats.length > 1) {
      return null;
    }

    if (activeSeats.isEmpty) {
      return HoldemUncontestedSettlementResult(
        isReady: false,
        state: state,
        winningSeat: null,
        warnings: const <String>['ERR_HOLDEM_UNCONTESTED_SETTLEMENT_NO_WINNER'],
      );
    }

    final transition = stateMachine.canTransition(
      from: state.phase,
      to: HoldemHandPhase.settling,
    );
    if (!transition.isAllowed) {
      return HoldemUncontestedSettlementResult(
        isReady: false,
        state: state,
        winningSeat: _winningSeatFor(activeSeats),
        warnings: const <String>[
          'ERR_HOLDEM_UNCONTESTED_SETTLEMENT_TRANSITION',
        ],
      );
    }

    return HoldemUncontestedSettlementResult(
      isReady: true,
      state: state.copyWith(phase: HoldemHandPhase.settling),
      winningSeat: _winningSeatFor(activeSeats),
    );
  }

  int? _winningSeatFor(List<HoldemSeatState> activeSeats) {
    return activeSeats.length == 1 ? activeSeats.single.seat : null;
  }
}

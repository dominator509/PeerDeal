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
  });

  final HoldemActionApplicationResult action;
  final HoldemStreetAdvanceResult? street;
  final HoldemBettingRoundOpenResult? bettingRound;
  final HoldemHandState state;

  bool get isActionApplied => action.isApplied;

  bool get isBettingRoundComplete => action.isBettingRoundComplete;

  bool get isStreetAdvanced => street?.isAdvanced ?? false;

  bool get isBettingRoundOpened => bettingRound?.isOpened ?? false;

  List<String> get warnings {
    return <String>[...?street?.warnings, ...?bettingRound?.warnings];
  }
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
}

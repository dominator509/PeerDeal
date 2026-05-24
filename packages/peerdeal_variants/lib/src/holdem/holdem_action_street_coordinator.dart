import 'package:meta/meta.dart';

import 'holdem_action_applier.dart';
import 'holdem_hand_state.dart';
import 'holdem_state_machine.dart';
import 'holdem_table_action.dart';

@immutable
class HoldemActionStreetResult {
  const HoldemActionStreetResult({
    required this.action,
    required this.state,
    this.street,
  });

  final HoldemActionApplicationResult action;
  final HoldemStreetAdvanceResult? street;
  final HoldemHandState state;

  bool get isActionApplied => action.isApplied;

  bool get isBettingRoundComplete => action.isBettingRoundComplete;

  bool get isStreetAdvanced => street?.isAdvanced ?? false;

  List<String> get warnings => street?.warnings ?? const <String>[];
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
    return HoldemActionStreetResult(
      action: actionResult,
      street: streetResult,
      state: streetResult.state,
    );
  }
}

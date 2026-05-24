import 'package:meta/meta.dart';

import 'holdem_action_validator.dart';
import 'holdem_hand_state.dart';
import 'holdem_table_action.dart';

@immutable
class HoldemActionApplicationResult {
  const HoldemActionApplicationResult({
    required this.isApplied,
    required this.state,
    required this.validation,
  });

  final bool isApplied;
  final HoldemHandState state;
  final HoldemActionValidationResult validation;
}

class HoldemActionApplier {
  const HoldemActionApplier({
    this.validator = const BasicHoldemActionValidator(),
  });

  final HoldemActionValidator validator;

  HoldemActionApplicationResult apply({
    required HoldemHandState state,
    required HoldemTableAction action,
  }) {
    final validation = validator.validate(state: state, action: action);
    if (!validation.isValid) {
      return HoldemActionApplicationResult(
        isApplied: false,
        state: state,
        validation: validation,
      );
    }

    final actor = state.findSeat(action.actorSeat)!;
    final contribution = _contributionFor(
      state: state,
      actor: actor,
      action: action,
    );
    final newCommittedThisRound = actor.committedThisRound + contribution;
    final newStack = actor.stack - contribution;
    final opensOrRaisesBet = newCommittedThisRound > state.currentBetToCall;
    final updatedActor = actor.copyWith(
      stack: newStack,
      inHand: action.type == HoldemTableActionType.fold ? false : actor.inHand,
      folded: action.type == HoldemTableActionType.fold ? true : actor.folded,
      allIn: action.type == HoldemTableActionType.allIn || newStack == 0,
      committedThisRound: newCommittedThisRound,
      committedThisHand: actor.committedThisHand + contribution,
    );

    return HoldemActionApplicationResult(
      isApplied: true,
      state: state.copyWith(
        seats: <HoldemSeatState>[
          for (final seat in state.seats)
            seat.seat == action.actorSeat ? updatedActor : seat,
        ],
        pot: state.pot + contribution,
        currentBetToCall: opensOrRaisesBet
            ? newCommittedThisRound
            : state.currentBetToCall,
        lastAggressorSeat: opensOrRaisesBet
            ? action.actorSeat
            : state.lastAggressorSeat,
        lastActionSummary: _summaryFor(action, contribution),
      ),
      validation: validation,
    );
  }

  int _contributionFor({
    required HoldemHandState state,
    required HoldemSeatState actor,
    required HoldemTableAction action,
  }) {
    final amountToCall = state.currentBetToCall - actor.committedThisRound;
    return switch (action.type) {
      HoldemTableActionType.fold => 0,
      HoldemTableActionType.check => 0,
      HoldemTableActionType.call => amountToCall,
      HoldemTableActionType.bet => action.amount,
      HoldemTableActionType.raise => action.amount - actor.committedThisRound,
      HoldemTableActionType.allIn => actor.stack,
    };
  }

  String _summaryFor(HoldemTableAction action, int contribution) {
    final type = action.type.name;
    return contribution == 0
        ? 'seat_${action.actorSeat}_$type'
        : 'seat_${action.actorSeat}_${type}_$contribution';
  }
}

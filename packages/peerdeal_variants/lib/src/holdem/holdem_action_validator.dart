import 'package:meta/meta.dart';

import 'holdem_hand_phase.dart';
import 'holdem_hand_state.dart';
import 'holdem_table_action.dart';

@immutable
class HoldemActionValidationResult {
  const HoldemActionValidationResult({
    required this.isValid,
    this.reasonCode,
    this.message,
  });

  final bool isValid;
  final String? reasonCode;
  final String? message;

  static const ok = HoldemActionValidationResult(isValid: true);
}

abstract interface class HoldemActionValidator {
  HoldemActionValidationResult validate({
    required HoldemHandState state,
    required HoldemTableAction action,
  });
}

class BasicHoldemActionValidator implements HoldemActionValidator {
  const BasicHoldemActionValidator();

  @override
  HoldemActionValidationResult validate({
    required HoldemHandState state,
    required HoldemTableAction action,
  }) {
    if (action.amount < 0) {
      return const HoldemActionValidationResult(
        isValid: false,
        reasonCode: 'ERR_NEGATIVE_ACTION_AMOUNT',
        message: 'Action amount cannot be negative.',
      );
    }

    const bettingPhases = <HoldemHandPhase>{
      HoldemHandPhase.bettingPreflop,
      HoldemHandPhase.bettingFlop,
      HoldemHandPhase.bettingTurn,
      HoldemHandPhase.bettingRiver,
    };

    if (!bettingPhases.contains(state.phase)) {
      return const HoldemActionValidationResult(
        isValid: false,
        reasonCode: 'ERR_HAND_NOT_AWAITING_ACTION',
        message: 'Hand is not in a betting state.',
      );
    }

    if (state.currentActorSeat != action.actorSeat) {
      return const HoldemActionValidationResult(
        isValid: false,
        reasonCode: 'ERR_OUT_OF_TURN',
        message: 'Only the current actor may act.',
      );
    }

    final actor = state.findSeat(action.actorSeat);
    if (actor == null || !actor.inHand || actor.folded) {
      return const HoldemActionValidationResult(
        isValid: false,
        reasonCode: 'ERR_SEAT_NOT_ELIGIBLE',
        message: 'Seat is not eligible to act.',
      );
    }

    if (actor.allIn) {
      return const HoldemActionValidationResult(
        isValid: false,
        reasonCode: 'ERR_ACTOR_ALL_IN',
        message: 'An all-in seat may not take a new voluntary action.',
      );
    }

    final amountToCall = state.currentBetToCall - actor.committedThisRound;
    switch (action.type) {
      case HoldemTableActionType.fold:
        return HoldemActionValidationResult.ok;
      case HoldemTableActionType.check:
        if (amountToCall != 0) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_CHECK_FACES_BET',
            message: 'Cannot check while facing a bet.',
          );
        }
        return HoldemActionValidationResult.ok;
      case HoldemTableActionType.call:
        if (amountToCall <= 0) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_NOTHING_TO_CALL',
            message: 'There is nothing to call.',
          );
        }
        if (actor.stack < amountToCall) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_CALL_EXCEEDS_STACK',
            message: 'Call exceeds remaining stack.',
          );
        }
        return HoldemActionValidationResult.ok;
      case HoldemTableActionType.bet:
        if (state.currentBetToCall != 0) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_BET_ALREADY_OPEN',
            message: 'Use raise while facing an open bet.',
          );
        }
        if (action.amount < state.minimumRaiseAmount) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_BET_BELOW_MINIMUM',
            message: 'Bet amount is below minimum opening size.',
          );
        }
        if (action.amount > actor.stack) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_BET_EXCEEDS_STACK',
            message: 'Bet exceeds remaining stack.',
          );
        }
        return HoldemActionValidationResult.ok;
      case HoldemTableActionType.raise:
        if (amountToCall <= 0) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_NOT_FACING_BET',
            message: 'Cannot raise when not facing a bet.',
          );
        }
        if (state.actedSeatsThisRound.contains(action.actorSeat)) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_RAISE_NOT_REOPENED',
            message: 'A short all-in did not reopen raising for this seat.',
          );
        }
        final minimumTotal = state.currentBetToCall + state.minimumRaiseAmount;
        if (action.amount < minimumTotal) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_RAISE_BELOW_MINIMUM',
            message: 'Raise total is below minimum legal raise size.',
          );
        }
        if (action.amount - actor.committedThisRound > actor.stack) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_RAISE_EXCEEDS_STACK',
            message: 'Raise exceeds remaining stack.',
          );
        }
        return HoldemActionValidationResult.ok;
      case HoldemTableActionType.allIn:
        if (actor.stack <= 0) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_STACK_EMPTY',
            message: 'Cannot move all-in with zero stack.',
          );
        }
        final allInRaiseIncrement =
            actor.committedThisRound + actor.stack - state.currentBetToCall;
        if (state.actedSeatsThisRound.contains(action.actorSeat) &&
            allInRaiseIncrement >= state.minimumRaiseAmount) {
          return const HoldemActionValidationResult(
            isValid: false,
            reasonCode: 'ERR_RAISE_NOT_REOPENED',
            message: 'A short all-in did not reopen raising for this seat.',
          );
        }
        return HoldemActionValidationResult.ok;
    }
  }
}

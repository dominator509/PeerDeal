import 'package:meta/meta.dart';

import 'holdem_hand_phase.dart';
import 'holdem_hand_state.dart';
import 'holdem_state_machine.dart';

@immutable
class HoldemBlindPostingResult {
  const HoldemBlindPostingResult({
    required this.isPosted,
    required this.state,
    this.warnings = const <String>[],
  });

  final bool isPosted;
  final HoldemHandState state;
  final List<String> warnings;
}

class HoldemBlindPostingCoordinator {
  const HoldemBlindPostingCoordinator({
    this.stateMachine = const HoldemStateMachine(),
  });

  final HoldemStateMachine stateMachine;

  HoldemBlindPostingResult postBlinds({
    required HoldemHandState state,
    required int smallBlindAmount,
    required int bigBlindAmount,
  }) {
    final warnings = _validate(
      state: state,
      smallBlindAmount: smallBlindAmount,
      bigBlindAmount: bigBlindAmount,
    );
    if (warnings.isNotEmpty) {
      return HoldemBlindPostingResult(
        isPosted: false,
        state: state,
        warnings: warnings,
      );
    }

    final smallBlind = state.findSeat(state.smallBlindSeat)!;
    final bigBlind = state.findSeat(state.bigBlindSeat)!;
    final smallContribution = _blindContribution(
      seat: smallBlind,
      amount: smallBlindAmount,
    );
    final bigContribution = _blindContribution(
      seat: bigBlind,
      amount: bigBlindAmount,
    );
    final updatedSeats = <HoldemSeatState>[
      for (final seat in state.seats)
        if (seat.seat == smallBlind.seat)
          _postBlind(seat: seat, contribution: smallContribution)
        else if (seat.seat == bigBlind.seat)
          _postBlind(seat: seat, contribution: bigContribution)
        else
          seat,
    ];
    final currentBetToCall = smallContribution > bigContribution
        ? smallContribution
        : bigContribution;

    return HoldemBlindPostingResult(
      isPosted: true,
      state: state.copyWith(
        phase: HoldemHandPhase.dealingHole,
        seats: updatedSeats,
        pot: state.pot + smallContribution + bigContribution,
        currentBetToCall: currentBetToCall,
        minimumRaiseAmount: bigBlindAmount,
        lastAggressorSeat: state.bigBlindSeat,
        lastActionSummary:
            'blinds_posted_sb_$smallContribution'
            '_bb_$bigContribution',
      ),
    );
  }

  List<String> _validate({
    required HoldemHandState state,
    required int smallBlindAmount,
    required int bigBlindAmount,
  }) {
    final warnings = <String>[];
    if (state.phase != HoldemHandPhase.blindsPosting) {
      warnings.add('ERR_HOLDEM_BLINDS_PHASE');
    }

    final transition = stateMachine.canTransition(
      from: state.phase,
      to: HoldemHandPhase.dealingHole,
    );
    if (!transition.isAllowed) {
      warnings.add('ERR_HOLDEM_BLINDS_TRANSITION');
    }

    if (smallBlindAmount <= 0) {
      warnings.add('ERR_HOLDEM_SMALL_BLIND_AMOUNT');
    }

    if (bigBlindAmount <= 0 || bigBlindAmount < smallBlindAmount) {
      warnings.add('ERR_HOLDEM_BIG_BLIND_AMOUNT');
    }

    if (state.smallBlindSeat == state.bigBlindSeat) {
      warnings.add('ERR_HOLDEM_BLINDS_DUPLICATE_SEAT');
    }

    final smallBlind = state.findSeat(state.smallBlindSeat);
    final bigBlind = state.findSeat(state.bigBlindSeat);
    if (!_canPostBlind(smallBlind)) {
      warnings.add('ERR_HOLDEM_SMALL_BLIND_SEAT');
    }

    if (!_canPostBlind(bigBlind)) {
      warnings.add('ERR_HOLDEM_BIG_BLIND_SEAT');
    }

    if (state.pot != 0 ||
        state.currentBetToCall != 0 ||
        state.seats.any(
          (seat) =>
              seat.committedThisRound != 0 || seat.committedThisHand != 0,
        )) {
      warnings.add('ERR_HOLDEM_BLINDS_ALREADY_POSTED');
    }

    return List<String>.unmodifiable(warnings);
  }

  bool _canPostBlind(HoldemSeatState? seat) {
    return seat != null &&
        seat.inHand &&
        !seat.folded &&
        !seat.allIn &&
        seat.stack > 0;
  }

  int _blindContribution({
    required HoldemSeatState seat,
    required int amount,
  }) {
    return seat.stack < amount ? seat.stack : amount;
  }

  HoldemSeatState _postBlind({
    required HoldemSeatState seat,
    required int contribution,
  }) {
    final stack = seat.stack - contribution;
    return seat.copyWith(
      stack: stack,
      allIn: stack == 0,
      committedThisRound: seat.committedThisRound + contribution,
      committedThisHand: seat.committedThisHand + contribution,
    );
  }
}

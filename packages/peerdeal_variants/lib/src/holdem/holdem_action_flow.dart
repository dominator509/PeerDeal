import 'package:meta/meta.dart';

import 'holdem_hand_state.dart';

@immutable
class HoldemActionFlowResult {
  const HoldemActionFlowResult({
    required this.isBettingRoundComplete,
    this.nextActorSeat,
  });

  final bool isBettingRoundComplete;
  final int? nextActorSeat;
}

class HoldemActionFlow {
  const HoldemActionFlow();

  HoldemActionFlowResult afterAction({
    required HoldemHandState state,
    required int actedSeat,
  }) {
    final activeSeats = state.seats
        .where((seat) => seat.inHand && !seat.folded)
        .toList(growable: false);
    if (activeSeats.length <= 1) {
      return const HoldemActionFlowResult(isBettingRoundComplete: true);
    }

    final actionableSeats = state.seats
        .where(_canTakeVoluntaryAction)
        .toList(growable: false);
    if (actionableSeats.isEmpty) {
      return const HoldemActionFlowResult(isBettingRoundComplete: true);
    }

    final next = _nextSeatNeedingAction(
      state: state,
      actedSeat: actedSeat,
      actionableSeats: actionableSeats,
    );
    if (next == null) {
      return const HoldemActionFlowResult(isBettingRoundComplete: true);
    }

    return HoldemActionFlowResult(
      isBettingRoundComplete: false,
      nextActorSeat: next.seat,
    );
  }

  HoldemSeatState? _nextSeatNeedingAction({
    required HoldemHandState state,
    required int actedSeat,
    required List<HoldemSeatState> actionableSeats,
  }) {
    final orderedSeats = [...state.seats]
      ..sort((a, b) => a.seat.compareTo(b.seat));
    final actedIndex = orderedSeats.indexWhere(
      (seat) => seat.seat == actedSeat,
    );
    if (actedIndex == -1) {
      return null;
    }

    for (var offset = 1; offset <= orderedSeats.length; offset += 1) {
      final candidate =
          orderedSeats[(actedIndex + offset) % orderedSeats.length];
      if (!actionableSeats.any((seat) => seat.seat == candidate.seat)) {
        continue;
      }
      if (_needsAction(state: state, seat: candidate)) {
        return candidate;
      }
    }

    return null;
  }

  bool _canTakeVoluntaryAction(HoldemSeatState seat) {
    return seat.inHand && !seat.folded && !seat.allIn && seat.stack > 0;
  }

  bool _needsAction({
    required HoldemHandState state,
    required HoldemSeatState seat,
  }) {
    if (state.currentBetToCall == 0) {
      return !state.actedSeatsThisRound.contains(seat.seat);
    }

    // Matching the bet is not itself an action. This preserves the big blind
    // option and lets a checked/called seat act once after a short all-in.
    return seat.committedThisRound < state.currentBetToCall ||
        !state.actedSeatsThisRound.contains(seat.seat);
  }
}

import 'package:meta/meta.dart';

import 'holdem_betting_round.dart';
import 'holdem_hand_phase.dart';

@immutable
class HoldemSeatState {
  const HoldemSeatState({
    required this.seat,
    required this.stack,
    required this.inHand,
    required this.folded,
    required this.allIn,
    this.committedThisRound = 0,
    this.committedThisHand = 0,
  });

  final int seat;
  final int stack;
  final bool inHand;
  final bool folded;
  final bool allIn;
  final int committedThisRound;
  final int committedThisHand;

  HoldemSeatState copyWith({
    int? stack,
    bool? inHand,
    bool? folded,
    bool? allIn,
    int? committedThisRound,
    int? committedThisHand,
  }) {
    return HoldemSeatState(
      seat: seat,
      stack: stack ?? this.stack,
      inHand: inHand ?? this.inHand,
      folded: folded ?? this.folded,
      allIn: allIn ?? this.allIn,
      committedThisRound: committedThisRound ?? this.committedThisRound,
      committedThisHand: committedThisHand ?? this.committedThisHand,
    );
  }
}

@immutable
class HoldemHandState {
  const HoldemHandState({
    required this.handId,
    required this.phase,
    required this.bettingRound,
    required this.seats,
    required this.currentActorSeat,
    required this.buttonSeat,
    required this.smallBlindSeat,
    required this.bigBlindSeat,
    required this.currentBetToCall,
    required this.minimumRaiseAmount,
    this.boardCards = const <String>[],
    this.pot = 0,
    this.lastAggressorSeat,
    this.lastActionSummary,
  });

  final String handId;
  final HoldemHandPhase phase;
  final HoldemBettingRound bettingRound;
  final List<HoldemSeatState> seats;
  final int currentActorSeat;
  final int buttonSeat;
  final int smallBlindSeat;
  final int bigBlindSeat;
  final int currentBetToCall;
  final int minimumRaiseAmount;
  final List<String> boardCards;
  final int pot;
  final int? lastAggressorSeat;
  final String? lastActionSummary;

  HoldemSeatState? findSeat(int seat) {
    for (final entry in seats) {
      if (entry.seat == seat) {
        return entry;
      }
    }
    return null;
  }

  HoldemHandState copyWith({
    HoldemHandPhase? phase,
    HoldemBettingRound? bettingRound,
    List<HoldemSeatState>? seats,
    int? currentActorSeat,
    int? currentBetToCall,
    int? minimumRaiseAmount,
    List<String>? boardCards,
    int? pot,
    int? lastAggressorSeat,
    String? lastActionSummary,
  }) {
    return HoldemHandState(
      handId: handId,
      phase: phase ?? this.phase,
      bettingRound: bettingRound ?? this.bettingRound,
      seats: seats ?? this.seats,
      currentActorSeat: currentActorSeat ?? this.currentActorSeat,
      buttonSeat: buttonSeat,
      smallBlindSeat: smallBlindSeat,
      bigBlindSeat: bigBlindSeat,
      currentBetToCall: currentBetToCall ?? this.currentBetToCall,
      minimumRaiseAmount: minimumRaiseAmount ?? this.minimumRaiseAmount,
      boardCards: boardCards ?? this.boardCards,
      pot: pot ?? this.pot,
      lastAggressorSeat: lastAggressorSeat ?? this.lastAggressorSeat,
      lastActionSummary: lastActionSummary ?? this.lastActionSummary,
    );
  }
}

import 'package:meta/meta.dart';

import 'holdem_betting_round.dart';
import 'holdem_hand_phase.dart';
import 'holdem_hand_state.dart';

@immutable
class HoldemPhaseTransitionResult {
  const HoldemPhaseTransitionResult({
    required this.isAllowed,
    required this.nextPhase,
    this.reason,
  });

  final bool isAllowed;
  final HoldemHandPhase nextPhase;
  final String? reason;
}

class HoldemStateMachine {
  const HoldemStateMachine();

  static const Map<HoldemHandPhase, Set<HoldemHandPhase>> _allowed = {
    HoldemHandPhase.handIdle: {HoldemHandPhase.handPreparing},
    HoldemHandPhase.handPreparing: {HoldemHandPhase.blindsPosting},
    HoldemHandPhase.blindsPosting: {HoldemHandPhase.dealingHole},
    HoldemHandPhase.dealingHole: {HoldemHandPhase.bettingPreflop},
    HoldemHandPhase.bettingPreflop: {
      HoldemHandPhase.dealingFlop,
      HoldemHandPhase.settling,
    },
    HoldemHandPhase.dealingFlop: {HoldemHandPhase.bettingFlop},
    HoldemHandPhase.bettingFlop: {
      HoldemHandPhase.dealingTurn,
      HoldemHandPhase.settling,
    },
    HoldemHandPhase.dealingTurn: {HoldemHandPhase.bettingTurn},
    HoldemHandPhase.bettingTurn: {
      HoldemHandPhase.dealingRiver,
      HoldemHandPhase.settling,
    },
    HoldemHandPhase.dealingRiver: {HoldemHandPhase.bettingRiver},
    HoldemHandPhase.bettingRiver: {
      HoldemHandPhase.showdownPrep,
      HoldemHandPhase.settling,
    },
    HoldemHandPhase.showdownPrep: {HoldemHandPhase.showdownReveal},
    HoldemHandPhase.showdownReveal: {HoldemHandPhase.settling},
    HoldemHandPhase.settling: {HoldemHandPhase.handComplete},
    HoldemHandPhase.handComplete: {},
    HoldemHandPhase.handAbortedSafe: {},
  };

  HoldemPhaseTransitionResult canTransition({
    required HoldemHandPhase from,
    required HoldemHandPhase to,
  }) {
    final allowedTargets = _allowed[from] ?? const <HoldemHandPhase>{};
    if (allowedTargets.contains(to)) {
      return HoldemPhaseTransitionResult(isAllowed: true, nextPhase: to);
    }
    return HoldemPhaseTransitionResult(
      isAllowed: false,
      nextPhase: from,
      reason: 'Illegal Hold'em hand phase transition: $from -> $to',
    );
  }

  HoldemHandState openNextStreet({
    required HoldemHandState state,
  }) {
    switch (state.phase) {
      case HoldemHandPhase.bettingPreflop:
        return state.copyWith(
          phase: HoldemHandPhase.dealingFlop,
          bettingRound: HoldemBettingRound.flop,
          boardCards: <String>[...state.boardCards, 'F1', 'F2', 'F3'],
        );
      case HoldemHandPhase.bettingFlop:
        return state.copyWith(
          phase: HoldemHandPhase.dealingTurn,
          bettingRound: HoldemBettingRound.turn,
          boardCards: <String>[...state.boardCards, 'T1'],
        );
      case HoldemHandPhase.bettingTurn:
        return state.copyWith(
          phase: HoldemHandPhase.dealingRiver,
          bettingRound: HoldemBettingRound.river,
          boardCards: <String>[...state.boardCards, 'R1'],
        );
      default:
        return state;
    }
  }
}

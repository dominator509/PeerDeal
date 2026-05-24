import 'package:meta/meta.dart';

import 'holdem_betting_round.dart';
import 'holdem_card_identity.dart';
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

@immutable
class HoldemStreetAdvanceResult {
  const HoldemStreetAdvanceResult({
    required this.isAdvanced,
    required this.state,
    this.warnings = const <String>[],
  });

  final bool isAdvanced;
  final HoldemHandState state;
  final List<String> warnings;
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
      reason: "Illegal Hold'em hand phase transition: $from -> $to",
    );
  }

  HoldemStreetAdvanceResult advanceAfterBettingRound({
    required HoldemHandState state,
    required List<String> dealtBoardCards,
  }) {
    final target = _streetTargetFor(state.phase);
    if (target == null) {
      return HoldemStreetAdvanceResult(
        isAdvanced: false,
        state: state,
        warnings: const <String>['ERR_HOLDEM_STREET_ADVANCE_PHASE'],
      );
    }

    final transition = canTransition(from: state.phase, to: target.phase);
    if (!transition.isAllowed) {
      return HoldemStreetAdvanceResult(
        isAdvanced: false,
        state: state,
        warnings: const <String>['ERR_HOLDEM_STREET_TRANSITION'],
      );
    }

    final warnings = _validateBoardCards(
      state: state,
      dealtBoardCards: dealtBoardCards,
      expectedCount: target.boardCardCount,
    );
    if (warnings.isNotEmpty) {
      return HoldemStreetAdvanceResult(
        isAdvanced: false,
        state: state,
        warnings: warnings,
      );
    }

    return HoldemStreetAdvanceResult(
      isAdvanced: true,
      state: state.copyWith(
        phase: target.phase,
        bettingRound: target.bettingRound,
        seats: _resetStreetCommitments(state.seats),
        currentBetToCall: 0,
        boardCards: <String>[...state.boardCards, ...dealtBoardCards],
      ),
    );
  }

  List<HoldemSeatState> _resetStreetCommitments(List<HoldemSeatState> seats) {
    return <HoldemSeatState>[
      for (final seat in seats) seat.copyWith(committedThisRound: 0),
    ];
  }

  _StreetAdvanceTarget? _streetTargetFor(HoldemHandPhase phase) {
    return switch (phase) {
      HoldemHandPhase.bettingPreflop => const _StreetAdvanceTarget(
        phase: HoldemHandPhase.dealingFlop,
        bettingRound: HoldemBettingRound.flop,
        boardCardCount: 3,
      ),
      HoldemHandPhase.bettingFlop => const _StreetAdvanceTarget(
        phase: HoldemHandPhase.dealingTurn,
        bettingRound: HoldemBettingRound.turn,
        boardCardCount: 1,
      ),
      HoldemHandPhase.bettingTurn => const _StreetAdvanceTarget(
        phase: HoldemHandPhase.dealingRiver,
        bettingRound: HoldemBettingRound.river,
        boardCardCount: 1,
      ),
      HoldemHandPhase.bettingRiver => const _StreetAdvanceTarget(
        phase: HoldemHandPhase.showdownPrep,
        bettingRound: HoldemBettingRound.river,
        boardCardCount: 0,
      ),
      _ => null,
    };
  }

  List<String> _validateBoardCards({
    required HoldemHandState state,
    required List<String> dealtBoardCards,
    required int expectedCount,
  }) {
    final warnings = <String>[];
    if (dealtBoardCards.length != expectedCount) {
      warnings.add('ERR_HOLDEM_STREET_CARD_COUNT');
    }

    if (dealtBoardCards.any((card) => !isHoldemCardIdentity(card))) {
      warnings.add('ERR_HOLDEM_STREET_CARD_FORMAT');
    }

    final allBoardCards = <String>[...state.boardCards, ...dealtBoardCards];
    if (allBoardCards.toSet().length != allBoardCards.length) {
      warnings.add('ERR_HOLDEM_STREET_DUPLICATE_CARD');
    }

    return warnings;
  }
}

class _StreetAdvanceTarget {
  const _StreetAdvanceTarget({
    required this.phase,
    required this.bettingRound,
    required this.boardCardCount,
  });

  final HoldemHandPhase phase;
  final HoldemBettingRound bettingRound;
  final int boardCardCount;
}

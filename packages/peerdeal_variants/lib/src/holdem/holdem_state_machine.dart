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

@immutable
class HoldemBettingRoundOpenResult {
  const HoldemBettingRoundOpenResult({
    required this.isOpened,
    required this.state,
    this.warnings = const <String>[],
  });

  final bool isOpened;
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

  HoldemBettingRoundOpenResult openBettingRoundAfterDeal({
    required HoldemHandState state,
  }) {
    final target = _bettingRoundTargetFor(state.phase);
    if (target == null) {
      return HoldemBettingRoundOpenResult(
        isOpened: false,
        state: state,
        warnings: const <String>['ERR_HOLDEM_BETTING_ROUND_OPEN_PHASE'],
      );
    }

    final transition = canTransition(from: state.phase, to: target.phase);
    if (!transition.isAllowed) {
      return HoldemBettingRoundOpenResult(
        isOpened: false,
        state: state,
        warnings: const <String>['ERR_HOLDEM_BETTING_ROUND_TRANSITION'],
      );
    }

    if (state.boardCards.length != target.boardCardCount) {
      return HoldemBettingRoundOpenResult(
        isOpened: false,
        state: state,
        warnings: const <String>['ERR_HOLDEM_BETTING_ROUND_BOARD_COUNT'],
      );
    }

    final actorSeat = _firstActionableSeatAfterButton(state);
    if (actorSeat == null) {
      return HoldemBettingRoundOpenResult(
        isOpened: false,
        state: state,
        warnings: const <String>['ERR_HOLDEM_BETTING_ROUND_NO_ACTOR'],
      );
    }

    return HoldemBettingRoundOpenResult(
      isOpened: true,
      state: state.copyWith(
        phase: target.phase,
        bettingRound: target.bettingRound,
        currentActorSeat: actorSeat,
        currentBetToCall: 0,
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

  _BettingRoundOpenTarget? _bettingRoundTargetFor(HoldemHandPhase phase) {
    return switch (phase) {
      HoldemHandPhase.dealingFlop => const _BettingRoundOpenTarget(
        phase: HoldemHandPhase.bettingFlop,
        bettingRound: HoldemBettingRound.flop,
        boardCardCount: 3,
      ),
      HoldemHandPhase.dealingTurn => const _BettingRoundOpenTarget(
        phase: HoldemHandPhase.bettingTurn,
        bettingRound: HoldemBettingRound.turn,
        boardCardCount: 4,
      ),
      HoldemHandPhase.dealingRiver => const _BettingRoundOpenTarget(
        phase: HoldemHandPhase.bettingRiver,
        bettingRound: HoldemBettingRound.river,
        boardCardCount: 5,
      ),
      _ => null,
    };
  }

  int? _firstActionableSeatAfterButton(HoldemHandState state) {
    final orderedSeats = [...state.seats]
      ..sort((a, b) => a.seat.compareTo(b.seat));
    if (orderedSeats.isEmpty) {
      return null;
    }

    final buttonIndex = orderedSeats.indexWhere(
      (seat) => seat.seat == state.buttonSeat,
    );
    final startIndex = buttonIndex == -1 ? 0 : buttonIndex + 1;

    for (var offset = 0; offset < orderedSeats.length; offset += 1) {
      final candidate =
          orderedSeats[(startIndex + offset) % orderedSeats.length];
      if (_canTakeVoluntaryAction(candidate)) {
        return candidate.seat;
      }
    }

    return null;
  }

  bool _canTakeVoluntaryAction(HoldemSeatState seat) {
    return seat.inHand && !seat.folded && !seat.allIn && seat.stack > 0;
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

class _BettingRoundOpenTarget {
  const _BettingRoundOpenTarget({
    required this.phase,
    required this.bettingRound,
    required this.boardCardCount,
  });

  final HoldemHandPhase phase;
  final HoldemBettingRound bettingRound;
  final int boardCardCount;
}

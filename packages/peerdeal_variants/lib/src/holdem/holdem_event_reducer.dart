import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'holdem_action_street_coordinator.dart';
import 'holdem_betting_round.dart';
import 'holdem_hand_phase.dart';
import 'holdem_hand_state.dart';
import 'holdem_state_machine.dart';
import 'holdem_table_action.dart';

const holdemNlheVariantId = 'holdem_nlhe';

enum HoldemEventReductionDisposition { applied, rejected }

@immutable
class HoldemEventReductionResult {
  HoldemEventReductionResult._({
    required this.disposition,
    required this.state,
    this.reasonCode,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  HoldemEventReductionResult.applied({
    required HoldemHandState state,
    List<String> warnings = const <String>[],
  }) : this._(
         disposition: HoldemEventReductionDisposition.applied,
         state: state,
         warnings: warnings,
       );

  HoldemEventReductionResult.rejected({
    required HoldemHandState state,
    required String reasonCode,
    List<String> warnings = const <String>[],
  }) : this._(
         disposition: HoldemEventReductionDisposition.rejected,
         state: state,
         reasonCode: reasonCode,
         warnings: warnings,
       );

  final HoldemEventReductionDisposition disposition;
  final HoldemHandState state;
  final String? reasonCode;
  final List<String> warnings;

  bool get isApplied => disposition == HoldemEventReductionDisposition.applied;
  bool get isRejected => !isApplied;
}

/// Reconstructs Hold'em state from the canonical events emitted by the
/// [HoldemCoreProjectionAdapter].
///
/// This reducer intentionally does not evaluate private showdown cards. A
/// receiver can validate the public reveal shape and advance the lifecycle;
/// private cards remain outside the event payload and are owned by the local
/// participant/session boundary.
class HoldemEventReducer {
  const HoldemEventReducer({
    this.actionStreetCoordinator = const HoldemActionStreetCoordinator(),
    this.stateMachine = const HoldemStateMachine(),
  });

  final HoldemActionStreetCoordinator actionStreetCoordinator;
  final HoldemStateMachine stateMachine;

  HoldemEventReductionResult apply({
    required HoldemHandState state,
    required EventEnvelope event,
  }) {
    if (event.eventVersion != '1.0') {
      return _rejected(state, 'ERR_HOLDEM_EVENT_VERSION_UNSUPPORTED');
    }
    if (event.handId != state.handId) {
      return _rejected(state, 'ERR_HOLDEM_EVENT_HAND_MISMATCH');
    }

    try {
      return switch (event.eventType) {
        'HandStarted' => _reduceHandStarted(state, event),
        'PlayerFolded' ||
        'PlayerChecked' ||
        'PlayerCalled' ||
        'PlayerBet' ||
        'PlayerRaised' ||
        'PlayerAllIn' => _reduceAction(state, event),
        'ShowdownStarted' => _reduceShowdownStarted(state, event),
        'ShowdownRevealed' => _reduceShowdownRevealed(state, event),
        'SettlementProjected' => _reduceSettlementProjected(state, event),
        'SettlementBlocked' => _reduceSettlementBlocked(state, event),
        'HandSettled' => _reduceHandSettled(state, event),
        _ => _rejected(state, 'ERR_HOLDEM_EVENT_TYPE_UNSUPPORTED'),
      };
    } on _HoldemPayloadFailure catch (failure) {
      return _rejected(state, failure.reasonCode);
    } on Object {
      return _rejected(state, 'ERR_HOLDEM_EVENT_PAYLOAD_INVALID');
    }
  }

  HoldemEventReductionResult _reduceHandStarted(
    HoldemHandState state,
    EventEnvelope event,
  ) {
    _requireVariant(event.payload);
    final handId = _requiredString(event.payload, 'hand_id');
    if (handId != state.handId || event.handId != handId) {
      return _rejected(state, 'ERR_HOLDEM_EVENT_HAND_MISMATCH');
    }
    if (_requiredInt(event.payload, 'button_seat') != state.buttonSeat ||
        _requiredInt(event.payload, 'small_blind_seat') !=
            state.smallBlindSeat ||
        _requiredInt(event.payload, 'big_blind_seat') != state.bigBlindSeat) {
      return _rejected(state, 'ERR_HOLDEM_HAND_START_CONFIGURATION_MISMATCH');
    }

    return HoldemEventReductionResult.applied(state: state);
  }

  HoldemEventReductionResult _reduceAction(
    HoldemHandState state,
    EventEnvelope event,
  ) {
    _requireVariant(event.payload);
    final actionType = _actionTypeForEvent(event.eventType);
    final payloadActionType = _requiredString(event.payload, 'action_type');
    if (payloadActionType != actionType.name) {
      return _rejected(state, 'ERR_HOLDEM_ACTION_EVENT_TYPE_MISMATCH');
    }

    final actorSeat = _requiredInt(event.payload, 'actor_seat');
    final amount = _requiredInt(event.payload, 'amount');
    final contribution = _requiredInt(event.payload, 'contribution');
    final dealtBoardCards = _requiredStringList(
      event.payload,
      'dealt_board_cards',
    );
    final projectedBoardCards = _requiredStringList(
      event.payload,
      'board_cards',
    );
    final projectedPhase = _phaseFromPayload(event.payload, 'phase');
    final projectedBettingRound = _bettingRoundFromPayload(
      event.payload,
      'betting_round',
    );

    final actorBefore = state.findSeat(actorSeat);
    final actionResult = actionStreetCoordinator.applyAndAdvanceIfComplete(
      state: state,
      action: HoldemTableAction(
        actorSeat: actorSeat,
        type: actionType,
        amount: amount,
      ),
      dealtBoardCards: dealtBoardCards,
      openNextBettingRound:
          _isBettingPhase(projectedPhase) && projectedPhase != state.phase,
    );
    if (!actionResult.isActionApplied) {
      return _rejected(
        state,
        actionResult.action.validation.reasonCode ??
            'ERR_HOLDEM_ACTION_REJECTED',
      );
    }

    final projectedState = actionResult.state;
    if (projectedState.phase != projectedPhase ||
        projectedState.bettingRound != projectedBettingRound ||
        projectedState.pot != _requiredInt(event.payload, 'pot') ||
        projectedState.currentBetToCall !=
            _requiredInt(event.payload, 'current_bet_to_call') ||
        projectedState.minimumRaiseAmount !=
            _requiredInt(event.payload, 'minimum_raise_amount') ||
        !_sameStrings(projectedState.boardCards, projectedBoardCards)) {
      return _rejected(state, 'ERR_HOLDEM_ACTION_PROJECTION_MISMATCH');
    }

    final actorAfter = projectedState.findSeat(actorSeat);
    final expectedContribution = actorBefore == null || actorAfter == null
        ? 0
        : actorAfter.committedThisHand - actorBefore.committedThisHand;
    if (contribution != expectedContribution) {
      return _rejected(state, 'ERR_HOLDEM_ACTION_PROJECTION_MISMATCH');
    }

    if (actionResult.street?.isAdvanced != true && dealtBoardCards.isNotEmpty) {
      return _rejected(state, 'ERR_HOLDEM_ACTION_BOARD_PROJECTION_MISMATCH');
    }
    if (actionResult.street?.isAdvanced != true &&
        !_sameStrings(state.boardCards, projectedBoardCards)) {
      return _rejected(state, 'ERR_HOLDEM_ACTION_BOARD_PROJECTION_MISMATCH');
    }

    final expectedNextActor = actionResult.action.nextActorSeat;
    final payloadNextActor = event.payload['next_actor_seat'];
    if (expectedNextActor == null) {
      if (payloadNextActor != null) {
        return _rejected(state, 'ERR_HOLDEM_ACTION_PROJECTION_MISMATCH');
      }
    } else if (payloadNextActor != expectedNextActor) {
      return _rejected(state, 'ERR_HOLDEM_ACTION_PROJECTION_MISMATCH');
    }

    return HoldemEventReductionResult.applied(state: projectedState);
  }

  HoldemEventReductionResult _reduceShowdownStarted(
    HoldemHandState state,
    EventEnvelope event,
  ) {
    _requireVariant(event.payload);
    final boardCards = _requiredStringList(event.payload, 'board_cards');
    if (state.phase != HoldemHandPhase.showdownPrep) {
      return _rejected(state, 'ERR_HOLDEM_SHOWDOWN_START_PHASE');
    }
    if (!_sameStrings(state.boardCards, boardCards)) {
      return _rejected(state, 'ERR_HOLDEM_SHOWDOWN_BOARD_MISMATCH');
    }
    return HoldemEventReductionResult.applied(state: state);
  }

  HoldemEventReductionResult _reduceShowdownRevealed(
    HoldemHandState state,
    EventEnvelope event,
  ) {
    _requireVariant(event.payload);
    if (state.phase != HoldemHandPhase.showdownPrep) {
      return _rejected(state, 'ERR_HOLDEM_SHOWDOWN_REVEAL_PHASE');
    }
    _validateShowdownResults(state, event.payload['results']);
    final transition = stateMachine.canTransition(
      from: state.phase,
      to: HoldemHandPhase.showdownReveal,
    );
    if (!transition.isAllowed) {
      return _rejected(state, 'ERR_HOLDEM_SHOWDOWN_REVEAL_TRANSITION');
    }
    return HoldemEventReductionResult.applied(
      state: state.copyWith(phase: HoldemHandPhase.showdownReveal),
    );
  }

  HoldemEventReductionResult _reduceSettlementProjected(
    HoldemHandState state,
    EventEnvelope event,
  ) {
    _requireVariant(event.payload);
    _requireIdentity(_requiredString(event.payload, 'projection_id'));
    _validateAwards(state, event.payload['awards']);
    return _advancePhase(state, HoldemHandPhase.settling);
  }

  HoldemEventReductionResult _reduceSettlementBlocked(
    HoldemHandState state,
    EventEnvelope event,
  ) {
    _requireVariant(event.payload);
    _requireIdentity(_requiredString(event.payload, 'projection_id'));
    _requiredStringList(event.payload, 'reason_codes');
    _requiredStringList(event.payload, 'warnings');
    if (state.phase != HoldemHandPhase.showdownReveal &&
        state.phase != HoldemHandPhase.settling) {
      return _rejected(state, 'ERR_HOLDEM_SETTLEMENT_PHASE');
    }
    return _advancePhase(state, HoldemHandPhase.settling);
  }

  HoldemEventReductionResult _reduceHandSettled(
    HoldemHandState state,
    EventEnvelope event,
  ) {
    _requireVariant(event.payload);
    _requireIdentity(_requiredString(event.payload, 'settlement_id'));
    _requireIdentity(_requiredString(event.payload, 'projection_id'));
    return _advancePhase(state, HoldemHandPhase.handComplete);
  }

  HoldemEventReductionResult _advancePhase(
    HoldemHandState state,
    HoldemHandPhase targetPhase,
  ) {
    if (state.phase == targetPhase) {
      return HoldemEventReductionResult.applied(state: state);
    }
    final transition = stateMachine.canTransition(
      from: state.phase,
      to: targetPhase,
    );
    if (!transition.isAllowed) {
      return _rejected(state, 'ERR_HOLDEM_EVENT_PHASE_TRANSITION');
    }
    return HoldemEventReductionResult.applied(
      state: state.copyWith(phase: targetPhase),
    );
  }

  HoldemTableActionType _actionTypeForEvent(String eventType) {
    return switch (eventType) {
      'PlayerFolded' => HoldemTableActionType.fold,
      'PlayerChecked' => HoldemTableActionType.check,
      'PlayerCalled' => HoldemTableActionType.call,
      'PlayerBet' => HoldemTableActionType.bet,
      'PlayerRaised' => HoldemTableActionType.raise,
      'PlayerAllIn' => HoldemTableActionType.allIn,
      _ => throw StateError('Unsupported Holdem action event.'),
    };
  }

  void _requireVariant(Map<String, Object?> payload) {
    if (_requiredString(payload, 'variant_id') != holdemNlheVariantId) {
      throw const _HoldemPayloadFailure('ERR_HOLDEM_VARIANT_MISMATCH');
    }
  }

  void _validateShowdownResults(HoldemHandState state, Object? rawResults) {
    if (rawResults is! List || rawResults.isEmpty) {
      throw const _HoldemPayloadFailure('ERR_HOLDEM_SHOWDOWN_RESULTS_INVALID');
    }
    final seats = <int>{};
    for (final rawResult in rawResults) {
      if (rawResult is! Map) {
        throw const _HoldemPayloadFailure(
          'ERR_HOLDEM_SHOWDOWN_RESULTS_INVALID',
        );
      }
      final seat = rawResult['seat'];
      final rankIndex = rawResult['rank_index'];
      final summary = rawResult['summary'];
      if (seat is! int ||
          rankIndex is! int ||
          rankIndex < 0 ||
          summary is! String ||
          summary.trim().isEmpty ||
          !seats.add(seat) ||
          state.findSeat(seat) == null) {
        throw const _HoldemPayloadFailure(
          'ERR_HOLDEM_SHOWDOWN_RESULTS_INVALID',
        );
      }
    }
  }

  void _validateAwards(HoldemHandState state, Object? rawAwards) {
    if (rawAwards is! List || rawAwards.isEmpty) {
      throw const _HoldemPayloadFailure('ERR_HOLDEM_SETTLEMENT_AWARDS_INVALID');
    }
    var totalAwarded = 0;
    for (final rawAward in rawAwards) {
      if (rawAward is! Map ||
          rawAward['seat_id'] is! String ||
          (rawAward['seat_id'] as String).trim().isEmpty ||
          rawAward['amount'] is! int ||
          (rawAward['amount'] as int) <= 0) {
        throw const _HoldemPayloadFailure(
          'ERR_HOLDEM_SETTLEMENT_AWARDS_INVALID',
        );
      }
      totalAwarded += rawAward['amount'] as int;
    }
    if (totalAwarded != state.pot) {
      throw const _HoldemPayloadFailure(
        'ERR_HOLDEM_SETTLEMENT_AWARDS_POT_MISMATCH',
      );
    }
  }

  HoldemHandPhase _phaseFromPayload(Map<String, Object?> payload, String key) {
    final value = _requiredString(payload, key);
    return _phaseByName(value);
  }

  HoldemBettingRound _bettingRoundFromPayload(
    Map<String, Object?> payload,
    String key,
  ) {
    final value = _requiredString(payload, key);
    for (final round in HoldemBettingRound.values) {
      if (round.name == value) return round;
    }
    throw const _HoldemPayloadFailure('ERR_HOLDEM_BETTING_ROUND_INVALID');
  }

  HoldemHandPhase _phaseByName(String value) {
    for (final phase in HoldemHandPhase.values) {
      if (phase.name == value) return phase;
    }
    throw const _HoldemPayloadFailure('ERR_HOLDEM_PHASE_INVALID');
  }

  String _requiredString(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw _HoldemPayloadFailure('ERR_HOLDEM_EVENT_PAYLOAD_INVALID');
    }
    return value;
  }

  int _requiredInt(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! int) {
      throw _HoldemPayloadFailure('ERR_HOLDEM_EVENT_PAYLOAD_INVALID');
    }
    return value;
  }

  List<String> _requiredStringList(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! List) {
      throw _HoldemPayloadFailure('ERR_HOLDEM_EVENT_PAYLOAD_INVALID');
    }
    final strings = <String>[];
    for (final item in value) {
      if (item is! String || item.trim().isEmpty || item != item.trim()) {
        throw _HoldemPayloadFailure('ERR_HOLDEM_EVENT_PAYLOAD_INVALID');
      }
      strings.add(item);
    }
    return List<String>.unmodifiable(strings);
  }

  void _requireIdentity(String value) {
    if (value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
      throw const _HoldemPayloadFailure('ERR_HOLDEM_EVENT_PAYLOAD_INVALID');
    }
  }

  bool _isBettingPhase(HoldemHandPhase phase) {
    return phase == HoldemHandPhase.bettingPreflop ||
        phase == HoldemHandPhase.bettingFlop ||
        phase == HoldemHandPhase.bettingTurn ||
        phase == HoldemHandPhase.bettingRiver;
  }

  bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  HoldemEventReductionResult _rejected(
    HoldemHandState state,
    String reasonCode,
  ) {
    return HoldemEventReductionResult.rejected(
      state: state,
      reasonCode: reasonCode,
    );
  }
}

class _HoldemPayloadFailure implements Exception {
  const _HoldemPayloadFailure(this.reasonCode);

  final String reasonCode;
}

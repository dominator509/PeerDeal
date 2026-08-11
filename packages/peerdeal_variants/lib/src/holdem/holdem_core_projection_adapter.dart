import 'package:meta/meta.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'holdem_action_street_coordinator.dart';
import '../contracts/showdown_models.dart';
import 'holdem_hand_phase.dart';
import 'holdem_hand_state.dart';
import 'holdem_settlement_blocked_event_builder.dart';
import 'holdem_settlement_projected_event_builder.dart';
import 'holdem_showdown_coordinator.dart';
import 'holdem_table_action.dart';
import 'holdem_hand_settled_event_builder.dart';

typedef HoldemEventIdFactory = String Function(String eventType, int eventSeq);
typedef HoldemEventTimestampFactory = String Function();
typedef HoldemEventHashFactory =
    String Function(Map<String, Object?> canonicalEvent);

/// An immutable cursor for constructing one contiguous protocol event stream.
///
/// The cursor owns sequence and hash-chain continuity, while the caller owns
/// event id and timestamp policy through the injected factories. The default
/// event hash covers every envelope field except `event_hash` itself.
class HoldemEventCursor {
  HoldemEventCursor({
    required this.protocolVersion,
    required this.tableId,
    required this.sessionId,
    required this.nextEventSeq,
    required this.previousEventHash,
    required this.actorRef,
    required this.eventIdFactory,
    required this.emittedAtFactory,
    this.eventHashFactory = _defaultEventHash,
    this.lastEventType,
  }) {
    _requireIdentity(protocolVersion, 'protocolVersion');
    _requireIdentity(tableId, 'tableId');
    _requireIdentity(sessionId, 'sessionId');
    _requireIdentity(previousEventHash, 'previousEventHash');
    _requireIdentity(actorRef, 'actorRef');
    if (nextEventSeq < 1) {
      throw ArgumentError.value(
        nextEventSeq,
        'nextEventSeq',
        'Event sequence must be positive.',
      );
    }
  }

  factory HoldemEventCursor.fromJson(
    Map<String, Object?> json, {
    required HoldemEventIdFactory eventIdFactory,
    required HoldemEventTimestampFactory emittedAtFactory,
    HoldemEventHashFactory eventHashFactory = _defaultEventHash,
  }) {
    return HoldemEventCursor(
      protocolVersion: _cursorRequiredString(json, 'protocol_version'),
      tableId: _cursorRequiredString(json, 'table_id'),
      sessionId: _cursorRequiredString(json, 'session_id'),
      nextEventSeq: _cursorRequiredInt(json, 'next_event_seq'),
      previousEventHash: _cursorRequiredString(json, 'previous_event_hash'),
      actorRef: _cursorRequiredString(json, 'actor_ref'),
      eventIdFactory: eventIdFactory,
      emittedAtFactory: emittedAtFactory,
      eventHashFactory: eventHashFactory,
      lastEventType: _cursorNullableString(json, 'last_event_type'),
    );
  }

  final String protocolVersion;
  final String tableId;
  final String sessionId;
  final int nextEventSeq;
  final String previousEventHash;
  final String actorRef;
  final HoldemEventIdFactory eventIdFactory;
  final HoldemEventTimestampFactory emittedAtFactory;
  final HoldemEventHashFactory eventHashFactory;
  final String? lastEventType;

  Map<String, Object?> toJson() => <String, Object?>{
    'protocol_version': protocolVersion,
    'table_id': tableId,
    'session_id': sessionId,
    'next_event_seq': nextEventSeq,
    'previous_event_hash': previousEventHash,
    'actor_ref': actorRef,
    'last_event_type': lastEventType,
  };

  HoldemEventCursorResult issue({
    required String eventType,
    required Map<String, Object?> payload,
    String? handId,
    String? actorRef,
    String? eventId,
    String? emittedAt,
  }) {
    _requireIdentity(eventType, 'eventType');
    final resolvedActorRef = actorRef ?? this.actorRef;
    final resolvedEventId = eventId ?? eventIdFactory(eventType, nextEventSeq);
    final resolvedEmittedAt = emittedAt ?? emittedAtFactory();
    _requireIdentity(resolvedActorRef, 'actorRef');
    _requireIdentity(resolvedEventId, 'eventId');
    _requireIdentity(resolvedEmittedAt, 'emittedAt');
    if (handId != null) {
      _requireIdentity(handId, 'handId');
    }

    final eventPayload = Map<String, Object?>.unmodifiable(payload);
    final canonicalEvent = <String, Object?>{
      'event_id': resolvedEventId,
      'event_type': eventType,
      'event_version': '1.0',
      'protocol_version': protocolVersion,
      'event_seq': nextEventSeq,
      'table_id': tableId,
      'session_id': sessionId,
      'hand_id': handId,
      'emitted_at': resolvedEmittedAt,
      'actor_ref': resolvedActorRef,
      'payload': eventPayload,
      'prev_event_hash': previousEventHash,
    };
    final event = EventEnvelope(
      eventId: resolvedEventId,
      eventType: eventType,
      eventVersion: '1.0',
      protocolVersion: protocolVersion,
      eventSeq: nextEventSeq,
      tableId: tableId,
      sessionId: sessionId,
      handId: handId,
      emittedAt: resolvedEmittedAt,
      actorRef: resolvedActorRef,
      payload: eventPayload,
      prevEventHash: previousEventHash,
      eventHash: eventHashFactory(
        Map<String, Object?>.unmodifiable(canonicalEvent),
      ),
    );
    _requireIdentity(event.eventHash, 'eventHash');
    final compatibility = const ProtocolCatalog().checkEventEnvelope(event);
    if (!compatibility.isSupported) {
      throw ArgumentError.value(
        eventType,
        'eventType',
        'Event is not supported by the protocol catalog.',
      );
    }

    return HoldemEventCursorResult(
      event: event,
      cursor: HoldemEventCursor(
        protocolVersion: protocolVersion,
        tableId: tableId,
        sessionId: sessionId,
        nextEventSeq: nextEventSeq + 1,
        previousEventHash: event.eventHash,
        actorRef: this.actorRef,
        eventIdFactory: eventIdFactory,
        emittedAtFactory: emittedAtFactory,
        eventHashFactory: eventHashFactory,
        lastEventType: event.eventType,
      ),
    );
  }

  /// Accepts one event from the same contiguous stream without issuing a new
  /// event id or timestamp.
  ///
  /// Remote acceptance verifies the stream identity, sequence, hash link,
  /// protocol catalog entry, and event hash before advancing the cursor.
  HoldemEventCursorAcceptanceResult accept(EventEnvelope event) {
    if (event.protocolVersion != protocolVersion ||
        event.tableId != tableId ||
        event.sessionId != sessionId) {
      return HoldemEventCursorAcceptanceResult.rejected(
        cursor: this,
        reasonCode: 'ERR_HOLDEM_EVENT_CURSOR_SCOPE_MISMATCH',
      );
    }
    if (event.eventSeq != nextEventSeq) {
      return HoldemEventCursorAcceptanceResult.rejected(
        cursor: this,
        reasonCode: 'ERR_HOLDEM_EVENT_CURSOR_SEQUENCE_GAP',
      );
    }
    if (event.prevEventHash != previousEventHash) {
      return HoldemEventCursorAcceptanceResult.rejected(
        cursor: this,
        reasonCode: 'ERR_HOLDEM_EVENT_CURSOR_HASH_CHAIN_BREAK',
      );
    }

    final compatibility = const ProtocolCatalog().checkEventEnvelope(event);
    if (!compatibility.isSupported) {
      return HoldemEventCursorAcceptanceResult.rejected(
        cursor: this,
        reasonCode: 'ERR_HOLDEM_EVENT_CURSOR_UNSUPPORTED_EVENT',
      );
    }

    try {
      _requireIdentity(event.eventId, 'eventId');
      _requireIdentity(event.eventType, 'eventType');
      _requireIdentity(event.eventVersion, 'eventVersion');
      _requireIdentity(event.emittedAt, 'emittedAt');
      _requireIdentity(event.actorRef, 'actorRef');
      _requireIdentity(event.eventHash, 'eventHash');
      final expectedHash = eventHashFactory(
        Map<String, Object?>.unmodifiable(_canonicalEvent(event)),
      );
      if (expectedHash != event.eventHash) {
        return HoldemEventCursorAcceptanceResult.rejected(
          cursor: this,
          reasonCode: 'ERR_HOLDEM_EVENT_CURSOR_HASH_INVALID',
        );
      }
    } on Object {
      return HoldemEventCursorAcceptanceResult.rejected(
        cursor: this,
        reasonCode: 'ERR_HOLDEM_EVENT_CURSOR_EVENT_INVALID',
      );
    }

    return HoldemEventCursorAcceptanceResult.accepted(
      cursor: HoldemEventCursor(
        protocolVersion: protocolVersion,
        tableId: tableId,
        sessionId: sessionId,
        nextEventSeq: nextEventSeq + 1,
        previousEventHash: event.eventHash,
        actorRef: actorRef,
        eventIdFactory: eventIdFactory,
        emittedAtFactory: emittedAtFactory,
        eventHashFactory: eventHashFactory,
        lastEventType: event.eventType,
      ),
    );
  }

  Map<String, Object?> _canonicalEvent(EventEnvelope event) {
    return <String, Object?>{
      'event_id': event.eventId,
      'event_type': event.eventType,
      'event_version': event.eventVersion,
      'protocol_version': event.protocolVersion,
      'event_seq': event.eventSeq,
      'table_id': event.tableId,
      'session_id': event.sessionId,
      'hand_id': event.handId,
      'emitted_at': event.emittedAt,
      'actor_ref': event.actorRef,
      'payload': Map<String, Object?>.unmodifiable(event.payload),
      'prev_event_hash': event.prevEventHash,
    };
  }
}

@immutable
class HoldemEventCursorResult {
  const HoldemEventCursorResult({required this.event, required this.cursor});

  final EventEnvelope event;
  final HoldemEventCursor cursor;
}

@immutable
class HoldemEventCursorAcceptanceResult {
  const HoldemEventCursorAcceptanceResult._({
    required this.isAccepted,
    required this.cursor,
    this.reasonCode,
  });

  const HoldemEventCursorAcceptanceResult.accepted({
    required HoldemEventCursor cursor,
  }) : this._(isAccepted: true, cursor: cursor);

  const HoldemEventCursorAcceptanceResult.rejected({
    required HoldemEventCursor cursor,
    required String reasonCode,
  }) : this._(isAccepted: false, cursor: cursor, reasonCode: reasonCode);

  final bool isAccepted;
  final HoldemEventCursor cursor;
  final String? reasonCode;

  bool get isRejected => !isAccepted;
}

@immutable
class HoldemCoreProjectionResult {
  const HoldemCoreProjectionResult({
    required this.isApplied,
    required this.coreState,
    required this.handState,
    required this.cursor,
    required this.events,
    this.warnings = const <String>[],
    this.reasonCode,
    this.actionResult,
    this.showdownResult,
    this.settlementResult,
    this.completionResult,
  });

  final bool isApplied;
  final TableState coreState;
  final HoldemHandState handState;
  final HoldemEventCursor cursor;
  final List<EventEnvelope> events;
  final List<String> warnings;
  final String? reasonCode;
  final HoldemActionStreetResult? actionResult;
  final HoldemShowdownRevealResult? showdownResult;
  final HoldemSettlementProjectionGateResult? settlementResult;
  final HoldemHandCompletionGateResult? completionResult;

  bool get isRejected => !isApplied;
}

/// Connects Hold'em variant transitions to canonical protocol events and the
/// universal deterministic core reducer.
///
/// This adapter is intentionally variant-owned. `peerdeal_core` only sees the
/// resulting protocol envelopes and remains unaware of Hold'em rules.
class HoldemCoreProjectionAdapter {
  const HoldemCoreProjectionAdapter({
    this.actionStreetCoordinator = const HoldemActionStreetCoordinator(),
    this.showdownCoordinator = const HoldemShowdownCoordinator(),
    this.coreReducer = const CoreReducer(),
    this.settlementBlockedBuilder = const HoldemSettlementBlockedEventBuilder(),
    this.settlementProjectedBuilder =
        const HoldemSettlementProjectedEventBuilder(),
    this.handSettledBuilder = const HoldemHandSettledEventBuilder(),
  });

  final HoldemActionStreetCoordinator actionStreetCoordinator;
  final HoldemShowdownCoordinator showdownCoordinator;
  final CoreReducer coreReducer;
  final HoldemSettlementBlockedEventBuilder settlementBlockedBuilder;
  final HoldemSettlementProjectedEventBuilder settlementProjectedBuilder;
  final HoldemHandSettledEventBuilder handSettledBuilder;

  HoldemCoreProjectionResult startHand({
    required TableState coreState,
    required HoldemHandState handState,
    required HoldemEventCursor cursor,
    String? actorRef,
  }) {
    if (coreState.hasActiveHand) {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: 'ERR_HOLDEM_CORE_HAND_ALREADY_ACTIVE',
      );
    }

    final events = <EventEnvelope>[];
    var nextCursor = cursor;
    try {
      final issued = nextCursor.issue(
        eventType: 'HandStarted',
        handId: handState.handId,
        actorRef: actorRef,
        payload: <String, Object?>{
          'hand_id': handState.handId,
          'variant_id': 'holdem_nlhe',
          'button_seat': handState.buttonSeat,
          'small_blind_seat': handState.smallBlindSeat,
          'big_blind_seat': handState.bigBlindSeat,
        },
      );
      events.add(issued.event);
      nextCursor = issued.cursor;
    } on Object {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: 'ERR_HOLDEM_EVENT_ENVELOPE_INVALID',
      );
    }

    return _applyEvents(
      coreState: coreState,
      handState: handState,
      cursor: cursor,
      nextCursor: nextCursor,
      events: events,
      nextHandState: handState,
    );
  }

  HoldemCoreProjectionResult applyAction({
    required TableState coreState,
    required HoldemHandState handState,
    required HoldemTableAction action,
    required HoldemEventCursor cursor,
    List<String> dealtBoardCards = const <String>[],
    bool openNextBettingRound = false,
    String? actorRef,
  }) {
    final actionResult = actionStreetCoordinator.applyAndAdvanceIfComplete(
      state: handState,
      action: action,
      dealtBoardCards: dealtBoardCards,
      openNextBettingRound: openNextBettingRound,
    );
    if (!actionResult.isActionApplied) {
      final reasonCode =
          actionResult.action.validation.reasonCode ??
          'ERR_HOLDEM_ACTION_REJECTED';
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: reasonCode,
        warnings: actionResult.warnings,
        actionResult: actionResult,
      );
    }

    final events = <EventEnvelope>[];
    var nextCursor = cursor;
    try {
      final actorBefore = handState.findSeat(action.actorSeat);
      final actorAfter = actionResult.state.findSeat(action.actorSeat);
      final contribution = actorBefore == null || actorAfter == null
          ? 0
          : actorAfter.committedThisHand - actorBefore.committedThisHand;
      final actionEventType = _eventTypeForAction(action);
      final actionEvent = nextCursor.issue(
        eventType: actionEventType,
        handId: handState.handId,
        actorRef: actorRef,
        payload: <String, Object?>{
          'variant_id': 'holdem_nlhe',
          'actor_seat': action.actorSeat,
          'action_type': action.type.name,
          'amount': action.amount,
          'contribution': contribution,
          'dealt_board_cards': List<String>.unmodifiable(dealtBoardCards),
          'board_cards': List<String>.unmodifiable(
            actionResult.state.boardCards,
          ),
          'phase': actionResult.state.phase.name,
          'betting_round': actionResult.state.bettingRound.name,
          'pot': actionResult.state.pot,
          'current_bet_to_call': actionResult.state.currentBetToCall,
          'minimum_raise_amount': actionResult.state.minimumRaiseAmount,
          if (actionResult.action.nextActorSeat != null)
            'next_actor_seat': actionResult.action.nextActorSeat,
        },
      );
      events.add(actionEvent.event);
      nextCursor = actionEvent.cursor;

      if (actionResult.street?.isAdvanced == true &&
          actionResult.state.phase == HoldemHandPhase.showdownPrep) {
        final showdownStarted = nextCursor.issue(
          eventType: 'ShowdownStarted',
          handId: handState.handId,
          actorRef: actorRef,
          payload: <String, Object?>{
            'variant_id': 'holdem_nlhe',
            'board_cards': List<String>.unmodifiable(
              actionResult.state.boardCards,
            ),
          },
        );
        events.add(showdownStarted.event);
        nextCursor = showdownStarted.cursor;
      }
    } on Object {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: 'ERR_HOLDEM_EVENT_ENVELOPE_INVALID',
        warnings: actionResult.warnings,
        actionResult: actionResult,
      );
    }

    return _applyEvents(
      coreState: coreState,
      handState: handState,
      cursor: cursor,
      nextCursor: nextCursor,
      events: events,
      nextHandState: actionResult.state,
      warnings: actionResult.warnings,
      actionResult: actionResult,
    );
  }

  HoldemCoreProjectionResult revealShowdown({
    required TableState coreState,
    required HoldemHandState handState,
    required ShowdownEvaluationInput input,
    required HoldemEventCursor cursor,
    String? actorRef,
  }) {
    final reveal = showdownCoordinator.reveal(state: handState, input: input);
    if (!reveal.isRevealed) {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: reveal.warnings.isEmpty
            ? 'ERR_HOLDEM_SHOWDOWN_REVEAL_REJECTED'
            : reveal.warnings.first,
        warnings: reveal.warnings,
        showdownResult: reveal,
      );
    }

    final events = <EventEnvelope>[];
    var nextCursor = cursor;
    try {
      if (nextCursor.lastEventType != 'ShowdownStarted') {
        final showdownStarted = nextCursor.issue(
          eventType: 'ShowdownStarted',
          handId: handState.handId,
          actorRef: actorRef,
          payload: <String, Object?>{
            'variant_id': 'holdem_nlhe',
            'board_cards': List<String>.unmodifiable(handState.boardCards),
          },
        );
        events.add(showdownStarted.event);
        nextCursor = showdownStarted.cursor;
      }

      final revealed = nextCursor.issue(
        eventType: 'ShowdownRevealed',
        handId: handState.handId,
        actorRef: actorRef,
        payload: <String, Object?>{
          'variant_id': 'holdem_nlhe',
          'results': <Map<String, Object?>>[
            for (final result in reveal.evaluation.results)
              <String, Object?>{
                'seat': result.seat,
                'rank_index': result.rankIndex,
                'summary': result.summary,
              },
          ],
        },
      );
      events.add(revealed.event);
      nextCursor = revealed.cursor;
    } on Object {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: 'ERR_HOLDEM_EVENT_ENVELOPE_INVALID',
        showdownResult: reveal,
      );
    }

    return _applyEvents(
      coreState: coreState,
      handState: handState,
      cursor: cursor,
      nextCursor: nextCursor,
      events: events,
      nextHandState: reveal.state,
      showdownResult: reveal,
    );
  }

  HoldemCoreProjectionResult projectSettlement({
    required TableState coreState,
    required HoldemHandState handState,
    required HoldemSettlementProjectionGateResult settlement,
    required HoldemHandCompletionGateResult completion,
    required HoldemEventCursor cursor,
    required String projectionId,
    required String settlementId,
    String? actorRef,
  }) {
    try {
      _requireIdentity(projectionId, 'projectionId');
      _requireIdentity(settlementId, 'settlementId');
    } on ArgumentError {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: 'ERR_HOLDEM_SETTLEMENT_ID_INVALID',
      );
    }

    if (settlement.isProjected != completion.isCompleted) {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: 'ERR_HOLDEM_SETTLEMENT_COMPLETION_MISMATCH',
        settlementResult: settlement,
        completionResult: completion,
      );
    }

    final events = <EventEnvelope>[];
    var nextCursor = cursor;
    try {
      if (!settlement.isProjected) {
        final draft = settlementBlockedBuilder.buildDraft(
          settlement: settlement,
          projectionId: projectionId,
        );
        final blocked = nextCursor.issue(
          eventType: HoldemSettlementBlockedEventBuilder.eventType,
          handId: handState.handId,
          actorRef: actorRef,
          payload: draft.payload,
        );
        events.add(blocked.event);
        nextCursor = blocked.cursor;
      } else {
        final projectedDraft = settlementProjectedBuilder.buildDraft(
          settlement: settlement,
          projectionId: projectionId,
        );
        final projected = nextCursor.issue(
          eventType: HoldemSettlementProjectedEventBuilder.eventType,
          handId: handState.handId,
          actorRef: actorRef,
          payload: projectedDraft.payload,
        );
        events.add(projected.event);
        nextCursor = projected.cursor;

        final settledDraft = handSettledBuilder.buildDraft(
          completion: completion,
          settlementId: settlementId,
          projectionId: projectionId,
        );
        final settled = nextCursor.issue(
          eventType: HoldemHandSettledEventBuilder.eventType,
          handId: handState.handId,
          actorRef: actorRef,
          payload: settledDraft.payload,
        );
        events.add(settled.event);
        nextCursor = settled.cursor;
      }
    } on Object {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: 'ERR_HOLDEM_EVENT_ENVELOPE_INVALID',
        settlementResult: settlement,
        completionResult: completion,
      );
    }

    return _applyEvents(
      coreState: coreState,
      handState: handState,
      cursor: cursor,
      nextCursor: nextCursor,
      events: events,
      nextHandState: completion.isCompleted
          ? completion.state
          : settlement.state,
      warnings: settlement.warnings,
      settlementResult: settlement,
      completionResult: completion,
    );
  }

  HoldemCoreProjectionResult _applyEvents({
    required TableState coreState,
    required HoldemHandState handState,
    required HoldemEventCursor cursor,
    required HoldemEventCursor nextCursor,
    required List<EventEnvelope> events,
    required HoldemHandState nextHandState,
    List<String> warnings = const <String>[],
    HoldemActionStreetResult? actionResult,
    HoldemShowdownRevealResult? showdownResult,
    HoldemSettlementProjectionGateResult? settlementResult,
    HoldemHandCompletionGateResult? completionResult,
  }) {
    var projected = coreState;
    try {
      for (final event in events) {
        projected = coreReducer.apply(projected, event);
      }
    } on InvariantViolation catch (error) {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: error.code,
        warnings: warnings,
        actionResult: actionResult,
        showdownResult: showdownResult,
        settlementResult: settlementResult,
        completionResult: completionResult,
      );
    } on Object {
      return _rejected(
        coreState: coreState,
        handState: handState,
        cursor: cursor,
        reasonCode: 'ERR_HOLDEM_CORE_PROJECTION_REJECTED',
        warnings: warnings,
        actionResult: actionResult,
        showdownResult: showdownResult,
        settlementResult: settlementResult,
        completionResult: completionResult,
      );
    }

    return HoldemCoreProjectionResult(
      isApplied: true,
      coreState: projected,
      handState: nextHandState,
      cursor: nextCursor,
      events: List<EventEnvelope>.unmodifiable(events),
      warnings: List<String>.unmodifiable(warnings),
      actionResult: actionResult,
      showdownResult: showdownResult,
      settlementResult: settlementResult,
      completionResult: completionResult,
    );
  }

  HoldemCoreProjectionResult _rejected({
    required TableState coreState,
    required HoldemHandState handState,
    required HoldemEventCursor cursor,
    required String reasonCode,
    List<String> warnings = const <String>[],
    HoldemActionStreetResult? actionResult,
    HoldemShowdownRevealResult? showdownResult,
    HoldemSettlementProjectionGateResult? settlementResult,
    HoldemHandCompletionGateResult? completionResult,
  }) {
    return HoldemCoreProjectionResult(
      isApplied: false,
      coreState: coreState,
      handState: handState,
      cursor: cursor,
      events: const <EventEnvelope>[],
      warnings: List<String>.unmodifiable(warnings),
      reasonCode: reasonCode,
      actionResult: actionResult,
      showdownResult: showdownResult,
      settlementResult: settlementResult,
      completionResult: completionResult,
    );
  }

  String _eventTypeForAction(HoldemTableAction action) {
    return switch (action.type) {
      HoldemTableActionType.fold => 'PlayerFolded',
      HoldemTableActionType.check => 'PlayerChecked',
      HoldemTableActionType.call => 'PlayerCalled',
      HoldemTableActionType.bet => 'PlayerBet',
      HoldemTableActionType.raise => 'PlayerRaised',
      HoldemTableActionType.allIn => 'PlayerAllIn',
    };
  }
}

String _cursorRequiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Holdem cursor $key must be a string.');
  }
  return value;
}

String? _cursorNullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value != null && value is! String) {
    throw FormatException('Holdem cursor $key must be a string or null.');
  }
  return value as String?;
}

int _cursorRequiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Holdem cursor $key must be an integer.');
  }
  return value;
}

String _defaultEventHash(Map<String, Object?> canonicalEvent) {
  return computeCanonicalHash(canonicalEvent);
}

void _requireIdentity(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(
      value,
      field,
      'Identity must be non-empty and unpadded.',
    );
  }
  for (final codeUnit in value.codeUnits) {
    if (codeUnit < 0x20 || codeUnit == 0x7f) {
      throw ArgumentError.value(
        value,
        field,
        'Identity contains a control character.',
      );
    }
  }
}

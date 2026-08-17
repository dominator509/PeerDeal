import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/invariant_guard.dart';
import '../invariants/baseline_invariant_guards.dart';
import '../models/core_invariant_codes.dart';
import '../models/invariant_violation.dart';
import '../models/table_phase.dart';
import '../models/table_state.dart';

class CoreReducer {
  const CoreReducer({this.protocolCatalog = const ProtocolCatalog()})
    : invariantGuards = baselineInvariantGuards;

  /// Creates a reducer with caller-supplied guards owned by the reducer.
  CoreReducer.withInvariantGuards({
    this.protocolCatalog = const ProtocolCatalog(),
    List<InvariantGuard> invariantGuards = baselineInvariantGuards,
  }) : invariantGuards = List<InvariantGuard>.unmodifiable(invariantGuards);

  final ProtocolCatalog protocolCatalog;
  final List<InvariantGuard> invariantGuards;

  /// Returns every configured invariant violation for [state].
  ///
  /// Callers at an app or persistence boundary can preflight typed state
  /// without duplicating core truth or applying a synthetic event.
  List<InvariantViolation> validateState(TableState state) {
    final violations = <InvariantViolation>[];
    for (final guard in invariantGuards) {
      violations.addAll(guard.evaluate(state));
    }
    return List<InvariantViolation>.unmodifiable(violations);
  }

  TableState apply(TableState current, EventEnvelope event) {
    _ensureStateIsPossible(current);
    _ensureEventEnvelopeIdentity(event);

    final compatibility = protocolCatalog.checkEventEnvelope(event);
    if (!compatibility.isSupported) {
      throw InvariantViolation(
        code: compatibility.resultCode == ResultCode.errProtocolIncompatible
            ? ProtocolResultCodes.errEventProtocolIncompatible
            : ProtocolResultCodes.errEventSchemaUnsupported,
        message: 'Event is not supported by the protocol catalog.',
      );
    }

    if (event.eventSeq <= current.eventSequence) {
      throw InvariantViolation(
        code: 'ERR_EVENT_SEQUENCE_NOT_MONOTONIC',
        message:
            'event_seq must be strictly monotonic: '
            'current=${current.eventSequence}, incoming=${event.eventSeq}',
      );
    }
    if (event.eventSeq != current.eventSequence + 1) {
      throw InvariantViolation(
        code: 'ERR_EVENT_SEQUENCE_GAP',
        message:
            'event_seq must be contiguous: '
            'current=${current.eventSequence}, incoming=${event.eventSeq}',
      );
    }
    if (current.eventSequence > 0 &&
        (event.tableId != current.tableId ||
            event.sessionId != current.sessionId)) {
      throw InvariantViolation(
        code: 'ERR_EVENT_STREAM_IDENTITY_MISMATCH',
        message:
            'event stream table_id and session_id must remain stable: '
            'current=${current.tableId}/${current.sessionId}, '
            'incoming=${event.tableId}/${event.sessionId}',
      );
    }
    if (current.eventSequence > 0 &&
        event.protocolVersion != current.protocolVersion) {
      throw InvariantViolation(
        code: 'ERR_EVENT_STREAM_PROTOCOL_MISMATCH',
        message:
            'event stream protocol_version must remain stable: '
            'current=${current.protocolVersion}, '
            'incoming=${event.protocolVersion}',
      );
    }
    if (current.eventSequence > 0 &&
        event.prevEventHash != current.metadata['last_event_hash']) {
      throw InvariantViolation(
        code: 'ERR_EVENT_HASH_CHAIN_BREAK',
        message:
            'event prev_event_hash must match the last projected event_hash: '
            'expected=${current.metadata['last_event_hash']}, '
            'actual=${event.prevEventHash}',
      );
    }

    _ensureEventCanAdvanceState(current, event);

    final TableState nextState;
    switch (event.eventType) {
      case 'OpenTableSessionOpened':
        nextState = current.copyWith(
          tableId: event.tableId,
          sessionId: event.sessionId,
          protocolVersion: event.protocolVersion,
          phase: TablePhase.openReady,
          eventSequence: event.eventSeq,
          metadata: <String, Object?>{
            ...current.metadata,
            if (event.payload['mode_type'] != null)
              'mode_type': event.payload['mode_type'],
            'last_event_hash': event.eventHash,
          },
        );
        break;

      case 'ParticipantAdmitted':
      case 'ParticipantConnected':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          playersConnected: current.playersConnected + 1,
          metadata: _metadataAfter(current, event),
        );
        break;

      case 'ParticipantSeated':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          playersSeated: current.playersSeated + 1,
          metadata: _metadataAfter(current, event),
        );
        break;

      case 'HandStarted':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          activeHandId: event.handId ?? event.payload['hand_id'] as String?,
          phase: TablePhase.liveActive,
          metadata: _metadataAfter(current, event),
        );
        break;

      case 'HandSettled':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          activeHandId: null,
          phase: current.closeRequested
              ? TablePhase.closing
              : TablePhase.liveActive,
          metadata: _settlementMetadataAfter(
            current,
            event,
            settlementStatus: 'settled',
          ),
        );
        break;

      case 'SettlementProjected':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          metadata: _settlementMetadataAfter(
            current,
            event,
            settlementStatus: 'projected',
          ),
        );
        break;

      case 'SettlementBlocked':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          metadata: _settlementMetadataAfter(
            current,
            event,
            settlementStatus: 'blocked',
          ),
        );
        break;

      case 'SessionCloseRequested':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          closeRequested: true,
          phase: current.hasActiveHand
              ? TablePhase.liveActive
              : TablePhase.closing,
          metadata: _metadataAfter(current, event),
        );
        break;

      case 'SessionClosed':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          activeHandId: null,
          closeRequested: true,
          phase: TablePhase.closed,
          playersConnected: 0,
          playersSeated: 0,
          metadata: _metadataAfter(current, event),
        );
        break;

      case 'SessionWiped':
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          activeHandId: null,
          closeRequested: true,
          phase: TablePhase.wiped,
          playersConnected: 0,
          playersSeated: 0,
          metadata: _metadataAfter(current, event),
        );
        break;

      default:
        nextState = current.copyWith(
          eventSequence: event.eventSeq,
          metadata: _metadataAfter(current, event),
        );
        break;
    }

    _ensureProjectedStateIsPossible(nextState);
    return nextState;
  }

  void _ensureEventEnvelopeIdentity(EventEnvelope event) {
    final emptyFields = <String>[
      if (event.eventId.trim().isEmpty) 'event_id',
      if (event.eventType.trim().isEmpty) 'event_type',
      if (event.eventVersion.trim().isEmpty) 'event_version',
      if (event.protocolVersion.trim().isEmpty) 'protocol_version',
      if (event.tableId.trim().isEmpty) 'table_id',
      if (event.sessionId.trim().isEmpty) 'session_id',
      if (event.emittedAt.trim().isEmpty) 'emitted_at',
      if (event.actorRef.trim().isEmpty) 'actor_ref',
      if (event.prevEventHash.trim().isEmpty) 'prev_event_hash',
      if (event.eventHash.trim().isEmpty) 'event_hash',
    ];

    if (emptyFields.isEmpty) {
      return;
    }

    throw InvariantViolation(
      code: CoreInvariantCodes.eventEnvelopeIdentityEmpty,
      message:
          'Event envelope identity fields must be non-empty: '
          '${emptyFields.join(', ')}.',
    );
  }

  void _ensureEventCanAdvanceState(TableState current, EventEnvelope event) {
    if (event.eventType == 'SessionWiped' &&
        current.phase != TablePhase.closed) {
      throw InvariantViolation(
        code: CoreInvariantCodes.sessionWipedBeforeClose,
        message: 'SessionWiped requires a prior SessionClosed event.',
      );
    }

    if (current.phase == TablePhase.wiped ||
        (current.phase == TablePhase.closed &&
            event.eventType != 'SessionWiped')) {
      throw InvariantViolation(
        code: CoreInvariantCodes.terminalStateCannotAdvance,
        message:
            'Terminal table states cannot accept additional events except '
            'a final wipe marker.',
      );
    }

    if (event.eventType == 'OpenTableSessionOpened' &&
        current.eventSequence > 0) {
      throw InvariantViolation(
        code: CoreInvariantCodes.openEventAfterStreamStarted,
        message: 'OpenTableSessionOpened must be the first event in a stream.',
      );
    }

    if (event.eventType == 'ParticipantSeated' &&
        current.playersSeated >= current.playersConnected) {
      throw InvariantViolation(
        code: CoreInvariantCodes.participantSeatedWithoutConnected,
        message: 'ParticipantSeated requires an available connected player.',
      );
    }

    if (event.eventType == 'HandStarted') {
      final handId = _eventHandId(event);
      if (handId == null || handId.trim().isEmpty) {
        throw InvariantViolation(
          code: CoreInvariantCodes.handStartedWithoutHandId,
          message: 'HandStarted requires a non-empty hand_id.',
        );
      }
      if (current.hasActiveHand) {
        throw InvariantViolation(
          code: CoreInvariantCodes.handStartedWhileActive,
          message: 'HandStarted cannot occur while another hand is active.',
        );
      }
      return;
    }

    if (_handScopedEventTypes.contains(event.eventType)) {
      final handId = _eventHandId(event);
      if (handId == null || handId.trim().isEmpty) {
        throw InvariantViolation(
          code: CoreInvariantCodes.handEventWithoutHandId,
          message: '${event.eventType} requires a non-empty hand_id.',
        );
      }
      if (!current.hasActiveHand) {
        throw InvariantViolation(
          code: CoreInvariantCodes.handEventWithoutActiveHand,
          message: '${event.eventType} requires an active hand.',
        );
      }
      if (handId != current.activeHandId) {
        throw InvariantViolation(
          code: CoreInvariantCodes.handEventIdMismatch,
          message:
              '${event.eventType} hand_id must match the active hand: '
              'current=${current.activeHandId}, incoming=$handId',
        );
      }
    }

    if (event.eventType == 'SessionClosed') {
      if (!current.closeRequested) {
        throw InvariantViolation(
          code: CoreInvariantCodes.sessionClosedWithoutCloseRequest,
          message: 'SessionClosed requires a prior SessionCloseRequested.',
        );
      }
      if (current.hasActiveHand) {
        throw InvariantViolation(
          code: CoreInvariantCodes.sessionClosedWithActiveHand,
          message: 'SessionClosed cannot close over an active hand.',
        );
      }
    }
  }

  Map<String, Object?> _metadataAfter(TableState current, EventEnvelope event) {
    return <String, Object?>{
      ...current.metadata,
      'last_event_hash': event.eventHash,
    };
  }

  Map<String, Object?> _settlementMetadataAfter(
    TableState current,
    EventEnvelope event, {
    required String settlementStatus,
  }) {
    return <String, Object?>{
      ..._metadataAfter(current, event),
      'last_settlement_status': settlementStatus,
      'last_settlement_event_type': event.eventType,
      if (event.handId != null) 'last_settlement_hand_id': event.handId,
      if (event.payload['variant_id'] != null)
        'last_settlement_variant_id': event.payload['variant_id'],
      if (event.payload['projection_id'] != null)
        'last_settlement_projection_id': event.payload['projection_id'],
      if (event.payload['settlement_id'] != null)
        'last_settlement_id': event.payload['settlement_id'],
      if (event.payload['reason_codes'] is List<Object?>)
        'last_settlement_reason_codes': List<Object?>.unmodifiable(
          event.payload['reason_codes']! as List<Object?>,
        ),
      if (event.payload['warnings'] is List<Object?>)
        'last_settlement_warnings': List<Object?>.unmodifiable(
          event.payload['warnings']! as List<Object?>,
        ),
    };
  }

  void _ensureProjectedStateIsPossible(TableState state) {
    _ensureStateIsPossible(state);
  }

  void _ensureStateIsPossible(TableState state) {
    for (final violation in validateState(state)) {
      throw violation;
    }
  }

  String? _eventHandId(EventEnvelope event) {
    final payloadHandId = event.payload['hand_id'];
    return event.handId ?? (payloadHandId is String ? payloadHandId : null);
  }

  static const _handScopedEventTypes = <String>{
    'PlayerFolded',
    'PlayerChecked',
    'PlayerCalled',
    'PlayerBet',
    'PlayerRaised',
    'PlayerAllIn',
    'ShowdownStarted',
    'ShowdownRevealed',
    'SettlementProjected',
    'SettlementBlocked',
    'HandSettled',
  };
}

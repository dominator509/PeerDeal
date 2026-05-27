import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/invariant_violation.dart';
import '../models/table_phase.dart';
import '../models/table_state.dart';

class CoreReducer {
  const CoreReducer({this.protocolCatalog = const ProtocolCatalog()});

  final ProtocolCatalog protocolCatalog;

  TableState apply(TableState current, EventEnvelope event) {
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
    if (state.hasActiveHand && state.phase != TablePhase.liveActive) {
      throw const InvariantViolation(
        code: 'ERR_ACTIVE_HAND_OUTSIDE_LIVE_PHASE',
        message: 'A hand cannot remain active outside liveActive phase.',
      );
    }

    if (state.playersSeated > state.playersConnected) {
      throw const InvariantViolation(
        code: 'ERR_SEATED_EXCEEDS_CONNECTED',
        message: 'Seated players cannot exceed connected players.',
      );
    }

    if (state.phase == TablePhase.wiped &&
        (state.hasActiveHand ||
            state.playersConnected > 0 ||
            state.playersSeated > 0)) {
      throw const InvariantViolation(
        code: 'ERR_WIPED_STATE_NOT_TERMINAL',
        message: 'Wiped phase must not retain active hand or participants.',
      );
    }
  }
}

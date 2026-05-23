import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/invariant_violation.dart';
import '../models/table_state.dart';

class CoreReducer {
  const CoreReducer();

  TableState apply(TableState current, EventEnvelope event) {
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

    switch (event.eventType) {
      case 'OpenTableSessionOpened':
      case 'TournamentSessionOpened':
        return current.copyWith(
          tableId: event.tableId,
          sessionId: event.sessionId,
          protocolVersion: event.protocolVersion,
          phase: current.phase,
          eventSequence: event.eventSeq,
          metadata: <String, Object?>{
            ...current.metadata,
            if (event.payload['mode_type'] != null)
              'mode_type': event.payload['mode_type'],
          },
        );

      case 'ParticipantAdmitted':
        return current.copyWith(
          eventSequence: event.eventSeq,
          playersConnected: current.playersConnected + 1,
        );

      default:
        return current.copyWith(eventSequence: event.eventSeq);
    }
  }
}

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/invariant_violation.dart';
import '../models/table_state.dart';

class CoreReducer {
  const CoreReducer();

  TableState apply(TableState current, EventEnvelope event) {
    if (event.eventSeq <= current.eventSeq) {
      throw InvariantViolation(
        'event_seq must be strictly monotonic: current=${current.eventSeq}, incoming=${event.eventSeq}',
      );
    }

    switch (event.eventType) {
      case 'OpenTableSessionOpened':
      case 'TournamentSessionOpened':
        return current.copyWith(
          tableId: event.tableId,
          sessionId: event.sessionId,
          modeType: event.payload['mode_type'] as String?,
          protocolVersion: event.protocolVersion,
          eventSeq: event.eventSeq,
          isOpen: true,
        );

      case 'ParticipantAdmitted':
        return current.copyWith(
          eventSeq: event.eventSeq,
          participantCount: current.participantCount + 1,
        );

      default:
        return current.copyWith(eventSeq: event.eventSeq);
    }
  }
}

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/replay_mismatch.dart';

class EventWindowValidator {
  const EventWindowValidator();

  List<ReplayMismatch> validate(List<EventEnvelope> events) {
    final mismatches = <ReplayMismatch>[];

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      if (i > 0) {
        final previous = events[i - 1];
        if (event.eventSeq != previous.eventSeq + 1) {
          mismatches.add(
            ReplayMismatch(
              code: 'ERR_REPLAY_EVENT_GAP',
              message: 'Event sequence gap detected.',
              expected: previous.eventSeq + 1,
              actual: event.eventSeq,
            ),
          );
        }
        if (event.prevEventHash != previous.eventHash) {
          mismatches.add(
            ReplayMismatch(
              code: 'ERR_REPLAY_HASH_CHAIN_BREAK',
              message: 'Event hash chain continuity failed.',
              expected: previous.eventHash,
              actual: event.prevEventHash,
            ),
          );
        }
      }
    }

    return mismatches;
  }
}

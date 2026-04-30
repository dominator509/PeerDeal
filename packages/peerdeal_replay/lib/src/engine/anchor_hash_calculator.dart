import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/anchor_hash.dart';
import '../models/replay_scope.dart';

class AnchorHashCalculator {
  const AnchorHashCalculator();

  AnchorHash calculate({
    required ReplayScope scope,
    required Iterable<EventEnvelope> events,
  }) {
    final payload = [
      for (final event in events)
        {
          'event_seq': event.eventSeq,
          'event_hash': event.eventHash,
          'prev_event_hash': event.prevEventHash,
        },
    ];

    return AnchorHash(
      scope: scope.name,
      value: computeCanonicalHash(payload),
    );
  }
}

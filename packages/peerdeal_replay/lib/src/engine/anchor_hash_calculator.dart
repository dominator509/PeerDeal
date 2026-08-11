import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/anchor_hash.dart';
import '../models/replay_scope.dart';
import 'event_window_validator.dart';

class AnchorHashCalculator {
  AnchorHashCalculator({int maxEvents = defaultMaxEvents})
    : _maxEvents = maxEvents {
    if (maxEvents <= 0) {
      throw ArgumentError.value(
        maxEvents,
        'maxEvents',
        'Anchor event limit must be positive.',
      );
    }
  }

  static const defaultMaxEvents = EventWindowValidator.defaultMaxEvents;

  final int _maxEvents;

  AnchorHash calculate({
    required ReplayScope scope,
    required Iterable<EventEnvelope> events,
  }) {
    final payload = <Map<String, Object?>>[];
    for (final event in events) {
      if (payload.length >= _maxEvents) {
        throw ArgumentError.value(
          payload.length + 1,
          'events',
          'Anchor event window exceeds the configured limit.',
        );
      }
      payload.add(<String, Object?>{
        'event_seq': event.eventSeq,
        'event_hash': event.eventHash,
        'prev_event_hash': event.prevEventHash,
      });
    }

    return AnchorHash(
      scope: scope.name,
      value: computeCanonicalHash(
        payload,
        limits: CanonicalJsonLimits(
          maxListItems: _maxEvents,
          maxNodes: (_maxEvents * 8) + 1,
        ),
      ),
    );
  }
}

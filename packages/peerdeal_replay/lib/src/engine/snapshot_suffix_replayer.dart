import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/snapshot_suffix_result.dart';
import 'event_window_validator.dart';

class SnapshotSuffixReplayer {
  SnapshotSuffixReplayer({int maxEvents = defaultMaxEvents})
    : _maxEvents = maxEvents {
    if (maxEvents <= 0) {
      throw ArgumentError.value(
        maxEvents,
        'maxEvents',
        'Snapshot suffix event limit must be positive.',
      );
    }
  }

  static const defaultMaxEvents = EventWindowValidator.defaultMaxEvents;

  final int _maxEvents;

  SnapshotSuffixResult plan({
    required SnapshotEnvelope snapshot,
    required List<EventEnvelope> events,
  }) {
    if (events.length > _maxEvents) {
      throw ArgumentError.value(
        events.length,
        'events',
        'Snapshot suffix event window exceeds the configured limit.',
      );
    }
    if (!validateSnapshotEnvelopeIdentity(snapshot).isValid) {
      throw ArgumentError.value(
        snapshot,
        'snapshot',
        'Snapshot envelope identity is empty or unsafe.',
      );
    }
    if (snapshot.snapshotBaseEventSeq < 0) {
      throw ArgumentError.value(
        snapshot.snapshotBaseEventSeq,
        'snapshot.snapshotBaseEventSeq',
        'Snapshot base event sequence must be non-negative.',
      );
    }

    final suffix = events
        .where((event) => event.eventSeq > snapshot.snapshotBaseEventSeq)
        .toList(growable: false);

    return SnapshotSuffixResult(
      eventsToApply: suffix,
      snapshotBaseEventSeq: snapshot.snapshotBaseEventSeq,
    );
  }
}

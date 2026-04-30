import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/snapshot_suffix_result.dart';

class SnapshotSuffixReplayer {
  const SnapshotSuffixReplayer();

  SnapshotSuffixResult plan({
    required SnapshotEnvelope snapshot,
    required List<EventEnvelope> events,
  }) {
    final suffix = events
        .where((event) => event.eventSeq > snapshot.snapshotBaseEventSeq)
        .toList(growable: false);

    return SnapshotSuffixResult(
      eventsToApply: suffix,
      snapshotBaseEventSeq: snapshot.snapshotBaseEventSeq,
    );
  }
}

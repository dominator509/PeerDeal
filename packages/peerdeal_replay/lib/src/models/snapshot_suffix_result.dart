import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

@immutable
class SnapshotSuffixResult {
  SnapshotSuffixResult({
    required List<EventEnvelope> eventsToApply,
    required this.snapshotBaseEventSeq,
  }) : eventsToApply = List<EventEnvelope>.unmodifiable(eventsToApply);

  final List<EventEnvelope> eventsToApply;
  final int snapshotBaseEventSeq;
}

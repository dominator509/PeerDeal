import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

@immutable
class SnapshotSuffixResult {
  const SnapshotSuffixResult({
    required this.eventsToApply,
    required this.snapshotBaseEventSeq,
  });

  final List<EventEnvelope> eventsToApply;
  final int snapshotBaseEventSeq;
}

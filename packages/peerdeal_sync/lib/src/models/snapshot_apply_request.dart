import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

@immutable
class SnapshotApplyRequest {
  SnapshotApplyRequest({
    required this.tableId,
    required this.sessionId,
    required this.protocolVersion,
    required List<EventEnvelope> events,
    this.snapshot,
  }) : events = List<EventEnvelope>.unmodifiable(events);

  final String tableId;
  final String sessionId;
  final String protocolVersion;
  final List<EventEnvelope> events;
  final SnapshotEnvelope? snapshot;
}

import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

@immutable
class SnapshotApplyRequest {
  const SnapshotApplyRequest({
    required this.tableId,
    required this.sessionId,
    required this.protocolVersion,
    required this.events,
    this.snapshot,
  });

  final String tableId;
  final String sessionId;
  final String protocolVersion;
  final List<EventEnvelope> events;
  final SnapshotEnvelope? snapshot;
}

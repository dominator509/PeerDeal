import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'anchor_hash.dart';
import 'replay_scope.dart';

@immutable
class ReplayRequest {
  const ReplayRequest({
    required this.tableId,
    required this.sessionId,
    required this.protocolVersion,
    required this.scope,
    required this.events,
    this.snapshot,
    this.expectedAnchor,
    this.fromEventSeq,
    this.toEventSeq,
  });

  final String tableId;
  final String sessionId;
  final String protocolVersion;
  final ReplayScope scope;
  final List<EventEnvelope> events;
  final SnapshotEnvelope? snapshot;
  final AnchorHash? expectedAnchor;
  final int? fromEventSeq;
  final int? toEventSeq;
}

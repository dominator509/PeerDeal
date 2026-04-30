import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'recovery_mode.dart';

@immutable
class RecoveryRequest {
  const RecoveryRequest({
    required this.tableId,
    required this.sessionId,
    required this.protocolVersion,
    required this.mode,
    required this.events,
    this.snapshot,
    this.expectedFinalEventSeq,
    this.expectedFinalEventHash,
  });

  final String tableId;
  final String sessionId;
  final String protocolVersion;
  final RecoveryMode mode;
  final List<EventEnvelope> events;
  final SnapshotEnvelope? snapshot;
  final int? expectedFinalEventSeq;
  final String? expectedFinalEventHash;
}

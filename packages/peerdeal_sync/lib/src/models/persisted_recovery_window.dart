import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

@immutable
class PersistedRecoveryWindow {
  const PersistedRecoveryWindow({required this.events, this.snapshot});

  final SnapshotEnvelope? snapshot;
  final List<EventEnvelope> events;
}

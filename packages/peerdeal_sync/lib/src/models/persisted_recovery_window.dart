import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

@immutable
class PersistedRecoveryWindow {
  PersistedRecoveryWindow({required List<EventEnvelope> events, this.snapshot})
    : events = List<EventEnvelope>.unmodifiable(events);

  final SnapshotEnvelope? snapshot;
  final List<EventEnvelope> events;
}

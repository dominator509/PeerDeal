import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

class FakeSnapshotProjection {
  const FakeSnapshotProjection({
    required this.tableId,
    required this.sessionId,
    required this.protocolVersion,
    required this.appliedEventTypes,
    required this.snapshotApplied,
  });

  final String tableId;
  final String sessionId;
  final String protocolVersion;
  final List<String> appliedEventTypes;
  final bool snapshotApplied;
}

class FakeSnapshotProjector implements SnapshotStateProjector<FakeSnapshotProjection> {
  @override
  FakeSnapshotProjection createBaseState({
    required String tableId,
    required String sessionId,
    required String protocolVersion,
  }) {
    return FakeSnapshotProjection(
      tableId: tableId,
      sessionId: sessionId,
      protocolVersion: protocolVersion,
      appliedEventTypes: const <String>[],
      snapshotApplied: false,
    );
  }

  @override
  FakeSnapshotProjection applySnapshot({
    required FakeSnapshotProjection state,
    required SnapshotEnvelope snapshot,
  }) {
    return FakeSnapshotProjection(
      tableId: state.tableId,
      sessionId: state.sessionId,
      protocolVersion: state.protocolVersion,
      appliedEventTypes: <String>[...state.appliedEventTypes, 'SnapshotApplied'],
      snapshotApplied: true,
    );
  }

  @override
  FakeSnapshotProjection applyEvent({
    required FakeSnapshotProjection state,
    required EventEnvelope event,
  }) {
    return FakeSnapshotProjection(
      tableId: state.tableId,
      sessionId: state.sessionId,
      protocolVersion: state.protocolVersion,
      appliedEventTypes: <String>[...state.appliedEventTypes, event.eventType],
      snapshotApplied: state.snapshotApplied,
    );
  }
}

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';

class FakeTableProjection {
  const FakeTableProjection({
    required this.tableId,
    required this.sessionId,
    required this.protocolVersion,
    required this.appliedEventTypes,
  });

  final String tableId;
  final String sessionId;
  final String protocolVersion;
  final List<String> appliedEventTypes;

  FakeTableProjection copyWithEvent(String eventType) => FakeTableProjection(
    tableId: tableId,
    sessionId: sessionId,
    protocolVersion: protocolVersion,
    appliedEventTypes: [...appliedEventTypes, eventType],
  );
}

class FakeTableProjector
    implements
        ReplayStateProjector<FakeTableProjection>,
        ReplaySnapshotStateProjector<FakeTableProjection> {
  @override
  FakeTableProjection createBaseState({
    required String tableId,
    required String sessionId,
    required String protocolVersion,
  }) {
    return FakeTableProjection(
      tableId: tableId,
      sessionId: sessionId,
      protocolVersion: protocolVersion,
      appliedEventTypes: const <String>[],
    );
  }

  @override
  FakeTableProjection createStateFromSnapshot({
    required SnapshotEnvelope snapshot,
  }) {
    return FakeTableProjection(
      tableId: snapshot.tableId,
      sessionId: snapshot.sessionId,
      protocolVersion: snapshot.protocolVersion,
      appliedEventTypes: <String>['Snapshot:${snapshot.snapshotId}'],
    );
  }

  @override
  FakeTableProjection applyEvent({
    required FakeTableProjection state,
    required EventEnvelope event,
  }) {
    return state.copyWithEvent(event.eventType);
  }
}

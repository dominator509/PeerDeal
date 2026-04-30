import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

import 'fakes/fake_snapshot_projector.dart';

void main() {
  test('returns safe-close recommendation on fatal conflict', () {
    final coordinator = BasicSyncCoordinator<FakeSnapshotProjection>(
      conflictDetector: const BasicConflictDetector(),
      snapshotApplier: BasicSnapshotApplier<FakeSnapshotProjection>(
        projector: FakeSnapshotProjector(),
      ),
    );

    final result = coordinator.recover(
      const RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_1',
          protocolVersion: '2.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 5,
          snapshotHash: 'hash_snap',
          payload: <String, Object?>{},
        ),
        events: <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.safeCloseRecommended, isTrue);
    expect(result.reconciliation.recommendedAction, 'safe_close');
  });

  test('recovers by applying snapshot and suffix window when no fatal conflict exists', () {
    final coordinator = BasicSyncCoordinator<FakeSnapshotProjection>(
      conflictDetector: const BasicConflictDetector(),
      snapshotApplier: BasicSnapshotApplier<FakeSnapshotProjection>(
        projector: FakeSnapshotProjector(),
      ),
    );

    final result = coordinator.recover(
      const RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_1',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 2,
          snapshotHash: 'snap_hash',
          payload: <String, Object?>{},
        ),
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_3',
            eventType: 'RecoveryPauseEnded',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 3,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:05Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: 'hash_2',
            eventHash: 'hash_3',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.state, isNotNull);
    expect(result.finalAppliedEventSeq, 3);
    expect(result.reconciliation.canResume, isTrue);
    expect(result.state!.appliedEventTypes, ['SnapshotApplied', 'RecoveryPauseEnded']);
  });
}

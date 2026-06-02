import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

import 'fakes/fake_snapshot_projector.dart';

void main() {
  test('applies snapshot first and only replays suffix events', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: FakeSnapshotProjector(),
    );

    final result = applier.apply(
      SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        snapshot: const SnapshotEnvelope(
          snapshotId: 'snap_1',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 10,
          snapshotHash: 'snap_hash',
          payload: <String, Object?>{'phase': 'LIVE_ACTIVE'},
        ),
        events: const <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_10',
            eventType: 'IgnoredBecauseCoveredBySnapshot',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 10,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: 'prev',
            eventHash: 'hash_10',
          ),
          EventEnvelope(
            eventId: 'evt_11',
            eventType: 'RecoveryPauseEnded',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 11,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:05Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: 'hash_10',
            eventHash: 'hash_11',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.appliedEventCount, 1);
    expect(result.finalAppliedEventSeq, 11);
    expect(result.state.snapshotApplied, isTrue);
    expect(result.state.appliedEventTypes, [
      'SnapshotApplied',
      'RecoveryPauseEnded',
    ]);
  });

  test('fails safely when snapshot suffix has a sequence gap', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: FakeSnapshotProjector(),
    );

    final result = applier.apply(
      SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        snapshot: const SnapshotEnvelope(
          snapshotId: 'snap_1',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 10,
          snapshotHash: 'snap_hash',
          payload: <String, Object?>{'phase': 'LIVE_ACTIVE'},
        ),
        events: const <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_12',
            eventType: 'RecoveryPauseEnded',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 12,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:05Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: 'hash_11',
            eventHash: 'hash_12',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.appliedEventCount, 0);
    expect(result.finalAppliedEventSeq, isNull);
    expect(result.state.snapshotApplied, isFalse);
    expect(result.state.appliedEventTypes, isEmpty);
    expect(result.conflicts.single.code, 'ERR_SNAPSHOT_APPLY_SUFFIX_GAP');
  });

  test('fails safely when apply request has no snapshot and no events', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: FakeSnapshotProjector(),
    );

    final result = applier.apply(
      const SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        events: <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.appliedEventCount, 0);
    expect(result.finalAppliedEventSeq, isNull);
    expect(result.conflicts.single.code, 'ERR_SNAPSHOT_APPLY_EMPTY_WINDOW');
  });

  test('fails safely when no-snapshot event window misses the prefix', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: FakeSnapshotProjector(),
    );

    final result = applier.apply(
      const SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
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

    expect(result.isSuccess, isFalse);
    expect(result.appliedEventCount, 0);
    expect(
      result.conflicts.single.code,
      'ERR_SNAPSHOT_APPLY_EVENT_WINDOW_MISSING_PREFIX',
    );
  });
}

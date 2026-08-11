import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

import 'fakes/fake_snapshot_projector.dart';

void main() {
  test('rejects an invalid direct apply scope before projector access', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: FakeSnapshotProjector(),
    );
    final result = applier.apply(
      SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'x' * RecoveryPersistenceLimits.defaultMaxStorageKeyBytes,
        protocolVersion: '1.0.0',
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.appliedEventCount, 0);
    expect(result.conflicts.single.code, 'ERR_SNAPSHOT_APPLY_SCOPE_INVALID');
  });

  test('rejects an oversized event window before applying events', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: _ThrowingEventProjector(),
      maxEvents: 1,
    );

    final result = applier.apply(
      SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        events: <EventEnvelope>[
          _event(1, prevEventHash: genesisEventHash, eventHash: 'hash_1'),
          _event(2, prevEventHash: 'hash_1', eventHash: 'hash_2'),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.appliedEventCount, 0);
    expect(result.state.appliedEventTypes, isEmpty);
    expect(result.conflicts.single.code, 'ERR_RECOVERY_EVENT_COUNT_TOO_LARGE');
    expect(result.conflicts.single.expected, '1');
    expect(result.conflicts.single.actual, '2');
  });

  test('rejects an unencodable direct event before projector access', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: _ThrowingEventProjector(),
    );

    final result = applier.apply(
      SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        events: <EventEnvelope>[
          _event(
            1,
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
            payload: <String, Object?>{'unsupported': Object()},
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.appliedEventCount, 0);
    expect(result.state.appliedEventTypes, isEmpty);
    expect(result.conflicts.single.code, 'ERR_RECOVERY_EVENT_INVALID');
  });

  test('rejects an unencodable direct snapshot before snapshot projection', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: FakeSnapshotProjector(),
    );

    final result = applier.apply(
      SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_1',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 1,
          snapshotHash: 'snap_hash',
          payload: <String, Object?>{'unsupported': Object()},
        ),
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.appliedEventCount, 0);
    expect(result.state.snapshotApplied, isFalse);
    expect(result.conflicts.single.code, 'ERR_RECOVERY_SNAPSHOT_INVALID');
  });

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
      result.conflicts.map((conflict) => conflict.code),
      contains('ERR_SNAPSHOT_APPLY_EVENT_WINDOW_MISSING_PREFIX'),
    );
  });

  test('fails safely when projector throws while applying an event', () {
    final applier = BasicSnapshotApplier<FakeSnapshotProjection>(
      projector: _ThrowingEventProjector(),
    );

    final result = applier.apply(
      const SnapshotApplyRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'RecoveryPauseEnded',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 1,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:05Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.appliedEventCount, 0);
    expect(result.finalAppliedEventSeq, isNull);
    expect(result.state.appliedEventTypes, isEmpty);
    expect(
      result.conflicts.single.code,
      'ERR_SNAPSHOT_APPLY_PROJECTOR_FAILURE',
    );
    expect(result.conflicts.single.actual, 'StateError');
  });

  test(
    'fails safely when no-snapshot event window has non-genesis first hash',
    () {
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
              eventId: 'evt_1',
              eventType: 'OpenTableSessionOpened',
              eventVersion: '1.0',
              protocolVersion: '1.0.0',
              eventSeq: 1,
              tableId: 'table_1',
              sessionId: 'session_1',
              handId: null,
              emittedAt: '2026-04-25T00:00:00Z',
              actorRef: 'host_1',
              payload: <String, Object?>{},
              prevEventHash: 'root',
              eventHash: 'hash_1',
            ),
          ],
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.appliedEventCount, 0);
      expect(
        result.conflicts.single.code,
        'ERR_SNAPSHOT_APPLY_EVENT_WINDOW_GENESIS_HASH_MISMATCH',
      );
      expect(result.conflicts.single.expected, genesisEventHash);
      expect(result.conflicts.single.actual, 'root');
    },
  );
}

class _ThrowingEventProjector extends FakeSnapshotProjector {
  @override
  FakeSnapshotProjection applyEvent({
    required FakeSnapshotProjection state,
    required EventEnvelope event,
  }) {
    throw StateError('projector failed');
  }
}

EventEnvelope _event(
  int eventSeq, {
  required String prevEventHash,
  required String eventHash,
  Map<String, Object?> payload = const <String, Object?>{},
}) {
  return EventEnvelope(
    eventId: 'evt_$eventSeq',
    eventType: eventSeq == 1 ? 'OpenTableSessionOpened' : 'RecoveryPauseEnded',
    eventVersion: '1.0',
    protocolVersion: '1.0.0',
    eventSeq: eventSeq,
    tableId: 'table_1',
    sessionId: 'session_1',
    handId: null,
    emittedAt: '2026-04-25T00:00:00Z',
    actorRef: 'system',
    payload: payload,
    prevEventHash: prevEventHash,
    eventHash: eventHash,
  );
}

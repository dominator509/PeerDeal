import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

import 'fakes/fake_snapshot_projector.dart';
import 'fixture_loader.dart';

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
    expect(result.diagnostics.single.toJson(), {
      'code': 'ERR_SNAPSHOT_PROTOCOL_INCOMPATIBLE',
      'message': 'Recovery snapshot protocol version is not supported.',
      'expected': '1.0.0',
      'actual': '2.0.0',
    });
  });

  test(
    'recovers by applying snapshot and suffix window when no fatal conflict exists',
    () {
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
      expect(result.state!.appliedEventTypes, [
        'SnapshotApplied',
        'RecoveryPauseEnded',
      ]);
    },
  );

  test('recovers Holdem settlement suffix from protocol fixture stream', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final first = events.first;
    final coordinator = BasicSyncCoordinator<FakeSnapshotProjection>(
      conflictDetector: const BasicConflictDetector(),
      snapshotApplier: BasicSnapshotApplier<FakeSnapshotProjection>(
        projector: FakeSnapshotProjector(),
      ),
    );

    final result = coordinator.recover(
      RecoveryRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        mode: RecoveryMode.reconnect,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_holdem_showdown_revealed',
          protocolVersion: first.protocolVersion,
          tableId: first.tableId,
          sessionId: first.sessionId,
          snapshotBaseEventSeq: 3,
          snapshotHash: 'snap_hash_holdem_showdown_revealed',
          payload: const <String, Object?>{
            'hand_id': 'hand_holdem_001',
            'variant_id': 'holdem_nlhe',
          },
        ),
        events: events,
        expectedFinalEventSeq: 5,
        expectedFinalEventHash: 'hash_holdem_005',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.safeCloseRecommended, isFalse);
    expect(result.finalAppliedEventSeq, 5);
    expect(result.reconciliation.canResume, isTrue);
    expect(result.reconciliation.recommendedAction, 'resume_with_warning');
    expect(result.conflicts.single.code, 'WARN_EVENT_WINDOW_OVERLAPS_SNAPSHOT');
    expect(
      result.warnings,
      contains(
        'Recovery used snapshot checkpoint as a reconstruction accelerator.',
      ),
    );
    expect(result.state!.appliedEventTypes, <String>[
      'SnapshotApplied',
      'SettlementProjected',
      'HandSettled',
    ]);
  });

  test('recovers Holdem blocked settlement suffix from protocol fixtures', () {
    final events = _loadHoldemBlockedSettlementEvents();
    final first = events.first;
    final coordinator = BasicSyncCoordinator<FakeSnapshotProjection>(
      conflictDetector: const BasicConflictDetector(),
      snapshotApplier: BasicSnapshotApplier<FakeSnapshotProjection>(
        projector: FakeSnapshotProjector(),
      ),
    );

    final result = coordinator.recover(
      RecoveryRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        mode: RecoveryMode.reconnect,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_holdem_showdown_revealed',
          protocolVersion: first.protocolVersion,
          tableId: first.tableId,
          sessionId: first.sessionId,
          snapshotBaseEventSeq: 3,
          snapshotHash: 'snap_hash_holdem_showdown_revealed',
          payload: const <String, Object?>{
            'hand_id': 'hand_holdem_001',
            'variant_id': 'holdem_nlhe',
          },
        ),
        events: events,
        expectedFinalEventSeq: 4,
        expectedFinalEventHash: 'hash_holdem_blocked_004',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.safeCloseRecommended, isFalse);
    expect(result.finalAppliedEventSeq, 4);
    expect(result.reconciliation.canResume, isTrue);
    expect(result.conflicts.single.code, 'WARN_EVENT_WINDOW_OVERLAPS_SNAPSHOT');
    expect(result.state!.appliedEventTypes, <String>[
      'SnapshotApplied',
      'SettlementBlocked',
    ]);
  });

  test('safe-closes when snapshot applier rejects the recovery window', () {
    final coordinator = BasicSyncCoordinator<FakeSnapshotProjection>(
      conflictDetector: const _NoConflictDetector(),
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
            eventId: 'evt_4',
            eventType: 'RecoveryPauseEnded',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 4,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:05Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: 'hash_3',
            eventHash: 'hash_4',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.safeCloseRecommended, isTrue);
    expect(result.reconciliation.recommendedAction, 'safe_close');
    expect(result.conflicts.single.code, 'ERR_SNAPSHOT_APPLY_SUFFIX_GAP');
  });
}

List<EventEnvelope> _loadHoldemShowdownSettlementEvents() {
  return <EventEnvelope>[
    loadProtocolEventFixture('events/holdem_hand_started_event_v1.json'),
    loadProtocolEventFixture('events/holdem_showdown_started_event_v1.json'),
    loadProtocolEventFixture('events/holdem_showdown_revealed_event_v1.json'),
    loadProtocolEventFixture(
      'events/holdem_settlement_projected_event_v1.json',
    ),
    loadProtocolEventFixture('events/holdem_hand_settled_event_v1.json'),
  ];
}

List<EventEnvelope> _loadHoldemBlockedSettlementEvents() {
  return <EventEnvelope>[
    loadProtocolEventFixture('events/holdem_hand_started_event_v1.json'),
    loadProtocolEventFixture('events/holdem_showdown_started_event_v1.json'),
    loadProtocolEventFixture('events/holdem_showdown_revealed_event_v1.json'),
    loadProtocolEventFixture('events/holdem_settlement_blocked_event_v1.json'),
  ];
}

class _NoConflictDetector implements ConflictDetector {
  const _NoConflictDetector();

  @override
  ConflictDetectionResult detect(RecoveryRequest request) {
    return const ConflictDetectionResult(conflicts: <SyncConflict>[]);
  }
}

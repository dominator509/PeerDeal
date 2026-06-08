import 'package:peerdeal_core/peerdeal_core.dart';
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

  test('safe-closes empty recovery requests', () {
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
        events: <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.safeCloseRecommended, isTrue);
    expect(result.reconciliation.recommendedAction, 'safe_close');
    expect(result.conflicts.single.code, 'ERR_EMPTY_RECOVERY_WINDOW');
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

  test('recovers Holdem settlement metadata through core projector', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final first = events.first;
    final coordinator = BasicSyncCoordinator<TableState>(
      conflictDetector: const BasicConflictDetector(),
      snapshotApplier: BasicSnapshotApplier<TableState>(
        projector: const _CoreSnapshotProjector(),
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
            'last_event_hash': 'hash_holdem_003',
          },
        ),
        events: events,
        expectedFinalEventSeq: 5,
        expectedFinalEventHash: 'hash_holdem_005',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.state, isNotNull);
    expect(result.state!.activeHandId, isNull);
    expect(result.state!.metadata['last_settlement_status'], 'settled');
    expect(result.state!.metadata['last_settlement_event_type'], 'HandSettled');
    expect(
      result.state!.metadata['last_settlement_hand_id'],
      'hand_holdem_001',
    );
    expect(
      result.state!.metadata['last_settlement_projection_id'],
      'settlement_projection_holdem_001',
    );
    expect(
      result.state!.metadata['last_settlement_id'],
      'settlement_holdem_001',
    );
    expect(result.state!.metadata['last_settlement_variant_id'], 'holdem_nlhe');
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

  test(
    'recovers Holdem blocked settlement reason codes through core projector',
    () {
      const fixtureCases = <String, List<String>>{
        'events/holdem_settlement_blocked_event_v1.json': <String>[
          'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
        ],
        'events/holdem_settlement_blocked_empty_pot_event_v1.json': <String>[
          'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT',
        ],
        'events/holdem_settlement_blocked_invalid_showdown_event_v1.json':
            <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN'],
      };
      final coordinator = BasicSyncCoordinator<TableState>(
        conflictDetector: const BasicConflictDetector(),
        snapshotApplier: BasicSnapshotApplier<TableState>(
          projector: const _CoreSnapshotProjector(),
        ),
      );

      for (final entry in fixtureCases.entries) {
        final events = _loadHoldemBlockedSettlementEvents(
          blockedFixturePath: entry.key,
        );
        final first = events.first;
        final blocked = events.last;

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
                'last_event_hash': 'hash_holdem_003',
              },
            ),
            events: events,
            expectedFinalEventSeq: blocked.eventSeq,
            expectedFinalEventHash: blocked.eventHash,
          ),
        );

        expect(result.isSuccess, isTrue, reason: entry.key);
        expect(result.state, isNotNull, reason: entry.key);
        expect(
          result.state!.metadata['last_settlement_status'],
          'blocked',
          reason: entry.key,
        );
        expect(
          result.state!.metadata['last_settlement_event_type'],
          'SettlementBlocked',
          reason: entry.key,
        );
        expect(
          result.state!.metadata['last_settlement_reason_codes'],
          entry.value,
          reason: entry.key,
        );
        expect(
          result.state!.metadata['last_settlement_warnings'],
          containsAll(entry.value),
          reason: entry.key,
        );
      }
    },
  );

  test(
    'safe-closes Holdem recovery when lifecycle fixture stream has a gap',
    () {
      final events = _loadHoldemShowdownSettlementEvents();
      final gappedEvents = <EventEnvelope>[
        events[0],
        events[1],
        events[3],
        events[4],
      ];
      final first = gappedEvents.first;
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
          events: gappedEvents,
          expectedFinalEventSeq: 5,
          expectedFinalEventHash: 'hash_holdem_005',
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.safeCloseRecommended, isTrue);
      expect(result.reconciliation.recommendedAction, 'safe_close');
      expect(
        result.conflicts.map((conflict) => conflict.code),
        contains('ERR_EVENT_SEQUENCE_GAP'),
      );
    },
  );

  test('safe-closes Holdem recovery when lifecycle hash diverges', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final divergentEvents = <EventEnvelope>[
      ...events.take(3),
      _copyEvent(events[3], prevEventHash: 'hash_holdem_diverged'),
      events[4],
    ];
    final first = divergentEvents.first;
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
        events: divergentEvents,
        expectedFinalEventSeq: 5,
        expectedFinalEventHash: 'hash_holdem_005',
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.safeCloseRecommended, isTrue);
    expect(result.conflicts.single.code, 'ERR_EVENT_HASH_CHAIN_BREAK');
    expect(result.conflicts.single.expected, 'hash_holdem_003');
    expect(result.conflicts.single.actual, 'hash_holdem_diverged');
  });

  test('safe-closes Holdem recovery when expected final hash diverges', () {
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
        expectedFinalEventHash: 'hash_holdem_diverged_final',
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.safeCloseRecommended, isTrue);
    expect(
      result.conflicts.map((conflict) => conflict.code),
      contains('ERR_FINAL_EVENT_HASH_MISMATCH'),
    );
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

  test('safe-closes when conflict detector throws', () {
    final coordinator = BasicSyncCoordinator<FakeSnapshotProjection>(
      conflictDetector: const _ThrowingConflictDetector(),
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
    expect(result.state, isNull);
    expect(result.safeCloseRecommended, isTrue);
    expect(result.reconciliation.recommendedAction, 'safe_close');
    expect(result.conflicts.single.code, 'ERR_SYNC_CONFLICT_DETECTOR_FAILURE');
    expect(result.conflicts.single.actual, 'StateError');
  });

  test('safe-closes when snapshot applier throws', () {
    final coordinator = BasicSyncCoordinator<FakeSnapshotProjection>(
      conflictDetector: const _NoConflictDetector(),
      snapshotApplier: const _ThrowingSnapshotApplier(),
    );

    final result = coordinator.recover(
      const RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
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
    expect(result.state, isNull);
    expect(result.safeCloseRecommended, isTrue);
    expect(result.reconciliation.recommendedAction, 'safe_close');
    expect(result.conflicts.single.code, 'ERR_SYNC_SNAPSHOT_APPLIER_FAILURE');
    expect(result.conflicts.single.actual, 'StateError');
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

List<EventEnvelope> _loadHoldemBlockedSettlementEvents({
  String blockedFixturePath = 'events/holdem_settlement_blocked_event_v1.json',
}) {
  return <EventEnvelope>[
    loadProtocolEventFixture('events/holdem_hand_started_event_v1.json'),
    loadProtocolEventFixture('events/holdem_showdown_started_event_v1.json'),
    loadProtocolEventFixture('events/holdem_showdown_revealed_event_v1.json'),
    loadProtocolEventFixture(blockedFixturePath),
  ];
}

EventEnvelope _copyEvent(EventEnvelope event, {String? prevEventHash}) {
  return EventEnvelope(
    eventId: event.eventId,
    eventType: event.eventType,
    eventVersion: event.eventVersion,
    protocolVersion: event.protocolVersion,
    eventSeq: event.eventSeq,
    tableId: event.tableId,
    sessionId: event.sessionId,
    handId: event.handId,
    emittedAt: event.emittedAt,
    actorRef: event.actorRef,
    payload: event.payload,
    prevEventHash: prevEventHash ?? event.prevEventHash,
    eventHash: event.eventHash,
  );
}

class _NoConflictDetector implements ConflictDetector {
  const _NoConflictDetector();

  @override
  ConflictDetectionResult detect(RecoveryRequest request) {
    return const ConflictDetectionResult(conflicts: <SyncConflict>[]);
  }
}

class _ThrowingConflictDetector implements ConflictDetector {
  const _ThrowingConflictDetector();

  @override
  ConflictDetectionResult detect(RecoveryRequest request) {
    throw StateError('detector failed');
  }
}

class _ThrowingSnapshotApplier
    implements SnapshotApplier<FakeSnapshotProjection> {
  const _ThrowingSnapshotApplier();

  @override
  SnapshotApplyResult<FakeSnapshotProjection> apply(
    SnapshotApplyRequest request,
  ) {
    throw StateError('applier failed');
  }
}

class _CoreSnapshotProjector implements SnapshotStateProjector<TableState> {
  const _CoreSnapshotProjector();

  @override
  TableState createBaseState({
    required String tableId,
    required String sessionId,
    required String protocolVersion,
  }) {
    return TableState.initial(
      tableId: tableId,
      sessionId: sessionId,
      protocolVersion: protocolVersion,
    );
  }

  @override
  TableState applySnapshot({
    required TableState state,
    required SnapshotEnvelope snapshot,
  }) {
    return TableState(
      tableId: snapshot.tableId,
      sessionId: snapshot.sessionId,
      phase: TablePhase.liveActive,
      protocolVersion: snapshot.protocolVersion,
      eventSequence: snapshot.snapshotBaseEventSeq,
      closeRequested: false,
      playersConnected: 0,
      playersSeated: 0,
      activeHandId: snapshot.payload['hand_id'] as String?,
      metadata: <String, Object?>{
        'last_event_hash':
            snapshot.payload['last_event_hash'] ?? snapshot.snapshotHash,
        if (snapshot.payload['variant_id'] != null)
          'variant_id': snapshot.payload['variant_id'],
      },
    );
  }

  @override
  TableState applyEvent({
    required TableState state,
    required EventEnvelope event,
  }) {
    return const CoreReducer().apply(state, event);
  }
}

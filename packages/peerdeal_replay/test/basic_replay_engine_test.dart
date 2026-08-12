import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';
import 'fakes/fake_table_projector.dart';

void main() {
  final engine = BasicReplayEngine<FakeTableProjection>(
    projector: FakeTableProjector(),
  );

  test('replays ordered event window into projected state', () {
    final events = [
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
        payload: const {'phase': 'OPEN_READY'},
        prevEventHash: genesisEventHash,
        eventHash: 'hash_1',
      ),
      EventEnvelope(
        eventId: 'evt_2',
        eventType: 'HandStarted',
        eventVersion: '1.0',
        protocolVersion: '1.0.0',
        eventSeq: 2,
        tableId: 'table_1',
        sessionId: 'session_1',
        handId: 'hand_1',
        emittedAt: '2026-04-25T00:00:05Z',
        actorRef: 'system',
        payload: const {'phase': 'LIVE_ACTIVE'},
        prevEventHash: 'hash_1',
        eventHash: 'hash_2',
      ),
    ];

    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: events,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.state, isNotNull);
    expect(result.state!.appliedEventTypes, [
      'OpenTableSessionOpened',
      'HandStarted',
    ]);
    expect(result.finalAppliedEventSeq, 2);
    expect(result.reconstructedAnchor, isNotNull);
  });

  test(
    'rejects full replay window that does not start at event sequence 1',
    () {
      final result = engine.replay(
        ReplayRequest(
          tableId: 'table_1',
          sessionId: 'session_1',
          protocolVersion: '1.0.0',
          scope: ReplayScope.session,
          events: <EventEnvelope>[
            EventEnvelope(
              eventId: 'evt_2',
              eventType: 'HandStarted',
              eventVersion: '1.0',
              protocolVersion: '1.0.0',
              eventSeq: 2,
              tableId: 'table_1',
              sessionId: 'session_1',
              handId: 'hand_1',
              emittedAt: '2026-04-25T00:00:05Z',
              actorRef: 'system',
              payload: <String, Object?>{'phase': 'LIVE_ACTIVE'},
              prevEventHash: genesisEventHash,
              eventHash: 'hash_2',
            ),
          ],
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.state, isNull);
      expect(
        result.mismatches.single.code,
        'ERR_REPLAY_EVENT_WINDOW_START_GAP',
      );
    },
  );

  test('rejects full replay window with a non-genesis first hash', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
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
            payload: <String, Object?>{'phase': 'OPEN_READY'},
            prevEventHash: 'root',
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_GENESIS_HASH_MISMATCH');
    expect(result.mismatches.single.expected, genesisEventHash);
    expect(result.mismatches.single.actual, 'root');
  });

  test('rejects non-positive replay event range before projection', () {
    final failingEngine = BasicReplayEngine<FakeTableProjection>(
      projector: const _ThrowingReplayProjector(throwOnCreate: true),
    );

    final result = failingEngine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: const <EventEnvelope>[],
        fromEventSeq: 0,
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.finalAppliedEventSeq, isNull);
    expect(result.reconstructedAnchor, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_EVENT_RANGE_INVALID');
    expect(
      result.mismatches.single.message,
      'Replay from-event sequence must be positive.',
    );
    expect(result.mismatches.single.expected, '>=1');
    expect(result.mismatches.single.actual, 0);
  });

  test('rejects oversized replay event windows before request traversal', () {
    final failingEngine = BasicReplayEngine<FakeTableProjection>(
      projector: const _ThrowingReplayProjector(throwOnCreate: true),
      eventWindowValidator: EventWindowValidator(maxEvents: 2),
    );

    final event = EventEnvelope(
      eventId: 'evt_1',
      eventType: 'OpenTableSessionOpened',
      eventVersion: '1.0',
      protocolVersion: '9.9.9',
      eventSeq: 1,
      tableId: 'table_1',
      sessionId: 'session_1',
      handId: null,
      emittedAt: '2026-04-25T00:00:00Z',
      actorRef: 'system',
      payload: const <String, Object?>{},
      prevEventHash: genesisEventHash,
      eventHash: 'hash_1',
    );

    final result = failingEngine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: currentProtocolVersion.toWire(),
        scope: ReplayScope.session,
        events: List<EventEnvelope>.filled(3, event),
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_EVENT_WINDOW_TOO_LARGE');
    expect(result.mismatches.single.expected, 2);
    expect(result.mismatches.single.actual, 3);
  });

  test('fails closed when replay anchor calculation throws', () {
    final event = EventEnvelope(
      eventId: 'evt_1',
      eventType: 'OpenTableSessionOpened',
      eventVersion: '1.0',
      protocolVersion: currentProtocolVersion.toWire(),
      eventSeq: 1,
      tableId: 'table_1',
      sessionId: 'session_1',
      handId: null,
      emittedAt: '2026-04-25T00:00:00Z',
      actorRef: 'system',
      payload: const <String, Object?>{},
      prevEventHash: genesisEventHash,
      eventHash: List<String>.filled(4097, 'h').join(),
    );

    final result =
        BasicReplayEngine<FakeTableProjection>(
          projector: FakeTableProjector(),
        ).replay(
          ReplayRequest(
            tableId: 'table_1',
            sessionId: 'session_1',
            protocolVersion: currentProtocolVersion.toWire(),
            scope: ReplayScope.session,
            events: <EventEnvelope>[event],
          ),
        );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.reconstructedAnchor, isNull);
    expect(
      result.mismatches.single.code,
      'ERR_REPLAY_ANCHOR_CALCULATION_FAILURE',
    );
  });

  test('rejects inverted replay event range before projection', () {
    final failingEngine = BasicReplayEngine<FakeTableProjection>(
      projector: const _ThrowingReplayProjector(throwOnCreate: true),
    );

    final result = failingEngine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: const <EventEnvelope>[],
        fromEventSeq: 3,
        toEventSeq: 2,
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.finalAppliedEventSeq, isNull);
    expect(result.reconstructedAnchor, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_EVENT_RANGE_INVALID');
    expect(
      result.mismatches.single.message,
      'Replay from-event sequence must not exceed to-event sequence.',
    );
    expect(result.mismatches.single.expected, '<=2');
    expect(result.mismatches.single.actual, 3);
  });

  test('replays fixture-backed Holdem showdown settlement lifecycle', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final first = events.first;

    final result = engine.replay(
      ReplayRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        scope: ReplayScope.hand,
        events: events,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.mismatches, isEmpty);
    expect(result.finalAppliedEventSeq, 5);
    expect(result.reconstructedAnchor, isNotNull);
    expect(result.state!.appliedEventTypes, <String>[
      'HandStarted',
      'ShowdownStarted',
      'ShowdownRevealed',
      'SettlementProjected',
      'HandSettled',
    ]);
  });

  test('replays Holdem settlement metadata through core projector', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final first = events.first;
    final coreReplayEngine = BasicReplayEngine<TableState>(
      projector: const _CoreReplayProjector(),
    );

    final result = coreReplayEngine.replay(
      ReplayRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        scope: ReplayScope.hand,
        events: events,
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

  test('replays Holdem settlement suffix after snapshot base', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final first = events.first;

    final result = engine.replay(
      ReplayRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        scope: ReplayScope.hand,
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
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.mismatches, isEmpty);
    expect(result.finalAppliedEventSeq, 5);
    expect(
      result.warnings,
      contains('Replay used snapshot + suffix planning path.'),
    );
    expect(result.state!.appliedEventTypes, <String>[
      'SettlementProjected',
      'HandSettled',
    ]);
  });

  test('fails closed when snapshot suffix selection exceeds its limit', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final first = events.first;
    final limitedEngine = BasicReplayEngine<FakeTableProjection>(
      projector: FakeTableProjector(),
      snapshotSuffixReplayer: SnapshotSuffixReplayer(maxEvents: 1),
    );

    final result = limitedEngine.replay(
      ReplayRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        scope: ReplayScope.hand,
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
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_SELECTION_FAILURE');
  });

  test('replays fixture-backed Holdem blocked settlement path', () {
    final events = _loadHoldemBlockedSettlementEvents();
    final first = events.first;

    final result = engine.replay(
      ReplayRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        scope: ReplayScope.hand,
        events: events,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.mismatches, isEmpty);
    expect(result.finalAppliedEventSeq, 4);
    expect(result.state!.appliedEventTypes, <String>[
      'HandStarted',
      'ShowdownStarted',
      'ShowdownRevealed',
      'SettlementBlocked',
    ]);
  });

  test(
    'replays Holdem blocked settlement reason codes through core projector',
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
      final coreReplayEngine = BasicReplayEngine<TableState>(
        projector: const _CoreReplayProjector(),
      );

      for (final entry in fixtureCases.entries) {
        final events = _loadHoldemBlockedSettlementEvents(
          blockedFixturePath: entry.key,
        );
        final first = events.first;

        final result = coreReplayEngine.replay(
          ReplayRequest(
            tableId: first.tableId,
            sessionId: first.sessionId,
            protocolVersion: first.protocolVersion,
            scope: ReplayScope.hand,
            events: events,
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

  test('rejects Holdem lifecycle fixture stream with missing reveal event', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final gappedEvents = <EventEnvelope>[
      events[0],
      events[1],
      events[3],
      events[4],
    ];
    final first = gappedEvents.first;

    final result = engine.replay(
      ReplayRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        scope: ReplayScope.hand,
        events: gappedEvents,
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(
      result.mismatches.map((mismatch) => mismatch.code),
      contains('ERR_REPLAY_EVENT_GAP'),
    );
  });

  test('rejects Holdem lifecycle fixture stream with divergent hash chain', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final divergentEvents = <EventEnvelope>[
      ...events.take(3),
      _copyEvent(events[3], prevEventHash: 'hash_holdem_diverged'),
      events[4],
    ];
    final first = divergentEvents.first;

    final result = engine.replay(
      ReplayRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        scope: ReplayScope.hand,
        events: divergentEvents,
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_HASH_CHAIN_BREAK');
    expect(result.mismatches.single.expected, 'hash_holdem_003');
    expect(result.mismatches.single.actual, 'hash_holdem_diverged');
  });

  test('rejects Holdem settlement suffix with missing projected event', () {
    final events = _loadHoldemShowdownSettlementEvents();
    final first = events.first;

    final result = engine.replay(
      ReplayRequest(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
        scope: ReplayScope.hand,
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
        events: <EventEnvelope>[events[0], events[1], events[2], events[4]],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_SNAPSHOT_SUFFIX_GAP');
    expect(result.mismatches.single.expected, 4);
    expect(result.mismatches.single.actual, 5);
  });

  test('rejects unsupported replay protocol before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '2.0.0',
        scope: ReplayScope.session,
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_PROTOCOL_INCOMPATIBLE');
    expect(result.mismatches.single.toProtocolDiagnostic().toJson(), {
      'code': 'ERR_REPLAY_PROTOCOL_INCOMPATIBLE',
      'message': 'Replay request protocol version is not supported.',
      'expected': '1.0.0',
      'actual': '2.0.0',
    });
    expect(result.diagnostics.single.toJson(), {
      'code': 'ERR_REPLAY_PROTOCOL_INCOMPATIBLE',
      'message': 'Replay request protocol version is not supported.',
      'expected': '1.0.0',
      'actual': '2.0.0',
    });
  });

  test('rejects event protocol mismatch before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'OpenTableSessionOpened',
            eventVersion: '1.0',
            protocolVersion: '2.0.0',
            eventSeq: 1,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'host_1',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(
      result.mismatches.single.code,
      'ERR_REPLAY_EVENT_PROTOCOL_INCOMPATIBLE',
    );
  });

  test('rejects event scope mismatch before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'OpenTableSessionOpened',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 1,
            tableId: 'other_table',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'host_1',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_EVENT_SCOPE_MISMATCH');
    expect(result.mismatches.single.expected, 'table_1/session_1');
    expect(result.mismatches.single.actual, 'other_table/session_1');
  });

  test('rejects snapshot scope mismatch before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_1',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'other_session',
          snapshotBaseEventSeq: 1,
          snapshotHash: 'snap_hash',
          payload: <String, Object?>{},
        ),
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_SNAPSHOT_SCOPE_MISMATCH');
    expect(result.mismatches.single.expected, 'table_1/session_1');
    expect(result.mismatches.single.actual, 'table_1/other_session');
  });

  test('rejects unsupported event artifact before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'UnknownEvent',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 1,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'host_1',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(
      result.mismatches.single.code,
      'ERR_REPLAY_EVENT_SCHEMA_UNSUPPORTED',
    );
  });

  test('rejects unsupported snapshot artifact before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_1',
          snapshotType: 'UnknownSnapshot',
          snapshotVersion: '1.0',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 1,
          snapshotHash: 'snap_hash',
          payload: <String, Object?>{},
        ),
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(
      result.mismatches.single.code,
      'ERR_REPLAY_SNAPSHOT_SCHEMA_UNSUPPORTED',
    );
  });

  test('rejects snapshot suffix gap before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
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
            eventType: 'PlayerCalled',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 4,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: 'hand_1',
            emittedAt: '2026-04-25T00:00:10Z',
            actorRef: 'player_1',
            payload: <String, Object?>{},
            prevEventHash: 'hash_3',
            eventHash: 'hash_4',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_SNAPSHOT_SUFFIX_GAP');
    expect(result.mismatches.single.expected, 3);
    expect(result.mismatches.single.actual, 4);
  });

  test('fails closed when replay projector cannot create base state', () {
    final failingEngine = BasicReplayEngine<FakeTableProjection>(
      projector: const _ThrowingReplayProjector(throwOnCreate: true),
    );

    final result = failingEngine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.finalAppliedEventSeq, isNull);
    expect(result.reconstructedAnchor, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_PROJECTOR_FAILURE');
    expect(
      result.mismatches.single.message,
      'Replay projector failed during reconstruction.',
    );
    expect(result.mismatches.single.actual, '_ReplayProjectorFailure');
  });

  test('fails closed when replay projector cannot apply an event', () {
    final failingEngine = BasicReplayEngine<FakeTableProjection>(
      projector: const _ThrowingReplayProjector(throwOnApply: true),
    );

    final result = failingEngine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
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
            payload: <String, Object?>{'phase': 'OPEN_READY'},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.finalAppliedEventSeq, isNull);
    expect(result.reconstructedAnchor, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_PROJECTOR_FAILURE');
    expect(result.mismatches.single.actual, '_ReplayProjectorFailure');
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

class _CoreReplayProjector implements ReplayStateProjector<TableState> {
  const _CoreReplayProjector();

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
  TableState applyEvent({
    required TableState state,
    required EventEnvelope event,
  }) {
    return const CoreReducer().apply(state, event);
  }
}

class _ThrowingReplayProjector
    implements ReplayStateProjector<FakeTableProjection> {
  const _ThrowingReplayProjector({
    this.throwOnCreate = false,
    this.throwOnApply = false,
  });

  final bool throwOnCreate;
  final bool throwOnApply;

  @override
  FakeTableProjection createBaseState({
    required String tableId,
    required String sessionId,
    required String protocolVersion,
  }) {
    if (throwOnCreate) {
      throw const _ReplayProjectorFailure();
    }
    return FakeTableProjection(
      tableId: tableId,
      sessionId: sessionId,
      protocolVersion: protocolVersion,
      appliedEventTypes: const <String>[],
    );
  }

  @override
  FakeTableProjection applyEvent({
    required FakeTableProjection state,
    required EventEnvelope event,
  }) {
    if (throwOnApply) {
      throw const _ReplayProjectorFailure();
    }
    return state.copyWithEvent(event.eventType);
  }
}

class _ReplayProjectorFailure implements Exception {
  const _ReplayProjectorFailure();
}

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';
import 'package:test/test.dart';

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
        prevEventHash: 'root',
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
  });

  test('rejects event protocol mismatch before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: const <EventEnvelope>[
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
            prevEventHash: 'root',
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
}

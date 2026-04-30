import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';
import 'package:test/test.dart';

void main() {
  const replayer = SnapshotSuffixReplayer();

  test('filters suffix events after snapshot base sequence', () {
    final snapshot = SnapshotEnvelope(
      snapshotId: 'snap_1',
      protocolVersion: '1.0.0',
      tableId: 'table_1',
      sessionId: 'session_1',
      snapshotBaseEventSeq: 2,
      snapshotHash: 'snap_hash',
      payload: const {'phase': 'LIVE_ACTIVE'},
    );

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
        payload: const {},
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
        payload: const {},
        prevEventHash: 'hash_1',
        eventHash: 'hash_2',
      ),
      EventEnvelope(
        eventId: 'evt_3',
        eventType: 'PlayerCalled',
        eventVersion: '1.0',
        protocolVersion: '1.0.0',
        eventSeq: 3,
        tableId: 'table_1',
        sessionId: 'session_1',
        handId: 'hand_1',
        emittedAt: '2026-04-25T00:00:10Z',
        actorRef: 'player_1',
        payload: const {},
        prevEventHash: 'hash_2',
        eventHash: 'hash_3',
      ),
    ];

    final result = replayer.plan(snapshot: snapshot, events: events);

    expect(result.snapshotBaseEventSeq, 2);
    expect(result.eventsToApply.map((e) => e.eventSeq).toList(), [3]);
  });
}

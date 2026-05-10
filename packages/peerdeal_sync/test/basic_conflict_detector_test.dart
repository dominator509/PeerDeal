import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  const detector = BasicConflictDetector();

  test(
    'flags fatal mismatch when final event hash differs from expected baseline',
    () {
      final result = detector.detect(
        const RecoveryRequest(
          tableId: 'table_1',
          sessionId: 'session_1',
          protocolVersion: '1.0.0',
          mode: RecoveryMode.primaryPeerTransfer,
          expectedFinalEventHash: 'expected_hash',
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
              eventHash: 'actual_hash',
            ),
          ],
        ),
      );

      expect(result.hasFatalConflicts, isTrue);
      expect(result.conflicts.first.code, 'ERR_FINAL_EVENT_HASH_MISMATCH');
    },
  );

  test('flags fatal unsupported recovery protocol', () {
    final result = detector.detect(
      const RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '2.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_RECOVERY_PROTOCOL_INCOMPATIBLE');
  });

  test('flags fatal event protocol mismatch', () {
    final result = detector.detect(
      const RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
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
            prevEventHash: 'root',
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_EVENT_PROTOCOL_INCOMPATIBLE');
  });

  test('flags fatal unsupported event artifact', () {
    final result = detector.detect(
      const RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
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
            prevEventHash: 'root',
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_EVENT_SCHEMA_UNSUPPORTED');
  });

  test('flags fatal unsupported snapshot artifact', () {
    final result = detector.detect(
      const RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
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
        events: <EventEnvelope>[],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_SNAPSHOT_SCHEMA_UNSUPPORTED');
  });
}

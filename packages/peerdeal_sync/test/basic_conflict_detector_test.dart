import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  const detector = BasicConflictDetector();

  test('flags fatal mismatch when final event hash differs from expected baseline', () {
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
  });
}

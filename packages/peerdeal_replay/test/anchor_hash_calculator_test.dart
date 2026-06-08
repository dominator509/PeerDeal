import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';
import 'package:test/test.dart';

void main() {
  const calculator = AnchorHashCalculator();

  test('produces deterministic anchor for same event window', () {
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
    ];

    final first = calculator.calculate(
      scope: ReplayScope.session,
      events: events,
    );
    final second = calculator.calculate(
      scope: ReplayScope.session,
      events: events,
    );

    expect(first, equals(second));
  });
}

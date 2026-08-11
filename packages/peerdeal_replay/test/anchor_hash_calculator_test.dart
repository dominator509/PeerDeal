import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';
import 'package:test/test.dart';

void main() {
  final calculator = AnchorHashCalculator();

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

  test('supports the default bounded replay event window', () {
    final event = EventEnvelope(
      eventId: 'evt_1',
      eventType: 'OpenTableSessionOpened',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
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

    final anchor = calculator.calculate(
      scope: ReplayScope.session,
      events: List<EventEnvelope>.filled(257, event),
    );

    expect(anchor.value, hasLength(64));
  });

  test('rejects anchor windows above the configured limit', () {
    final event = EventEnvelope(
      eventId: 'evt_1',
      eventType: 'OpenTableSessionOpened',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
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

    expect(
      () => AnchorHashCalculator(maxEvents: 2).calculate(
        scope: ReplayScope.session,
        events: List<EventEnvelope>.filled(3, event),
      ),
      throwsArgumentError,
    );
  });
}

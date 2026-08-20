import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('canonical event hash excludes event_hash itself', () {
    final unsigned = _event(eventHash: '');
    final valid = _event(eventHash: computeCanonicalEventHash(unsigned));

    expect(isCanonicalEventHashValid(valid), isTrue);
    expect(
      canonicalEventHashPayload(valid),
      isNot(containsPair('event_hash', anything)),
    );
  });

  test('canonical event hash changes when envelope content changes', () {
    final unsigned = _event(eventHash: '');
    final valid = _event(eventHash: computeCanonicalEventHash(unsigned));
    final changed = _event(
      payload: const <String, Object?>{'changed': true},
      eventHash: valid.eventHash,
    );

    expect(isCanonicalEventHashValid(valid), isTrue);
    expect(isCanonicalEventHashValid(changed), isFalse);
  });
}

EventEnvelope _event({
  Map<String, Object?> payload = const <String, Object?>{},
  required String eventHash,
}) => EventEnvelope(
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
  payload: payload,
  prevEventHash: genesisEventHash,
  eventHash: eventHash,
);

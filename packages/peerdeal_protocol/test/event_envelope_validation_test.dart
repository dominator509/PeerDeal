import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('accepts a safe complete event envelope identity', () {
    final result = validateEventEnvelopeIdentity(_event());

    expect(result.isValid, isTrue);
    expect(result.emptyFields, isEmpty);
    expect(result.unsafeFields, isEmpty);
  });

  test('reports empty and unsafe identity fields separately', () {
    final empty = validateEventEnvelopeIdentity(
      _event(eventId: '   ', emittedAt: ''),
    );
    expect(empty.emptyFields, containsAll(<String>['event_id', 'emitted_at']));
    expect(empty.unsafeFields, isEmpty);

    final unsafe = validateEventEnvelopeIdentity(_event(actorRef: 'actor\n'));
    expect(unsafe.emptyFields, isEmpty);
    expect(unsafe.unsafeFields, contains('actor_ref'));
  });
}

EventEnvelope _event({
  String eventId = 'event_1',
  String emittedAt = '2026-08-20T00:00:00Z',
  String actorRef = 'actor_1',
}) {
  return EventEnvelope(
    eventId: eventId,
    eventType: 'HandStarted',
    eventVersion: '1.0',
    protocolVersion: '1.0',
    eventSeq: 1,
    tableId: 'table_1',
    sessionId: 'session_1',
    handId: 'hand_1',
    emittedAt: emittedAt,
    actorRef: actorRef,
    payload: const <String, Object?>{},
    prevEventHash: genesisEventHash,
    eventHash: 'hash_1',
  );
}

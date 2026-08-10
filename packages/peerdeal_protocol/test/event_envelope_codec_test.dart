import 'dart:convert';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

void main() {
  final event = EventEnvelope(
    eventId: 'evt_1',
    eventType: 'OpenTableSessionOpened',
    eventVersion: '1.0',
    protocolVersion: '1.0.0',
    eventSeq: 1,
    tableId: 'table_1',
    sessionId: 'session_1',
    handId: null,
    emittedAt: '2026-08-09T12:00:00.000Z',
    actorRef: 'actor_1',
    payload: const <String, Object?>{'mode_type': 'cash'},
    prevEventHash: genesisEventHash,
    eventHash: 'hash_1',
  );

  test('round-trips an event through canonical wire bytes', () {
    const codec = EventEnvelopeCodec();

    final bytes = codec.encode(event);
    final decoded = codec.decode(bytes);

    expect(utf8.decode(bytes), canonicalJsonEncode(event.toJson()));
    expect(decoded.toJson(), event.toJson());
  });

  test('rejects empty, malformed, and non-object wire payloads', () {
    const codec = EventEnvelopeCodec();

    expect(() => codec.decode(const <int>[]), throwsFormatException);
    expect(() => codec.decode(utf8.encode('{')), throwsFormatException);
    expect(() => codec.decode(utf8.encode('[]')), throwsFormatException);
  });

  test('bounds encoded and decoded wire payloads', () {
    const codec = EventEnvelopeCodec(maxBytes: 8);

    expect(() => codec.encode(event), throwsFormatException);
    expect(() => codec.decode(List<int>.filled(9, 65)), throwsFormatException);
    expect(
      () => const EventEnvelopeCodec(maxBytes: 0).decode(<int>[65]),
      throwsArgumentError,
    );
  });
}

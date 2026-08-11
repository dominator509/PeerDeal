import 'dart:convert';

import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips HoldemEventCursor state through JSON', () {
    final cursor = HoldemEventCursor(
      protocolVersion: '1.0.0',
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      nextEventSeq: 7,
      previousEventHash: 'hash_006',
      actorRef: 'peer_local',
      eventIdFactory: (eventType, eventSeq) => '$eventType-$eventSeq',
      emittedAtFactory: () => '2026-08-10T00:00:00.000Z',
      lastEventType: 'PlayerCalled',
    );

    final persisted = Map<String, Object?>.from(
      jsonDecode(jsonEncode(cursor.toJson())) as Map,
    );
    final restored = HoldemEventCursor.fromJson(
      persisted,
      eventIdFactory: (eventType, eventSeq) => '$eventType-$eventSeq',
      emittedAtFactory: () => '2026-08-10T00:00:00.000Z',
    );

    expect(restored.toJson(), cursor.toJson());
    expect(restored.eventIdFactory('PlayerChecked', 8), 'PlayerChecked-8');
    expect(restored.emittedAtFactory(), '2026-08-10T00:00:00.000Z');
  });

  test('preserves an injected event hash policy during hydration', () {
    final cursor = HoldemEventCursor.fromJson(
      _cursorJson(),
      eventIdFactory: (_, eventSeq) => 'event-$eventSeq',
      emittedAtFactory: () => 'timestamp',
      eventHashFactory: (_) => 'custom_hash',
    );

    expect(cursor.eventHashFactory(const <String, Object?>{}), 'custom_hash');
  });

  test('rejects malformed cursor persistence fields', () {
    final wrongSequence = _cursorJson()..['next_event_seq'] = 'seven';
    expect(
      () => HoldemEventCursor.fromJson(
        wrongSequence,
        eventIdFactory: (_, _) => 'event',
        emittedAtFactory: () => 'timestamp',
      ),
      throwsA(isA<FormatException>()),
    );

    final wrongLastEventType = _cursorJson()
      ..['last_event_type'] = <String>['PlayerCalled'];
    expect(
      () => HoldemEventCursor.fromJson(
        wrongLastEventType,
        eventIdFactory: (_, _) => 'event',
        emittedAtFactory: () => 'timestamp',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Map<String, Object?> _cursorJson() => <String, Object?>{
  'protocol_version': '1.0.0',
  'table_id': 'tbl_001',
  'session_id': 'sess_001',
  'next_event_seq': 7,
  'previous_event_hash': 'hash_006',
  'actor_ref': 'peer_local',
  'last_event_type': 'PlayerCalled',
};

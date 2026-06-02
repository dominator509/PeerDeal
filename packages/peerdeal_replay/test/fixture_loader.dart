import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

List<EventEnvelope> loadReplayFixtureEvents(String path) {
  final raw = File(path).readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, Object?>;
  final events = decoded['events'] as List<Object?>;
  return events
      .map(
        (entry) => eventEnvelopeFromFixtureJson(entry as Map<String, Object?>),
      )
      .toList(growable: false);
}

EventEnvelope loadProtocolEventFixture(String path) {
  final raw = File('../peerdeal_protocol/fixtures/$path').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, Object?>;
  return eventEnvelopeFromFixtureJson(decoded);
}

EventEnvelope eventEnvelopeFromFixtureJson(Map<String, Object?> map) {
  return EventEnvelope(
    eventId: map['event_id']! as String,
    eventType: map['event_type']! as String,
    eventVersion: map['event_version']! as String,
    protocolVersion: map['protocol_version']! as String,
    eventSeq: map['event_seq']! as int,
    tableId: map['table_id']! as String,
    sessionId: map['session_id']! as String,
    handId: map['hand_id'] as String?,
    emittedAt: map['emitted_at']! as String,
    actorRef: map['actor_ref']! as String,
    payload: (map['payload']! as Map).cast<String, Object?>(),
    prevEventHash: map['prev_event_hash']! as String,
    eventHash: map['event_hash']! as String,
  );
}

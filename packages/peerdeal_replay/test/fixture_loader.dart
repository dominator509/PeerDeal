import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';

class ReplayFixture {
  const ReplayFixture({required this.request});

  final ReplayRequest request;
}

List<EventEnvelope> loadReplayFixtureEvents(String path) {
  final raw = File(path).readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, Object?>;
  return _eventsFromJson(decoded['events']);
}

ReplayFixture loadReplayFixture(String path) {
  final raw = File(path).readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, Object?>;
  final snapshot = _optionalMap(decoded['snapshot']);
  final expectedAnchor = _optionalMap(decoded['expected_anchor']);

  return ReplayFixture(
    request: ReplayRequest(
      tableId: decoded['table_id']! as String,
      sessionId: decoded['session_id']! as String,
      protocolVersion: decoded['protocol_version']! as String,
      scope: _replayScope(decoded['scope']! as String),
      events: _eventsFromJson(decoded['events']),
      snapshot: snapshot == null ? null : SnapshotEnvelope.fromJson(snapshot),
      expectedAnchor: expectedAnchor == null
          ? null
          : AnchorHash(
              scope: expectedAnchor['scope']! as String,
              value: expectedAnchor['value']! as String,
            ),
    ),
  );
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

List<EventEnvelope> _eventsFromJson(Object? value) {
  return (value as List<Object?>)
      .map(
        (entry) => eventEnvelopeFromFixtureJson(entry as Map<String, Object?>),
      )
      .toList(growable: false);
}

Map<String, Object?>? _optionalMap(Object? value) {
  if (value == null) return null;
  return (value as Map).cast<String, Object?>();
}

ReplayScope _replayScope(String value) {
  return ReplayScope.values.singleWhere((scope) => scope.name == value);
}

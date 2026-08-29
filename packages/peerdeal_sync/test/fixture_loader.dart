import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

Map<String, Object?> loadFixture(String relativePath) {
  final file = File(relativePath);
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

class RecoveryFixture {
  RecoveryFixture({
    required this.protocolVersion,
    required this.tableId,
    required this.sessionId,
    required this.snapshot,
    required List<EventEnvelope> suffixEvents,
    this.expectedFinalEventSeq,
    this.expectedFinalEventHash,
  }) : suffixEvents = List<EventEnvelope>.unmodifiable(suffixEvents);

  final String protocolVersion;
  final String tableId;
  final String sessionId;
  final SnapshotEnvelope snapshot;
  final List<EventEnvelope> suffixEvents;
  final int? expectedFinalEventSeq;
  final String? expectedFinalEventHash;

  RecoveryRequest toRequest({RecoveryMode mode = RecoveryMode.reconnect}) {
    return RecoveryRequest(
      tableId: tableId,
      sessionId: sessionId,
      protocolVersion: protocolVersion,
      mode: mode,
      snapshot: snapshot,
      events: suffixEvents,
      expectedFinalEventSeq: expectedFinalEventSeq,
      expectedFinalEventHash: expectedFinalEventHash,
    );
  }
}

RecoveryFixture loadRecoveryFixture(String relativePath) {
  final fixture = loadFixture(relativePath);
  final snapshotJson = fixture['snapshot'];
  if (snapshotJson is! Map) {
    throw const FormatException('Recovery fixture snapshot must be an object.');
  }
  final snapshot = SnapshotEnvelope.fromJson(
    snapshotJson.cast<String, Object?>(),
  );

  final suffixJson = fixture['suffix_events'];
  if (suffixJson is! List) {
    throw const FormatException(
      'Recovery fixture suffix_events must be an array.',
    );
  }
  final suffixEvents = <EventEnvelope>[];
  for (final rawEvent in suffixJson) {
    if (rawEvent is! Map) {
      throw const FormatException(
        'Recovery fixture suffix_events entries must be objects.',
      );
    }
    suffixEvents.add(
      eventEnvelopeFromFixtureJson(rawEvent.cast<String, Object?>()),
    );
  }

  return RecoveryFixture(
    protocolVersion:
        _optionalString(fixture, 'protocol_version') ??
        snapshot.protocolVersion,
    tableId: _optionalString(fixture, 'table_id') ?? snapshot.tableId,
    sessionId: _optionalString(fixture, 'session_id') ?? snapshot.sessionId,
    snapshot: snapshot,
    suffixEvents: suffixEvents,
    expectedFinalEventSeq: _optionalInt(fixture, 'expected_final_event_seq'),
    expectedFinalEventHash: _optionalString(
      fixture,
      'expected_final_event_hash',
    ),
  );
}

String? _optionalString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Recovery fixture $key must be a string.');
}

int? _optionalInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('Recovery fixture $key must be an integer.');
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

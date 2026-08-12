import '../serialization/canonical_json.dart';
import 'model_collection_ownership.dart';

class EventEnvelope {
  EventEnvelope({
    required this.eventId,
    required this.eventType,
    required this.eventVersion,
    required this.protocolVersion,
    required this.eventSeq,
    required this.tableId,
    required this.sessionId,
    required this.handId,
    required this.emittedAt,
    required this.actorRef,
    required Map<String, Object?> payload,
    required this.prevEventHash,
    required this.eventHash,
  }) : payload = freezeProtocolObjectMap(payload);

  final String eventId;
  final String eventType;
  final String eventVersion;
  final String protocolVersion;
  final int eventSeq;
  final String tableId;
  final String sessionId;
  final String? handId;
  final String emittedAt;
  final String actorRef;
  final Map<String, Object?> payload;
  final String prevEventHash;
  final String eventHash;

  factory EventEnvelope.fromJson(Map<String, Object?> json) {
    canonicalJsonEncode(json);
    return EventEnvelope(
      eventId: _string(json, 'event_id'),
      eventType: _string(json, 'event_type'),
      eventVersion: _string(json, 'event_version'),
      protocolVersion: _string(json, 'protocol_version'),
      eventSeq: _int(json, 'event_seq'),
      tableId: _string(json, 'table_id'),
      sessionId: _string(json, 'session_id'),
      handId: _nullableString(json, 'hand_id'),
      emittedAt: _string(json, 'emitted_at'),
      actorRef: _string(json, 'actor_ref'),
      payload: _map(json, 'payload'),
      prevEventHash: _string(json, 'prev_event_hash'),
      eventHash: _string(json, 'event_hash'),
    );
  }

  Map<String, Object?> toJson() => {
    'event_id': eventId,
    'event_type': eventType,
    'event_version': eventVersion,
    'protocol_version': protocolVersion,
    'event_seq': eventSeq,
    'table_id': tableId,
    'session_id': sessionId,
    'hand_id': handId,
    'emitted_at': emittedAt,
    'actor_ref': actorRef,
    'payload': payload,
    'prev_event_hash': prevEventHash,
    'event_hash': eventHash,
  };

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Expected string at $key.');
  }

  static String? _nullableString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Expected nullable string at $key.');
  }

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Expected int at $key.');
  }

  static Map<String, Object?> _map(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is Map<String, Object?>) return value;
    throw FormatException('Expected object at $key.');
  }
}

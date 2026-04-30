class EventEnvelope {
  const EventEnvelope({
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
    required this.payload,
    required this.prevEventHash,
    required this.eventHash,
  });

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
}

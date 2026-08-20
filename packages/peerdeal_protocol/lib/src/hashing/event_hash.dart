import '../models/event_envelope.dart';
import 'hash_chain.dart';

/// Calculates the content hash for a protocol event envelope.
///
/// The event hash covers every envelope field except `event_hash` itself.
/// Protocol variants may inject a documented alternative calculator, while
/// generic protocol consumers use this canonical calculator.
typedef EventHashCalculator = String Function(EventEnvelope event);

Map<String, Object?> canonicalEventHashPayload(EventEnvelope event) =>
    <String, Object?>{
      'event_id': event.eventId,
      'event_type': event.eventType,
      'event_version': event.eventVersion,
      'protocol_version': event.protocolVersion,
      'event_seq': event.eventSeq,
      'table_id': event.tableId,
      'session_id': event.sessionId,
      'hand_id': event.handId,
      'emitted_at': event.emittedAt,
      'actor_ref': event.actorRef,
      'payload': event.payload,
      'prev_event_hash': event.prevEventHash,
    };

String computeCanonicalEventHash(EventEnvelope event) =>
    computeCanonicalHash(canonicalEventHashPayload(event));

bool isCanonicalEventHashValid(EventEnvelope event) =>
    event.eventHash == computeCanonicalEventHash(event);

import '../models/event_envelope.dart';
import '../serialization/canonical_json_limits.dart';

/// Reports identity fields that make an event envelope unsafe to consume.
final class EventEnvelopeIdentityValidation {
  const EventEnvelopeIdentityValidation({
    required this.emptyFields,
    required this.unsafeFields,
  });

  final List<String> emptyFields;
  final List<String> unsafeFields;

  bool get isValid => emptyFields.isEmpty && unsafeFields.isEmpty;
}

/// Validates envelope identity independently of reducer policy.
///
/// Replay, sync, and persistence boundaries must apply the same ingress
/// identity rule as the core reducer before accepting an event. This helper
/// deliberately does not validate payload semantics or event-hash policy.
EventEnvelopeIdentityValidation validateEventEnvelopeIdentity(
  EventEnvelope event,
) {
  final emptyFields = <String>[
    if (event.eventId.trim().isEmpty) 'event_id',
    if (event.eventType.trim().isEmpty) 'event_type',
    if (event.eventVersion.trim().isEmpty) 'event_version',
    if (event.protocolVersion.trim().isEmpty) 'protocol_version',
    if (event.tableId.trim().isEmpty) 'table_id',
    if (event.sessionId.trim().isEmpty) 'session_id',
    if (event.emittedAt.trim().isEmpty) 'emitted_at',
    if (event.actorRef.trim().isEmpty) 'actor_ref',
    if (event.prevEventHash.trim().isEmpty) 'prev_event_hash',
    if (event.eventHash.trim().isEmpty) 'event_hash',
  ];
  if (emptyFields.isNotEmpty) {
    return EventEnvelopeIdentityValidation(
      emptyFields: List<String>.unmodifiable(emptyFields),
      unsafeFields: const <String>[],
    );
  }

  final unsafeFields = <String>[
    if (!_isSafeIdentity(event.eventId)) 'event_id',
    if (!_isSafeIdentity(event.eventType)) 'event_type',
    if (!_isSafeIdentity(event.eventVersion)) 'event_version',
    if (!_isSafeIdentity(event.protocolVersion)) 'protocol_version',
    if (!_isSafeIdentity(event.tableId)) 'table_id',
    if (!_isSafeIdentity(event.sessionId)) 'session_id',
    if (event.handId != null &&
        event.handId!.isNotEmpty &&
        !_isSafeIdentity(event.handId!))
      'hand_id',
    if (!_isSafeIdentity(event.emittedAt)) 'emitted_at',
    if (!_isSafeIdentity(event.actorRef)) 'actor_ref',
    if (!_isSafeIdentity(event.prevEventHash)) 'prev_event_hash',
    if (!_isSafeIdentity(event.eventHash)) 'event_hash',
  ];
  return EventEnvelopeIdentityValidation(
    emptyFields: const <String>[],
    unsafeFields: List<String>.unmodifiable(unsafeFields),
  );
}

bool _isSafeIdentity(String value) {
  if (value.trim() != value ||
      !const CanonicalJsonLimits().isWithinUtf8TextLimit(value)) {
    return false;
  }
  return value.codeUnits.every(
    (unit) => unit >= 0x20 && !(unit >= 0x7f && unit <= 0x9f),
  );
}

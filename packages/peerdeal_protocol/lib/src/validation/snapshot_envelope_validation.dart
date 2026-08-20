import '../models/snapshot_envelope.dart';
import '../serialization/canonical_json_limits.dart';

/// Reports identity fields that make a snapshot envelope unsafe to consume.
final class SnapshotEnvelopeIdentityValidation {
  const SnapshotEnvelopeIdentityValidation({
    required this.emptyFields,
    required this.unsafeFields,
  });

  final List<String> emptyFields;
  final List<String> unsafeFields;

  bool get isValid => emptyFields.isEmpty && unsafeFields.isEmpty;
}

/// Validates snapshot envelope identity independently of payload or catalog
/// policy. Sync, replay, and persistence boundaries can share this ingress
/// rule before traversing snapshot metadata or payload fields.
SnapshotEnvelopeIdentityValidation validateSnapshotEnvelopeIdentity(
  SnapshotEnvelope snapshot,
) {
  final emptyFields = <String>[
    if (snapshot.snapshotId.trim().isEmpty) 'snapshot_id',
    if (snapshot.snapshotType.trim().isEmpty) 'snapshot_type',
    if (snapshot.snapshotVersion.trim().isEmpty) 'snapshot_version',
    if (snapshot.protocolVersion.trim().isEmpty) 'protocol_version',
    if (snapshot.tableId.trim().isEmpty) 'table_id',
    if (snapshot.sessionId.trim().isEmpty) 'session_id',
    if (snapshot.snapshotHash.trim().isEmpty) 'snapshot_hash',
  ];
  if (emptyFields.isNotEmpty) {
    return SnapshotEnvelopeIdentityValidation(
      emptyFields: List<String>.unmodifiable(emptyFields),
      unsafeFields: const <String>[],
    );
  }

  final unsafeFields = <String>[
    if (!_isSafeIdentity(snapshot.snapshotId)) 'snapshot_id',
    if (!_isSafeIdentity(snapshot.snapshotType)) 'snapshot_type',
    if (!_isSafeIdentity(snapshot.snapshotVersion)) 'snapshot_version',
    if (!_isSafeIdentity(snapshot.protocolVersion)) 'protocol_version',
    if (!_isSafeIdentity(snapshot.tableId)) 'table_id',
    if (!_isSafeIdentity(snapshot.sessionId)) 'session_id',
    if (!_isSafeIdentity(snapshot.snapshotHash)) 'snapshot_hash',
  ];
  return SnapshotEnvelopeIdentityValidation(
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

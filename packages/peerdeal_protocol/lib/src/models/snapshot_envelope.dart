import '../serialization/canonical_json.dart';

class SnapshotEnvelope {
  const SnapshotEnvelope({
    required this.snapshotId,
    this.snapshotType = 'TableSnapshot',
    this.snapshotVersion = '1.0',
    required this.protocolVersion,
    required this.tableId,
    required this.sessionId,
    required this.snapshotBaseEventSeq,
    required this.snapshotHash,
    required this.payload,
  });

  final String snapshotId;
  final String snapshotType;
  final String snapshotVersion;
  final String protocolVersion;
  final String tableId;
  final String sessionId;
  final int snapshotBaseEventSeq;
  final String snapshotHash;
  final Map<String, Object?> payload;

  factory SnapshotEnvelope.fromJson(Map<String, Object?> json) {
    canonicalJsonEncode(json);
    return SnapshotEnvelope(
      snapshotId: _string(json, 'snapshot_id'),
      snapshotType: _stringWithDefault(json, 'snapshot_type', 'TableSnapshot'),
      snapshotVersion: _stringWithDefault(json, 'snapshot_version', '1.0'),
      protocolVersion: _string(json, 'protocol_version'),
      tableId: _string(json, 'table_id'),
      sessionId: _string(json, 'session_id'),
      snapshotBaseEventSeq: _int(json, 'snapshot_base_event_seq'),
      snapshotHash: _string(json, 'snapshot_hash'),
      payload: _map(json, 'payload'),
    );
  }

  Map<String, Object?> toJson() => {
    'snapshot_id': snapshotId,
    'snapshot_type': snapshotType,
    'snapshot_version': snapshotVersion,
    'protocol_version': protocolVersion,
    'table_id': tableId,
    'session_id': sessionId,
    'snapshot_base_event_seq': snapshotBaseEventSeq,
    'snapshot_hash': snapshotHash,
    'payload': payload,
  };

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Expected string at $key.');
  }

  static String _stringWithDefault(
    Map<String, Object?> json,
    String key,
    String defaultValue,
  ) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    throw FormatException('Expected string at $key.');
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

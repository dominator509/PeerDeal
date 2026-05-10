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
}

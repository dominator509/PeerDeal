class SnapshotEnvelope {
  const SnapshotEnvelope({
    required this.snapshotId,
    required this.protocolVersion,
    required this.tableId,
    required this.sessionId,
    required this.snapshotBaseEventSeq,
    required this.snapshotHash,
    required this.payload,
  });

  final String snapshotId;
  final String protocolVersion;
  final String tableId;
  final String sessionId;
  final int snapshotBaseEventSeq;
  final String snapshotHash;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
        'snapshot_id': snapshotId,
        'protocol_version': protocolVersion,
        'table_id': tableId,
        'session_id': sessionId,
        'snapshot_base_event_seq': snapshotBaseEventSeq,
        'snapshot_hash': snapshotHash,
        'payload': payload,
      };
}

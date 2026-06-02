abstract final class ProtocolResultCodes {
  static const errProtocolIncompatible = 'ERR_PROTOCOL_INCOMPATIBLE';

  static const errReplayProtocolIncompatible =
      'ERR_REPLAY_PROTOCOL_INCOMPATIBLE';
  static const errReplaySnapshotProtocolIncompatible =
      'ERR_REPLAY_SNAPSHOT_PROTOCOL_INCOMPATIBLE';
  static const errReplaySnapshotProtocolMismatch =
      'ERR_REPLAY_SNAPSHOT_PROTOCOL_MISMATCH';
  static const errReplaySnapshotSchemaUnsupported =
      'ERR_REPLAY_SNAPSHOT_SCHEMA_UNSUPPORTED';
  static const errReplayEventProtocolIncompatible =
      'ERR_REPLAY_EVENT_PROTOCOL_INCOMPATIBLE';
  static const errReplayEventProtocolMismatch =
      'ERR_REPLAY_EVENT_PROTOCOL_MISMATCH';
  static const errReplayEventSchemaUnsupported =
      'ERR_REPLAY_EVENT_SCHEMA_UNSUPPORTED';

  static const errRecoveryProtocolIncompatible =
      'ERR_RECOVERY_PROTOCOL_INCOMPATIBLE';
  static const errSnapshotProtocolIncompatible =
      'ERR_SNAPSHOT_PROTOCOL_INCOMPATIBLE';
  static const errSnapshotProtocolMismatch = 'ERR_SNAPSHOT_PROTOCOL_MISMATCH';
  static const errSnapshotSchemaUnsupported = 'ERR_SNAPSHOT_SCHEMA_UNSUPPORTED';
  static const errEventProtocolIncompatible = 'ERR_EVENT_PROTOCOL_INCOMPATIBLE';
  static const errEventProtocolMismatch = 'ERR_EVENT_PROTOCOL_MISMATCH';
  static const errEventSchemaUnsupported = 'ERR_EVENT_SCHEMA_UNSUPPORTED';

  static const all = <String>[
    errProtocolIncompatible,
    errReplayProtocolIncompatible,
    errReplaySnapshotProtocolIncompatible,
    errReplaySnapshotProtocolMismatch,
    errReplaySnapshotSchemaUnsupported,
    errReplayEventProtocolIncompatible,
    errReplayEventProtocolMismatch,
    errReplayEventSchemaUnsupported,
    errRecoveryProtocolIncompatible,
    errSnapshotProtocolIncompatible,
    errSnapshotProtocolMismatch,
    errSnapshotSchemaUnsupported,
    errEventProtocolIncompatible,
    errEventProtocolMismatch,
    errEventSchemaUnsupported,
  ];
}

import 'command_envelope.dart';
import 'event_envelope.dart';
import 'protocol_result_codes.dart';
import 'protocol_version.dart';
import 'result_code.dart';
import 'snapshot_envelope.dart';

enum ProtocolArtifactKind {
  command,
  event,
  snapshot,
  gameFile,
  invitePayload,
  resultCode,
}

class ProtocolCatalogEntry {
  const ProtocolCatalogEntry({
    required this.kind,
    required this.type,
    required this.artifactVersion,
    required this.protocolVersion,
  });

  final ProtocolArtifactKind kind;
  final String type;
  final String artifactVersion;
  final ProtocolVersion protocolVersion;

  String get key {
    return [
      kind.name,
      type,
      artifactVersion,
      protocolVersion.toWire(),
    ].join('|');
  }
}

class ProtocolCatalogLockReport {
  const ProtocolCatalogLockReport({required this.errors});

  final List<String> errors;

  bool get isLocked => errors.isEmpty;
}

class ProtocolCompatibilityResult {
  const ProtocolCompatibilityResult._({
    required this.resultCode,
    required this.isSupported,
    this.entry,
  });

  const ProtocolCompatibilityResult.supported(ProtocolCatalogEntry entry)
    : this._(
        resultCode: ResultCode.okAccepted,
        isSupported: true,
        entry: entry,
      );

  const ProtocolCompatibilityResult.unsupportedVersion()
    : this._(
        resultCode: ResultCode.errProtocolIncompatible,
        isSupported: false,
      );

  const ProtocolCompatibilityResult.unsupportedArtifact()
    : this._(resultCode: ResultCode.errSchemaInvalid, isSupported: false);

  final ResultCode resultCode;
  final bool isSupported;
  final ProtocolCatalogEntry? entry;
}

class ProtocolCatalog {
  const ProtocolCatalog({
    this.supportedProtocolVersion = currentProtocolVersion,
    this.entries = defaultProtocolCatalogEntries,
  });

  final ProtocolVersion supportedProtocolVersion;
  final List<ProtocolCatalogEntry> entries;

  Iterable<ProtocolCatalogEntry> entriesFor(ProtocolArtifactKind kind) {
    return entries.where((entry) => entry.kind == kind);
  }

  List<String> supportedTypesFor(ProtocolArtifactKind kind) {
    return [for (final entry in entriesFor(kind)) entry.type];
  }

  ProtocolCatalogLockReport validateLock({
    Iterable<ProtocolArtifactKind>? requiredKinds,
  }) {
    final errors = <String>[];
    final seen = <String>{};
    final required = requiredKinds ?? ProtocolArtifactKind.values;

    void addError(String error) {
      if (!errors.contains(error)) {
        errors.add(error);
      }
    }

    for (final entry in entries) {
      if (entry.type.isEmpty) {
        addError('ERR_PROTOCOL_CATALOG_EMPTY_TYPE');
      }
      if (entry.artifactVersion.isEmpty) {
        addError('ERR_PROTOCOL_CATALOG_EMPTY_ARTIFACT_VERSION');
      }
      if (entry.protocolVersion != supportedProtocolVersion) {
        addError('ERR_PROTOCOL_CATALOG_PROTOCOL_VERSION_MISMATCH');
      }
      if (!seen.add(entry.key)) {
        addError('ERR_PROTOCOL_CATALOG_DUPLICATE_ENTRY:${entry.key}');
      }
    }

    for (final kind in required) {
      if (!entries.any((entry) => entry.kind == kind)) {
        addError('ERR_PROTOCOL_CATALOG_MISSING_KIND:${kind.name}');
      }
    }

    return ProtocolCatalogLockReport(errors: List<String>.unmodifiable(errors));
  }

  bool supportsProtocolVersion(String wireVersion) {
    final parsed = _tryParseProtocolVersion(wireVersion);
    return parsed != null && parsed == supportedProtocolVersion;
  }

  ProtocolCompatibilityResult check({
    required ProtocolArtifactKind kind,
    required String type,
    required String artifactVersion,
    required String protocolVersion,
  }) {
    if (!supportsProtocolVersion(protocolVersion)) {
      return const ProtocolCompatibilityResult.unsupportedVersion();
    }

    for (final entry in entries) {
      if (entry.kind == kind &&
          entry.type == type &&
          entry.artifactVersion == artifactVersion &&
          entry.protocolVersion.toWire() == protocolVersion) {
        return ProtocolCompatibilityResult.supported(entry);
      }
    }

    return const ProtocolCompatibilityResult.unsupportedArtifact();
  }

  ProtocolCompatibilityResult checkCommandEnvelopeJson(
    Map<String, Object?> envelope,
  ) {
    final commandType = envelope['command_type'];
    final commandVersion = envelope['command_version'];
    final protocolVersion = envelope['protocol_version'];

    if (commandType is! String ||
        commandVersion is! String ||
        protocolVersion is! String) {
      return const ProtocolCompatibilityResult.unsupportedArtifact();
    }

    return check(
      kind: ProtocolArtifactKind.command,
      type: commandType,
      artifactVersion: commandVersion,
      protocolVersion: protocolVersion,
    );
  }

  ProtocolCompatibilityResult checkCommandEnvelope(CommandEnvelope envelope) {
    return check(
      kind: ProtocolArtifactKind.command,
      type: envelope.commandType,
      artifactVersion: envelope.commandVersion,
      protocolVersion: envelope.protocolVersion,
    );
  }

  ProtocolCompatibilityResult checkEventEnvelopeJson(
    Map<String, Object?> envelope,
  ) {
    final eventType = envelope['event_type'];
    final eventVersion = envelope['event_version'];
    final protocolVersion = envelope['protocol_version'];

    if (eventType is! String ||
        eventVersion is! String ||
        protocolVersion is! String) {
      return const ProtocolCompatibilityResult.unsupportedArtifact();
    }

    return check(
      kind: ProtocolArtifactKind.event,
      type: eventType,
      artifactVersion: eventVersion,
      protocolVersion: protocolVersion,
    );
  }

  ProtocolCompatibilityResult checkEventEnvelope(EventEnvelope envelope) {
    return check(
      kind: ProtocolArtifactKind.event,
      type: envelope.eventType,
      artifactVersion: envelope.eventVersion,
      protocolVersion: envelope.protocolVersion,
    );
  }

  ProtocolCompatibilityResult checkSnapshotEnvelopeJson(
    Map<String, Object?> envelope,
  ) {
    final snapshotType = envelope['snapshot_type'];
    final snapshotVersion = envelope['snapshot_version'];
    final protocolVersion = envelope['protocol_version'];

    if (snapshotType is! String ||
        snapshotVersion is! String ||
        protocolVersion is! String) {
      return const ProtocolCompatibilityResult.unsupportedArtifact();
    }

    return check(
      kind: ProtocolArtifactKind.snapshot,
      type: snapshotType,
      artifactVersion: snapshotVersion,
      protocolVersion: protocolVersion,
    );
  }

  ProtocolCompatibilityResult checkSnapshotEnvelope(SnapshotEnvelope envelope) {
    return check(
      kind: ProtocolArtifactKind.snapshot,
      type: envelope.snapshotType,
      artifactVersion: envelope.snapshotVersion,
      protocolVersion: envelope.protocolVersion,
    );
  }

  ProtocolCompatibilityResult checkGameFileJson(Map<String, Object?> gameFile) {
    final schemaId = gameFile['schema_id'];
    final gameFileVersion = gameFile['game_file_version'];
    final protocolVersion = gameFile['protocol_version'];

    if (schemaId is! String ||
        gameFileVersion is! String ||
        protocolVersion is! String) {
      return const ProtocolCompatibilityResult.unsupportedArtifact();
    }

    return check(
      kind: ProtocolArtifactKind.gameFile,
      type: schemaId,
      artifactVersion: gameFileVersion,
      protocolVersion: protocolVersion,
    );
  }

  ProtocolCompatibilityResult checkInvitePayloadJson(
    Map<String, Object?> invitePayload,
  ) {
    final inviteVersion = invitePayload['invite_version'];
    final protocolVersion = invitePayload['protocol_version'];

    if (inviteVersion is! String || protocolVersion is! String) {
      return const ProtocolCompatibilityResult.unsupportedArtifact();
    }

    return check(
      kind: ProtocolArtifactKind.invitePayload,
      type: invitePayloadCatalogType,
      artifactVersion: inviteVersion,
      protocolVersion: protocolVersion,
    );
  }

  ProtocolCompatibilityResult checkResultCode(String code) {
    return check(
      kind: ProtocolArtifactKind.resultCode,
      type: code,
      artifactVersion: resultCodeCatalogVersion,
      protocolVersion: supportedProtocolVersion.toWire(),
    );
  }

  ProtocolVersion? _tryParseProtocolVersion(String wireVersion) {
    try {
      return ProtocolVersion.parse(wireVersion);
    } on FormatException {
      return null;
    }
  }
}

const currentProtocolVersion = ProtocolVersion(1, 0, 0);
const gameFileCatalogType = 'peerdeal.gamefile';
const invitePayloadCatalogType = 'InvitePayload';
const resultCodeCatalogVersion = '1.0';

const supportedCommandCatalogEntries = [
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'OpenTableSession',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'StartHand',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'PlayerFold',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'PlayerCheck',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'PlayerCall',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'PlayerBet',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'PlayerRaise',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'PlayerAllIn',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.command,
    type: 'RequestSessionClose',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
];

const supportedEventCatalogEntries = [
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'OpenTableSessionOpened',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'ParticipantAdmitted',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'ParticipantConnected',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'ParticipantSeated',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'HandStarted',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'PlayerFolded',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'PlayerChecked',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'PlayerCalled',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'PlayerBet',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'PlayerRaised',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'PlayerAllIn',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'ShowdownStarted',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'ShowdownRevealed',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'SettlementProjected',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'SettlementBlocked',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'HandSettled',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'SessionCloseRequested',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'SessionClosed',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'SessionWiped',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'IgnoredBecauseCoveredBySnapshot',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.event,
    type: 'RecoveryPauseEnded',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
];

const supportedSnapshotCatalogEntries = [
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.snapshot,
    type: 'TableSnapshot',
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
];

const supportedGameFileCatalogEntries = [
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.gameFile,
    type: gameFileCatalogType,
    artifactVersion: '1.0.0',
    protocolVersion: currentProtocolVersion,
  ),
];

const supportedInvitePayloadCatalogEntries = [
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.invitePayload,
    type: invitePayloadCatalogType,
    artifactVersion: '1.0',
    protocolVersion: currentProtocolVersion,
  ),
];

const supportedResultCodeCatalogEntries = [
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errProtocolIncompatible,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errReplayProtocolIncompatible,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errReplaySnapshotProtocolIncompatible,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errReplaySnapshotProtocolMismatch,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errReplaySnapshotSchemaUnsupported,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errReplayEventProtocolIncompatible,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errReplayEventProtocolMismatch,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errReplayEventSchemaUnsupported,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errRecoveryProtocolIncompatible,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errSnapshotProtocolIncompatible,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errSnapshotProtocolMismatch,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errSnapshotSchemaUnsupported,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errEventProtocolIncompatible,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errEventProtocolMismatch,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
  ProtocolCatalogEntry(
    kind: ProtocolArtifactKind.resultCode,
    type: ProtocolResultCodes.errEventSchemaUnsupported,
    artifactVersion: resultCodeCatalogVersion,
    protocolVersion: currentProtocolVersion,
  ),
];

const defaultProtocolCatalogEntries = [
  ...supportedCommandCatalogEntries,
  ...supportedEventCatalogEntries,
  ...supportedSnapshotCatalogEntries,
  ...supportedGameFileCatalogEntries,
  ...supportedInvitePayloadCatalogEntries,
  ...supportedResultCodeCatalogEntries,
];

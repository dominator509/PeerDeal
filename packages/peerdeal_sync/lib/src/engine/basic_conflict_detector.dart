import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/conflict_detector.dart';
import '../models/conflict_detection_result.dart';
import '../models/recovery_event_window_limits.dart';
import '../models/recovery_persistence_scope.dart';
import '../models/recovery_request.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';

class BasicConflictDetector implements ConflictDetector {
  const BasicConflictDetector({
    this.protocolCatalog = const ProtocolCatalog(),
    this.maxEvents = RecoveryEventWindowLimits.defaultMaxEvents,
    this.eventCodec = const EventEnvelopeCodec(
      maxBytes: RecoveryEventWindowLimits.defaultMaxEventBytes,
    ),
    this.snapshotLimits = const CanonicalJsonLimits(
      maxEncodedBytes: RecoveryEventWindowLimits.defaultMaxSnapshotBytes,
    ),
  }) : assert(maxEvents > 0, 'maxEvents must be positive');

  final ProtocolCatalog protocolCatalog;
  final int maxEvents;
  final EventEnvelopeCodec eventCodec;
  final CanonicalJsonLimits snapshotLimits;

  @override
  ConflictDetectionResult detect(RecoveryRequest request) {
    final conflicts = <SyncConflict>[];

    if (!RecoveryPersistenceScope(
      tableId: request.tableId,
      sessionId: request.sessionId,
      protocolVersion: request.protocolVersion,
    ).hasValidStorageIdentity) {
      return const ConflictDetectionResult(
        conflicts: <SyncConflict>[
          SyncConflict(
            code: 'ERR_RECOVERY_SCOPE_INVALID',
            message: 'Recovery request scope identity is invalid.',
            severity: SyncConflictSeverity.fatal,
          ),
        ],
      );
    }

    if (request.events.length > maxEvents) {
      return ConflictDetectionResult(
        conflicts: <SyncConflict>[
          SyncConflict(
            code: 'ERR_RECOVERY_EVENT_COUNT_TOO_LARGE',
            message: 'Recovery event window exceeds the configured limit.',
            severity: SyncConflictSeverity.fatal,
            expected: '$maxEvents',
            actual: '${request.events.length}',
          ),
        ],
      );
    }

    if (request.snapshot != null) {
      final snapshotEncodingConflict = _snapshotEncodingConflict(
        request.snapshot!,
      );
      if (snapshotEncodingConflict != null) {
        return ConflictDetectionResult(
          conflicts: <SyncConflict>[snapshotEncodingConflict],
        );
      }
    }

    for (final event in request.events) {
      final eventEncodingConflict = _eventEncodingConflict(event);
      if (eventEncodingConflict != null) {
        return ConflictDetectionResult(
          conflicts: <SyncConflict>[eventEncodingConflict],
        );
      }
    }

    if (!protocolCatalog.supportsProtocolVersion(request.protocolVersion)) {
      conflicts.add(
        SyncConflict(
          code: ProtocolResultCodes.errRecoveryProtocolIncompatible,
          message: 'Recovery request protocol version is not supported.',
          severity: SyncConflictSeverity.fatal,
          expected: currentProtocolVersion.toWire(),
          actual: request.protocolVersion,
        ),
      );
      return ConflictDetectionResult(conflicts: conflicts);
    }

    if (request.snapshot != null) {
      final snapshot = request.snapshot!;
      final snapshotCompatibility = protocolCatalog.checkSnapshotEnvelope(
        snapshot,
      );
      if (snapshotCompatibility.resultCode ==
          ResultCode.errProtocolIncompatible) {
        conflicts.add(
          SyncConflict(
            code: ProtocolResultCodes.errSnapshotProtocolIncompatible,
            message: 'Recovery snapshot protocol version is not supported.',
            severity: SyncConflictSeverity.fatal,
            expected: currentProtocolVersion.toWire(),
            actual: snapshot.protocolVersion,
          ),
        );
      } else if (snapshot.protocolVersion != request.protocolVersion) {
        conflicts.add(
          SyncConflict(
            code: ProtocolResultCodes.errSnapshotProtocolMismatch,
            message:
                'Snapshot protocol version does not match the recovery request.',
            severity: SyncConflictSeverity.fatal,
            expected: request.protocolVersion,
            actual: snapshot.protocolVersion,
          ),
        );
      } else if (!snapshotCompatibility.isSupported) {
        conflicts.add(
          SyncConflict(
            code: ProtocolResultCodes.errSnapshotSchemaUnsupported,
            message:
                'Recovery snapshot artifact is not supported by the protocol catalog.',
            severity: SyncConflictSeverity.fatal,
            expected: 'supported snapshot artifact',
            actual: '${snapshot.snapshotType}@${snapshot.snapshotVersion}',
          ),
        );
      }

      if (snapshot.tableId != request.tableId ||
          snapshot.sessionId != request.sessionId) {
        conflicts.add(
          const SyncConflict(
            code: 'ERR_SNAPSHOT_SCOPE_MISMATCH',
            message:
                'Snapshot table/session scope does not match the recovery request.',
            severity: SyncConflictSeverity.fatal,
          ),
        );
      }
    }

    for (final event in request.events) {
      if (event.tableId != request.tableId ||
          event.sessionId != request.sessionId) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_EVENT_SCOPE_MISMATCH',
            message:
                'Recovery event table/session scope does not match the recovery request.',
            severity: SyncConflictSeverity.fatal,
            expected: '${request.tableId}/${request.sessionId}',
            actual: '${event.tableId}/${event.sessionId}',
          ),
        );
      }

      final eventCompatibility = protocolCatalog.checkEventEnvelope(event);
      if (eventCompatibility.resultCode == ResultCode.errProtocolIncompatible) {
        conflicts.add(
          SyncConflict(
            code: ProtocolResultCodes.errEventProtocolIncompatible,
            message: 'Recovery event protocol version is not supported.',
            severity: SyncConflictSeverity.fatal,
            expected: currentProtocolVersion.toWire(),
            actual: event.protocolVersion,
          ),
        );
      } else if (event.protocolVersion != request.protocolVersion) {
        conflicts.add(
          SyncConflict(
            code: ProtocolResultCodes.errEventProtocolMismatch,
            message:
                'Recovery event protocol version does not match the request.',
            severity: SyncConflictSeverity.fatal,
            expected: request.protocolVersion,
            actual: event.protocolVersion,
          ),
        );
      } else if (!eventCompatibility.isSupported) {
        conflicts.add(
          SyncConflict(
            code: ProtocolResultCodes.errEventSchemaUnsupported,
            message:
                'Recovery event artifact is not supported by the protocol catalog.',
            severity: SyncConflictSeverity.fatal,
            expected: 'supported event artifact',
            actual: '${event.eventType}@${event.eventVersion}',
          ),
        );
      }
    }

    for (var i = 1; i < request.events.length; i++) {
      final previous = request.events[i - 1];
      final current = request.events[i];
      if (current.eventSeq <= previous.eventSeq) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_EVENT_SEQUENCE_NON_MONOTONIC',
            message: 'Recovery event window is not strictly monotonic.',
            severity: SyncConflictSeverity.fatal,
            expected: '>${previous.eventSeq}',
            actual: '${current.eventSeq}',
          ),
        );
      } else if (current.eventSeq != previous.eventSeq + 1) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_EVENT_SEQUENCE_GAP',
            message: 'Recovery event sequence gap detected.',
            severity: SyncConflictSeverity.fatal,
            expected: '${previous.eventSeq + 1}',
            actual: '${current.eventSeq}',
          ),
        );
      }
      if (current.prevEventHash != previous.eventHash) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_EVENT_HASH_CHAIN_BREAK',
            message: 'Recovery event hash chain continuity failed.',
            severity: SyncConflictSeverity.fatal,
            expected: previous.eventHash,
            actual: current.prevEventHash,
          ),
        );
      }
    }

    if (request.snapshot != null && request.events.isNotEmpty) {
      final firstEventSeq = request.events.first.eventSeq;
      final snapshotBaseEventSeq = request.snapshot!.snapshotBaseEventSeq;
      if (firstEventSeq <= snapshotBaseEventSeq) {
        conflicts.add(
          SyncConflict(
            code: 'WARN_EVENT_WINDOW_OVERLAPS_SNAPSHOT',
            message:
                'Recovery event window overlaps the snapshot base sequence and will be filtered.',
            severity: SyncConflictSeverity.recoverable,
            expected: '>$snapshotBaseEventSeq',
            actual: '$firstEventSeq',
          ),
        );
      } else if (firstEventSeq != snapshotBaseEventSeq + 1) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_SNAPSHOT_SUFFIX_GAP',
            message:
                'Recovery event window does not continue from the snapshot base sequence.',
            severity: SyncConflictSeverity.fatal,
            expected: '${snapshotBaseEventSeq + 1}',
            actual: '$firstEventSeq',
          ),
        );
      }
    }

    if (request.snapshot == null && request.events.isNotEmpty) {
      final firstEventSeq = request.events.first.eventSeq;
      if (firstEventSeq != 1) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_EVENT_WINDOW_MISSING_PREFIX',
            message:
                'Recovery event window without a snapshot must start at the first event.',
            severity: SyncConflictSeverity.fatal,
            expected: '1',
            actual: '$firstEventSeq',
          ),
        );
      }
      final firstPrevEventHash = request.events.first.prevEventHash;
      if (firstPrevEventHash != genesisEventHash) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_EVENT_WINDOW_GENESIS_HASH_MISMATCH',
            message:
                'Recovery event window without a snapshot must chain from the genesis event hash.',
            severity: SyncConflictSeverity.fatal,
            expected: genesisEventHash,
            actual: firstPrevEventHash,
          ),
        );
      }
    }

    if (request.expectedFinalEventSeq != null && request.events.isNotEmpty) {
      final actualFinalSeq = request.events.last.eventSeq;
      if (actualFinalSeq != request.expectedFinalEventSeq) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_FINAL_EVENT_SEQ_MISMATCH',
            message:
                'Final event sequence does not match expected recovery baseline.',
            severity: SyncConflictSeverity.recoverable,
            expected: '${request.expectedFinalEventSeq}',
            actual: '$actualFinalSeq',
          ),
        );
      }
    }

    if (request.expectedFinalEventHash != null && request.events.isNotEmpty) {
      final actualFinalHash = request.events.last.eventHash;
      if (actualFinalHash != request.expectedFinalEventHash) {
        conflicts.add(
          SyncConflict(
            code: 'ERR_FINAL_EVENT_HASH_MISMATCH',
            message:
                'Final event hash does not match expected recovery baseline.',
            severity: SyncConflictSeverity.fatal,
            expected: request.expectedFinalEventHash,
            actual: actualFinalHash,
          ),
        );
      }
    }

    if (request.snapshot == null && request.events.isEmpty) {
      conflicts.add(
        const SyncConflict(
          code: 'ERR_EMPTY_RECOVERY_WINDOW',
          message: 'Recovery request has no snapshot and no events to apply.',
          severity: SyncConflictSeverity.fatal,
        ),
      );
    }

    return ConflictDetectionResult(conflicts: conflicts);
  }

  SyncConflict? _eventEncodingConflict(EventEnvelope event) {
    try {
      eventCodec.encode(event);
      return null;
    } on FormatException catch (error) {
      final isTooLarge =
          error.message == 'Event envelope wire payload is too large.';
      return SyncConflict(
        code: isTooLarge
            ? 'ERR_RECOVERY_EVENT_TOO_LARGE'
            : 'ERR_RECOVERY_EVENT_INVALID',
        message: isTooLarge
            ? 'Recovery event exceeds the configured wire-size limit.'
            : 'Recovery event could not be encoded as a protocol envelope.',
        severity: SyncConflictSeverity.fatal,
        expected: isTooLarge ? '${eventCodec.maxBytes}' : null,
      );
    }
  }

  SyncConflict? _snapshotEncodingConflict(SnapshotEnvelope snapshot) {
    try {
      canonicalJsonEncode(snapshot.toJson(), limits: snapshotLimits);
      return null;
    } on FormatException catch (error) {
      final isTooLarge =
          error.message == 'Canonical JSON payload is too large.';
      return SyncConflict(
        code: isTooLarge
            ? 'ERR_RECOVERY_SNAPSHOT_TOO_LARGE'
            : 'ERR_RECOVERY_SNAPSHOT_INVALID',
        message: isTooLarge
            ? 'Recovery snapshot exceeds the configured canonical limit.'
            : 'Recovery snapshot could not be encoded as canonical protocol JSON.',
        severity: SyncConflictSeverity.fatal,
        expected: isTooLarge ? '${snapshotLimits.maxEncodedBytes}' : null,
      );
    }
  }
}

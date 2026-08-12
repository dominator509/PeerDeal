import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

/// Writes one canonical typed Hold'em state snapshot to app-owned recovery.
///
/// Product state selection and event-log policy remain caller-owned. The
/// writer only validates the supplied state/cursor relationship, constructs a
/// hashed protocol envelope, and delegates persistence to the existing store.
class AppHoldemProductionSessionSnapshotWriter {
  const AppHoldemProductionSessionSnapshotWriter({
    required RecoveryPersistenceStore store,
  }) : _store = store;

  final RecoveryPersistenceStore _store;

  /// Validates all snapshot inputs without touching persistence.
  ///
  /// Combined event-and-snapshot writes use this as a preflight so malformed
  /// checkpoint input cannot leave a durable event suffix behind.
  RecoveryPersistenceResult? validate({
    required String snapshotId,
    required TableState tableState,
    required HoldemHandState handState,
    required HoldemEventCursor eventCursor,
    String snapshotType = 'HoldemStateSnapshot',
    String snapshotVersion = '1.0',
  }) {
    final identityFailure = _validateIdentity(
      snapshotId,
      warning: 'Holdem snapshot identity is invalid.',
    );
    if (identityFailure != null) return identityFailure;
    final typeFailure = _validateIdentity(
      snapshotType,
      warning: 'Holdem snapshot type is invalid.',
    );
    if (typeFailure != null) return typeFailure;
    final versionFailure = _validateIdentity(
      snapshotVersion,
      warning: 'Holdem snapshot version is invalid.',
    );
    if (versionFailure != null) return versionFailure;

    final scope = RecoveryPersistenceScope(
      tableId: tableState.tableId,
      sessionId: tableState.sessionId,
      protocolVersion: tableState.protocolVersion,
    );
    if (!scope.hasValidStorageIdentity) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot persistence scope is invalid.'],
      );
    }
    if (eventCursor.tableId != tableState.tableId ||
        eventCursor.sessionId != tableState.sessionId ||
        eventCursor.protocolVersion != tableState.protocolVersion) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot state and cursor scope differ.'],
      );
    }

    final snapshotBaseEventSeq = eventCursor.nextEventSeq - 1;
    if (snapshotBaseEventSeq < 0 ||
        tableState.eventSequence != snapshotBaseEventSeq) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot state and cursor sequence differ.'],
      );
    }
    final lastEventHash = tableState.metadata['last_event_hash'];
    if (lastEventHash != null &&
        (lastEventHash is! String ||
            lastEventHash != eventCursor.previousEventHash)) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot event hash is inconsistent.'],
      );
    }

    try {
      final typedSnapshot = HoldemStateSnapshot(
        tableState: tableState,
        handState: handState,
        eventCursor: eventCursor,
      );
      canonicalJsonEncode(typedSnapshot.toJson());
    } on Object {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot serialization is invalid.'],
      );
    }
    return null;
  }

  RecoveryPersistenceResult save({
    required String snapshotId,
    required TableState tableState,
    required HoldemHandState handState,
    required HoldemEventCursor eventCursor,
    String snapshotType = 'HoldemStateSnapshot',
    String snapshotVersion = '1.0',
  }) {
    final validation = validate(
      snapshotId: snapshotId,
      tableState: tableState,
      handState: handState,
      eventCursor: eventCursor,
      snapshotType: snapshotType,
      snapshotVersion: snapshotVersion,
    );
    if (validation != null) return validation;

    final scope = RecoveryPersistenceScope(
      tableId: tableState.tableId,
      sessionId: tableState.sessionId,
      protocolVersion: tableState.protocolVersion,
    );
    if (!scope.hasValidStorageIdentity) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot persistence scope is invalid.'],
      );
    }
    final snapshotBaseEventSeq = eventCursor.nextEventSeq - 1;

    final SnapshotEnvelope envelope;
    try {
      final typedSnapshot = HoldemStateSnapshot(
        tableState: tableState,
        handState: handState,
        eventCursor: eventCursor,
      );
      final payload = typedSnapshot.toJson();
      envelope = SnapshotEnvelope(
        snapshotId: snapshotId,
        snapshotType: snapshotType,
        snapshotVersion: snapshotVersion,
        protocolVersion: tableState.protocolVersion,
        tableId: tableState.tableId,
        sessionId: tableState.sessionId,
        snapshotBaseEventSeq: snapshotBaseEventSeq,
        snapshotHash: computeCanonicalHash(payload),
        payload: payload,
      );
    } on Object {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot serialization is unavailable.'],
      );
    }

    try {
      return _store.saveSnapshot(scope: scope, snapshot: envelope);
    } on Object {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot persistence is unavailable.'],
      );
    }
  }

  RecoveryPersistenceResult? _validateIdentity(
    String value, {
    required String warning,
  }) {
    if (value.isEmpty ||
        value.trim() != value ||
        RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>[warning],
      );
    }
    return null;
  }
}

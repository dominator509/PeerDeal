import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import 'app_holdem_production_session_snapshot_writer.dart';

/// Persists one accepted Hold'em event suffix and its resulting typed snapshot.
///
/// The caller owns state selection, event identity, snapshot identity, and
/// retention policy. Events are appended before the snapshot so recovery can
/// replay a durable suffix when the checkpoint write fails.
class AppHoldemProductionSessionPersistenceWriter {
  AppHoldemProductionSessionPersistenceWriter({
    required RecoveryPersistenceStore store,
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  }) : _store = store,
       _snapshotWriter = AppHoldemProductionSessionSnapshotWriter(store: store),
       _maxRecoveryEvents = _validateMaxRecoveryEvents(maxRecoveryEvents);

  final RecoveryPersistenceStore _store;
  final AppHoldemProductionSessionSnapshotWriter _snapshotWriter;
  final int _maxRecoveryEvents;

  RecoveryPersistenceResult persist({
    required String snapshotId,
    required TableState tableState,
    required HoldemHandState handState,
    required HoldemEventCursor eventCursor,
    List<EventEnvelope> events = const <EventEnvelope>[],
    String snapshotType = 'HoldemStateSnapshot',
    String snapshotVersion = '1.0',
  }) {
    final validation = _validateEvents(
      tableState: tableState,
      eventCursor: eventCursor,
      events: events,
    );
    if (validation != null) return validation;
    final snapshotValidation = _snapshotWriter.validate(
      snapshotId: snapshotId,
      tableState: tableState,
      handState: handState,
      eventCursor: eventCursor,
      snapshotType: snapshotType,
      snapshotVersion: snapshotVersion,
    );
    if (snapshotValidation != null) return snapshotValidation;

    RecoveryPersistenceResult eventResult =
        const RecoveryPersistenceResult.success();
    if (events.isNotEmpty) {
      final scope = RecoveryPersistenceScope(
        tableId: tableState.tableId,
        sessionId: tableState.sessionId,
        protocolVersion: tableState.protocolVersion,
      );
      try {
        eventResult = _store.appendEvents(scope: scope, events: events);
      } on Object {
        return const RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>['Holdem event-log persistence is unavailable.'],
        );
      }
      if (!eventResult.isSuccess) return eventResult;
    }

    final snapshotResult = _snapshotWriter.save(
      snapshotId: snapshotId,
      tableState: tableState,
      handState: handState,
      eventCursor: eventCursor,
      snapshotType: snapshotType,
      snapshotVersion: snapshotVersion,
    );
    final extraWarnings = <String>[
      ...eventResult.warnings,
      if (events.isNotEmpty && !snapshotResult.isSuccess)
        'Holdem snapshot checkpoint failed after event-log persistence.',
    ];
    if (extraWarnings.isEmpty) return snapshotResult;
    return RecoveryPersistenceResult(
      isSuccess: snapshotResult.isSuccess,
      conflicts: snapshotResult.conflicts,
      warnings: <String>[...extraWarnings, ...snapshotResult.warnings],
    );
  }

  RecoveryPersistenceResult? _validateEvents({
    required TableState tableState,
    required HoldemEventCursor eventCursor,
    required List<EventEnvelope> events,
  }) {
    if (events.isEmpty) return null;
    if (events.length > _maxRecoveryEvents) {
      return const RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>[
          'Holdem event-log suffix exceeds the configured recovery event limit.',
        ],
      );
    }

    EventEnvelope? previous;
    for (final event in events) {
      if (event.eventType == 'SessionClosed' ||
          event.eventType == 'SessionWiped') {
        return const RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>[
            'Holdem retention events require the close-retention adapter.',
          ],
        );
      }
      if (event.tableId != tableState.tableId ||
          event.sessionId != tableState.sessionId ||
          event.protocolVersion != tableState.protocolVersion) {
        return const RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>['Holdem event-log scope does not match state.'],
        );
      }
      if (previous != null &&
          (event.eventSeq != previous.eventSeq + 1 ||
              event.prevEventHash != previous.eventHash)) {
        return const RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>['Holdem event-log suffix is not contiguous.'],
        );
      }
      previous = event;
    }

    final lastEvent = events.last;
    if (lastEvent.eventSeq != tableState.eventSequence ||
        eventCursor.nextEventSeq != lastEvent.eventSeq + 1 ||
        eventCursor.previousEventHash != lastEvent.eventHash) {
      return const RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>[
          'Holdem event-log suffix does not match resulting state.',
        ],
      );
    }
    final lastEventHash = tableState.metadata['last_event_hash'];
    if (lastEventHash != null &&
        (lastEventHash is! String || lastEventHash != lastEvent.eventHash)) {
      return const RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem event-log state hash is inconsistent.'],
      );
    }
    return null;
  }
}

int _validateMaxRecoveryEvents(int value) {
  if (value <= 0) {
    throw ArgumentError.value(
      value,
      'maxRecoveryEvents',
      'Recovery event limit must be positive.',
    );
  }
  return value;
}

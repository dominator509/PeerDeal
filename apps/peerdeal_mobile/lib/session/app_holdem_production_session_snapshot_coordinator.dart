import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import 'app_holdem_production_session_persistence_writer.dart';

typedef AppHoldemProductionSnapshotIdFactory =
    String Function(TableState tableState, HoldemEventCursor eventCursor);

/// Serializes typed production snapshots without taking ownership of state.
///
/// Checkpoints are ordered per mounted route. A failed checkpoint is retained
/// and retried before a newer checkpoint, so an intermittent store failure
/// cannot silently discard the last durable state. Event-log policy remains
/// caller-owned by [AppHoldemProductionSessionPersistenceWriter].
class AppHoldemProductionSessionSnapshotCoordinator {
  static const int defaultMaxPendingCheckpoints = 64;

  AppHoldemProductionSessionSnapshotCoordinator({
    required AppHoldemProductionSessionPersistenceWriter persistenceWriter,
    AppHoldemProductionSnapshotIdFactory? snapshotIdFactory,
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
    int maxPendingCheckpoints = defaultMaxPendingCheckpoints,
  }) : _persistenceWriter = persistenceWriter,
       _snapshotIdFactory = snapshotIdFactory ?? _defaultSnapshotId,
       _maxRecoveryEvents = _validateMaxRecoveryEvents(maxRecoveryEvents),
       _maxPendingCheckpoints = _validateMaxPendingCheckpoints(
         maxPendingCheckpoints,
       );

  final AppHoldemProductionSessionPersistenceWriter _persistenceWriter;
  final AppHoldemProductionSnapshotIdFactory _snapshotIdFactory;
  final int _maxRecoveryEvents;
  final int _maxPendingCheckpoints;
  Future<void> _tail = Future<void>.value();
  final List<_SnapshotCheckpoint> _pending = <_SnapshotCheckpoint>[];
  RecoveryPersistenceResult? _lastResult;

  bool get hasPending => _pending.isNotEmpty;
  RecoveryPersistenceResult? get lastResult => _lastResult;

  Future<RecoveryPersistenceResult> persist({
    required TableState tableState,
    required HoldemHandState handState,
    required HoldemEventCursor eventCursor,
    List<EventEnvelope> events = const <EventEnvelope>[],
  }) {
    if (events.length > _maxRecoveryEvents) {
      return _enqueueOperation(() {
        const result = RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>[
            'Holdem snapshot event suffix exceeds the configured recovery event limit.',
          ],
        );
        _lastResult = result;
        return result;
      });
    }

    final capturedEvents = List<EventEnvelope>.unmodifiable(events);
    return _enqueueOperation(() {
      final String snapshotId;
      try {
        snapshotId = _snapshotIdFactory(tableState, eventCursor);
      } on Object {
        const result = RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>['Holdem snapshot ID could not be created.'],
        );
        _lastResult = result;
        return result;
      }

      return _persistCheckpoint(
        _SnapshotCheckpoint(
          snapshotId: snapshotId,
          tableState: tableState,
          handState: handState,
          eventCursor: eventCursor,
          events: capturedEvents,
        ),
      );
    });
  }

  Future<RecoveryPersistenceResult> retryPending() {
    return _enqueueOperation(() {
      if (_pending.isEmpty) {
        return const RecoveryPersistenceResult.success();
      }
      return _persistCheckpoint(_pending.first);
    });
  }

  /// Clears queued snapshot state after an accepted terminal retention event.
  ///
  /// The clear is serialized behind earlier writes so a late failed write
  /// cannot recreate recovery data after a successful close or wipe.
  Future<void> discardPending() {
    final operation = _tail.then<void>((_) {
      _pending.clear();
      _lastResult = const RecoveryPersistenceResult.success();
    });
    _tail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  Future<RecoveryPersistenceResult> _enqueueOperation(
    RecoveryPersistenceResult Function() operationCallback,
  ) {
    final operation = _tail.then<RecoveryPersistenceResult>(
      (_) => operationCallback(),
    );
    _tail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  RecoveryPersistenceResult _persistCheckpoint(_SnapshotCheckpoint checkpoint) {
    while (_pending.isNotEmpty) {
      final pending = _pending.first;
      final pendingResult = _save(pending);
      _lastResult = pendingResult;
      if (!pendingResult.isSuccess) {
        _pending[0] = pending.copyWith(
          eventsAlreadyPersisted:
              pending.eventsAlreadyPersisted ||
              pendingResult.warnings.contains(
                'Holdem snapshot checkpoint failed after event-log persistence.',
              ),
        );
        if (!identical(pending, checkpoint)) {
          if (_pending.length >= _maxPendingCheckpoints) {
            return _queueFullResult(pendingResult);
          }
          _pending.add(checkpoint);
        }
        return pendingResult;
      }
      _pending.removeAt(0);
      if (identical(pending, checkpoint)) return pendingResult;
    }

    final result = _save(checkpoint);
    _lastResult = result;
    if (!result.isSuccess) {
      if (_pending.length >= _maxPendingCheckpoints) {
        return _queueFullResult(result);
      }
      _pending.add(
        checkpoint.copyWith(
          eventsAlreadyPersisted: result.warnings.contains(
            'Holdem snapshot checkpoint failed after event-log persistence.',
          ),
        ),
      );
    }
    return result;
  }

  RecoveryPersistenceResult _queueFullResult(RecoveryPersistenceResult result) {
    final bounded = RecoveryPersistenceResult(
      isSuccess: false,
      conflicts: result.conflicts,
      warnings: <String>[
        ...result.warnings,
        'Holdem snapshot checkpoint queue is full.',
      ],
    );
    _lastResult = bounded;
    return bounded;
  }

  RecoveryPersistenceResult _save(_SnapshotCheckpoint checkpoint) {
    try {
      return _persistenceWriter.persist(
        snapshotId: checkpoint.snapshotId,
        tableState: checkpoint.tableState,
        handState: checkpoint.handState,
        eventCursor: checkpoint.eventCursor,
        events: checkpoint.events,
        eventsAlreadyPersisted: checkpoint.eventsAlreadyPersisted,
      );
    } on Object {
      return const RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['Holdem snapshot checkpoint is unavailable.'],
      );
    }
  }

  static String _defaultSnapshotId(
    TableState tableState,
    HoldemEventCursor eventCursor,
  ) {
    return 'snapshot_${tableState.sessionId}_${eventCursor.nextEventSeq - 1}';
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

int _validateMaxPendingCheckpoints(int value) {
  if (value <= 0) {
    throw ArgumentError.value(
      value,
      'maxPendingCheckpoints',
      'Pending snapshot checkpoint limit must be positive.',
    );
  }
  return value;
}

class _SnapshotCheckpoint {
  _SnapshotCheckpoint({
    required this.snapshotId,
    required this.tableState,
    required this.handState,
    required this.eventCursor,
    required List<EventEnvelope> events,
    this.eventsAlreadyPersisted = false,
  }) : events = List<EventEnvelope>.unmodifiable(events);

  _SnapshotCheckpoint copyWith({bool? eventsAlreadyPersisted}) {
    return _SnapshotCheckpoint(
      snapshotId: snapshotId,
      tableState: tableState,
      handState: handState,
      eventCursor: eventCursor,
      events: events,
      eventsAlreadyPersisted:
          eventsAlreadyPersisted ?? this.eventsAlreadyPersisted,
    );
  }

  final String snapshotId;
  final TableState tableState;
  final HoldemHandState handState;
  final HoldemEventCursor eventCursor;
  final List<EventEnvelope> events;
  final bool eventsAlreadyPersisted;
}

import 'dart:convert';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import 'app_holdem_production_session_persistence_writer.dart';
import 'app_holdem_production_session_snapshot_writer.dart';

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
  static const int defaultMaxPendingCheckpointBytes =
      RecoveryEventWindowLimits.defaultMaxSnapshotBytes;

  AppHoldemProductionSessionSnapshotCoordinator({
    required AppHoldemProductionSessionPersistenceWriter persistenceWriter,
    AppHoldemProductionSnapshotIdFactory? snapshotIdFactory,
    String snapshotType = 'HoldemStateSnapshot',
    String snapshotVersion = '1.0',
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
    int maxPendingCheckpoints = defaultMaxPendingCheckpoints,
    int maxPendingCheckpointBytes = defaultMaxPendingCheckpointBytes,
  }) : _persistenceWriter = persistenceWriter,
       _snapshotIdFactory = snapshotIdFactory ?? _defaultSnapshotId,
       _snapshotType = snapshotType,
       _snapshotVersion = snapshotVersion,
       _maxRecoveryEvents = _validateMaxRecoveryEvents(maxRecoveryEvents),
       _maxPendingCheckpoints = _validateMaxPendingCheckpoints(
         maxPendingCheckpoints,
       ),
       _maxPendingCheckpointBytes = _validateMaxPendingCheckpointBytes(
         maxPendingCheckpointBytes,
       );

  final AppHoldemProductionSessionPersistenceWriter _persistenceWriter;
  final AppHoldemProductionSnapshotIdFactory _snapshotIdFactory;
  final String _snapshotType;
  final String _snapshotVersion;
  final int _maxRecoveryEvents;
  final int _maxPendingCheckpoints;
  final int _maxPendingCheckpointBytes;
  Future<void> _tail = Future<void>.value();
  final List<_SnapshotCheckpoint> _pending = <_SnapshotCheckpoint>[];
  int _pendingBytes = 0;
  RecoveryPersistenceResult? _lastResult;

  bool get hasPending => _pending.isNotEmpty;
  RecoveryPersistenceResult? get lastResult => _lastResult;

  Future<RecoveryPersistenceResult> persist({
    required TableState tableState,
    required HoldemHandState handState,
    required HoldemEventCursor eventCursor,
    List<EventEnvelope> events = const <EventEnvelope>[],
    bool Function()? shouldPersist,
  }) {
    if (shouldPersist != null && !shouldPersist()) {
      return Future<RecoveryPersistenceResult>.value(
        RecoveryPersistenceResult.success(),
      );
    }
    if (events.length > _maxRecoveryEvents) {
      return _enqueueOperation(() {
        if (shouldPersist != null && !shouldPersist()) {
          return RecoveryPersistenceResult.success();
        }
        final result = RecoveryPersistenceResult(
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
      if (shouldPersist != null && !shouldPersist()) {
        return RecoveryPersistenceResult.success();
      }
      final String snapshotId;
      try {
        snapshotId = _snapshotIdFactory(tableState, eventCursor);
      } on Object {
        final result = RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>['Holdem snapshot ID could not be created.'],
        );
        _lastResult = result;
        return result;
      }
      if (!AppHoldemProductionSessionSnapshotWriter.isSafeSnapshotMetadata(
        snapshotId,
      )) {
        final result = RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>['Holdem snapshot identity is invalid.'],
        );
        _lastResult = result;
        return result;
      }
      if (!AppHoldemProductionSessionSnapshotWriter.isSafeSnapshotMetadata(
            _snapshotType,
          ) ||
          !AppHoldemProductionSessionSnapshotWriter.isSafeSnapshotMetadata(
            _snapshotVersion,
          )) {
        final result = RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>[
            if (!AppHoldemProductionSessionSnapshotWriter.isSafeSnapshotMetadata(
              _snapshotType,
            ))
              'Holdem snapshot type is invalid.'
            else
              'Holdem snapshot version is invalid.',
          ],
        );
        _lastResult = result;
        return result;
      }

      final int serializedBytes;
      try {
        serializedBytes = _measureCheckpointBytes(
          snapshotId: snapshotId,
          tableState: tableState,
          handState: handState,
          eventCursor: eventCursor,
          events: capturedEvents,
        );
      } on _PendingCheckpointTooLarge {
        final result = RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>[
            'Holdem snapshot checkpoint exceeds the configured pending byte limit.',
          ],
        );
        _lastResult = result;
        return result;
      } on Object {
        final result = RecoveryPersistenceResult(
          isSuccess: false,
          warnings: <String>[
            'Holdem snapshot checkpoint serialization is unavailable.',
          ],
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
          serializedBytes: serializedBytes,
        ),
      );
    });
  }

  Future<RecoveryPersistenceResult> retryPending() {
    return _enqueueOperation(() {
      if (_pending.isEmpty) {
        return RecoveryPersistenceResult.success();
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
      _pendingBytes = 0;
      _lastResult = RecoveryPersistenceResult.success();
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
          if (!_canQueue(checkpoint)) {
            return _queueLimitResult(pendingResult);
          }
          _pending.add(checkpoint);
          _pendingBytes += checkpoint.serializedBytes;
        }
        return pendingResult;
      }
      _pending.removeAt(0);
      _pendingBytes -= pending.serializedBytes;
      if (identical(pending, checkpoint)) return pendingResult;
    }

    final result = _save(checkpoint);
    _lastResult = result;
    if (!result.isSuccess) {
      if (!_canQueue(checkpoint)) {
        return _queueLimitResult(result);
      }
      _pending.add(
        checkpoint.copyWith(
          eventsAlreadyPersisted: result.warnings.contains(
            'Holdem snapshot checkpoint failed after event-log persistence.',
          ),
        ),
      );
      _pendingBytes += checkpoint.serializedBytes;
    }
    return result;
  }

  bool _canQueue(_SnapshotCheckpoint checkpoint) {
    if (_pending.length >= _maxPendingCheckpoints) return false;
    return checkpoint.serializedBytes <=
        _maxPendingCheckpointBytes - _pendingBytes;
  }

  RecoveryPersistenceResult _queueLimitResult(
    RecoveryPersistenceResult result,
  ) {
    final warning = _pending.length >= _maxPendingCheckpoints
        ? 'Holdem snapshot checkpoint queue is full.'
        : 'Holdem snapshot checkpoint byte budget is full.';
    final bounded = RecoveryPersistenceResult(
      isSuccess: false,
      conflicts: result.conflicts,
      warnings: <String>[...result.warnings, warning],
    );
    _lastResult = bounded;
    return bounded;
  }

  int _measureCheckpointBytes({
    required String snapshotId,
    required TableState tableState,
    required HoldemHandState handState,
    required HoldemEventCursor eventCursor,
    required List<EventEnvelope> events,
  }) {
    try {
      const codec = EventEnvelopeCodec(
        maxBytes: RecoveryEventWindowLimits.defaultMaxEventBytes,
      );
      for (final event in events) {
        codec.encode(event);
      }
      final payload = HoldemStateSnapshot(
        tableState: tableState,
        handState: handState,
        eventCursor: eventCursor,
      ).toJson();
      final snapshot = SnapshotEnvelope(
        snapshotId: snapshotId,
        snapshotType: _snapshotType,
        snapshotVersion: _snapshotVersion,
        protocolVersion: tableState.protocolVersion,
        tableId: tableState.tableId,
        sessionId: tableState.sessionId,
        snapshotBaseEventSeq: eventCursor.nextEventSeq - 1,
        snapshotHash: computeCanonicalHash(payload),
        payload: payload,
      );
      return utf8
          .encode(
            canonicalJsonEncode(
              <String, Object?>{
                'snapshot': snapshot.toJson(),
                'events': events
                    .map((event) => event.toJson())
                    .toList(growable: false),
              },
              limits: CanonicalJsonLimits(
                maxEncodedBytes: _maxPendingCheckpointBytes,
              ),
            ),
          )
          .length;
    } on FormatException catch (error) {
      if (error.message == 'Canonical JSON payload is too large.' ||
          error.message == 'Event envelope wire payload is too large.') {
        throw const _PendingCheckpointTooLarge();
      }
      rethrow;
    }
  }

  RecoveryPersistenceResult _save(_SnapshotCheckpoint checkpoint) {
    try {
      return _persistenceWriter.persist(
        snapshotId: checkpoint.snapshotId,
        snapshotType: _snapshotType,
        snapshotVersion: _snapshotVersion,
        tableState: checkpoint.tableState,
        handState: checkpoint.handState,
        eventCursor: checkpoint.eventCursor,
        events: checkpoint.events,
        eventsAlreadyPersisted: checkpoint.eventsAlreadyPersisted,
      );
    } on Object {
      return RecoveryPersistenceResult(
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

int _validateMaxPendingCheckpointBytes(int value) {
  if (value <= 0) {
    throw ArgumentError.value(
      value,
      'maxPendingCheckpointBytes',
      'Pending snapshot checkpoint byte limit must be positive.',
    );
  }
  return value;
}

class _PendingCheckpointTooLarge implements Exception {
  const _PendingCheckpointTooLarge();
}

class _SnapshotCheckpoint {
  _SnapshotCheckpoint({
    required this.snapshotId,
    required this.tableState,
    required this.handState,
    required this.eventCursor,
    required List<EventEnvelope> events,
    required this.serializedBytes,
    this.eventsAlreadyPersisted = false,
  }) : events = List<EventEnvelope>.unmodifiable(events);

  _SnapshotCheckpoint copyWith({bool? eventsAlreadyPersisted}) {
    return _SnapshotCheckpoint(
      snapshotId: snapshotId,
      tableState: tableState,
      handState: handState,
      eventCursor: eventCursor,
      events: events,
      serializedBytes: serializedBytes,
      eventsAlreadyPersisted:
          eventsAlreadyPersisted ?? this.eventsAlreadyPersisted,
    );
  }

  final String snapshotId;
  final TableState tableState;
  final HoldemHandState handState;
  final HoldemEventCursor eventCursor;
  final List<EventEnvelope> events;
  final int serializedBytes;
  final bool eventsAlreadyPersisted;
}

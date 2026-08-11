import 'package:meta/meta.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'holdem_core_projection_adapter.dart';
import 'holdem_hand_state.dart';

/// Typed variant state persisted inside a product-owned snapshot envelope.
///
/// This model owns only the state composition and wire shape. Persistence
/// selection, local identity, route metadata, and event policy remain outside
/// the variant package.
@immutable
class HoldemStateSnapshot {
  HoldemStateSnapshot({
    required this.tableState,
    required this.handState,
    required this.eventCursor,
  }) {
    if (tableState.tableId != eventCursor.tableId ||
        tableState.sessionId != eventCursor.sessionId ||
        tableState.protocolVersion != eventCursor.protocolVersion) {
      throw ArgumentError.value(
        eventCursor,
        'eventCursor',
        'Holdem snapshot state must share table, session, and protocol scope.',
      );
    }
  }

  factory HoldemStateSnapshot.fromJson(
    Map<String, Object?> json, {
    required HoldemEventIdFactory eventIdFactory,
    required HoldemEventTimestampFactory emittedAtFactory,
    HoldemEventHashFactory eventHashFactory = _defaultSnapshotEventHash,
  }) {
    try {
      return HoldemStateSnapshot(
        tableState: TableState.fromJson(_object(json, 'table_state')),
        handState: HoldemHandState.fromJson(_object(json, 'hand_state')),
        eventCursor: HoldemEventCursor.fromJson(
          _object(json, 'event_cursor'),
          eventIdFactory: eventIdFactory,
          emittedAtFactory: emittedAtFactory,
          eventHashFactory: eventHashFactory,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Holdem state snapshot scope is invalid: $error');
    }
  }

  final TableState tableState;
  final HoldemHandState handState;
  final HoldemEventCursor eventCursor;

  Map<String, Object?> toJson() => <String, Object?>{
    'table_state': tableState.toJson(),
    'hand_state': handState.toJson(),
    'event_cursor': eventCursor.toJson(),
  };
}

Map<String, Object?> _object(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map<Object?, Object?>) {
    throw FormatException('Holdem state snapshot $key must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException(
        'Holdem state snapshot $key contains a non-string key.',
      );
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _defaultSnapshotEventHash(Map<String, Object?> canonicalEvent) {
  return computeCanonicalHash(canonicalEvent);
}

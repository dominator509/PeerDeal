import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'table_phase.dart';

@immutable
class TableState {
  const TableState({
    required this.tableId,
    required this.sessionId,
    required this.phase,
    required this.protocolVersion,
    required this.eventSequence,
    required this.closeRequested,
    required this.playersConnected,
    required this.playersSeated,
    required this.activeHandId,
    required this.metadata,
  });

  factory TableState.initial({
    String tableId = 'table_1',
    String sessionId = 'session_1',
    String protocolVersion = '1.0',
  }) {
    return TableState(
      tableId: tableId,
      sessionId: sessionId,
      phase: TablePhase.draft,
      protocolVersion: protocolVersion,
      eventSequence: 0,
      closeRequested: false,
      playersConnected: 0,
      playersSeated: 0,
      activeHandId: null,
      metadata: const <String, Object?>{},
    );
  }

  factory TableState.fromJson(Map<String, Object?> json) {
    canonicalJsonEncode(json);
    final phaseValue = json['phase'];
    if (phaseValue is! String) {
      throw const FormatException('TableState phase must be a string.');
    }

    final TablePhase phase;
    try {
      phase = TablePhase.values.byName(phaseValue);
    } on ArgumentError {
      throw FormatException('Unknown TableState phase: $phaseValue.');
    }

    return TableState(
      tableId: _requiredString(json, 'table_id'),
      sessionId: _requiredString(json, 'session_id'),
      phase: phase,
      protocolVersion: _requiredString(json, 'protocol_version'),
      eventSequence: _requiredInt(json, 'event_sequence'),
      closeRequested: _requiredBool(json, 'close_requested'),
      playersConnected: _requiredInt(json, 'players_connected'),
      playersSeated: _requiredInt(json, 'players_seated'),
      activeHandId: _nullableString(json, 'active_hand_id'),
      metadata: _requiredMap(json, 'metadata'),
    );
  }

  final String tableId;
  final String sessionId;
  final TablePhase phase;
  final String protocolVersion;
  final int eventSequence;
  final bool closeRequested;
  final int playersConnected;
  final int playersSeated;
  final String? activeHandId;
  final Map<String, Object?> metadata;

  bool get hasActiveHand => activeHandId != null;

  int get eventSeq => eventSequence;

  int get participantCount => playersConnected;

  TableState copyWith({
    String? tableId,
    String? sessionId,
    TablePhase? phase,
    String? protocolVersion,
    int? eventSequence,
    bool? closeRequested,
    int? playersConnected,
    int? playersSeated,
    Object? activeHandId = _sentinel,
    Map<String, Object?>? metadata,
  }) {
    return TableState(
      tableId: tableId ?? this.tableId,
      sessionId: sessionId ?? this.sessionId,
      phase: phase ?? this.phase,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      eventSequence: eventSequence ?? this.eventSequence,
      closeRequested: closeRequested ?? this.closeRequested,
      playersConnected: playersConnected ?? this.playersConnected,
      playersSeated: playersSeated ?? this.playersSeated,
      activeHandId: identical(activeHandId, _sentinel)
          ? this.activeHandId
          : activeHandId as String?,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'table_id': tableId,
    'session_id': sessionId,
    'phase': phase.name,
    'protocol_version': protocolVersion,
    'event_sequence': eventSequence,
    'close_requested': closeRequested,
    'players_connected': playersConnected,
    'players_seated': playersSeated,
    'active_hand_id': activeHandId,
    'metadata': metadata,
  };

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('TableState $key must be a string.');
    }
    return value;
  }

  static String? _nullableString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value != null && value is! String) {
      throw FormatException('TableState $key must be a string or null.');
    }
    return value as String?;
  }

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('TableState $key must be an integer.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw FormatException('TableState $key must be a boolean.');
    }
    return value;
  }

  static Map<String, Object?> _requiredMap(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is! Map<Object?, Object?>) {
      throw FormatException('TableState $key must be an object.');
    }
    final entries = <MapEntry<String, Object?>>[];
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('TableState $key contains a non-string key.');
      }
      entries.add(MapEntry(entry.key as String, entry.value));
    }
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final entry in entries) entry.key: entry.value,
    });
  }

  static const Object _sentinel = Object();
}

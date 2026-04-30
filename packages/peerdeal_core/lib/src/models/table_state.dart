import 'package:meta/meta.dart';

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
    required String tableId,
    required String sessionId,
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
      activeHandId:
          identical(activeHandId, _sentinel) ? this.activeHandId : activeHandId as String?,
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

  static const Object _sentinel = Object();
}

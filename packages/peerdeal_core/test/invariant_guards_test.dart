import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

void main() {
  group('baseline invariant guards', () {
    test('flag impossible wiped state', () {
      final raw = jsonDecode(
        File('test/fixtures/invalid_wiped_state.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      final state = TableState(
        tableId: raw['table_id'] as String,
        sessionId: raw['session_id'] as String,
        phase: TablePhase.values.byName(raw['phase'] as String),
        protocolVersion: raw['protocol_version'] as String,
        eventSequence: raw['event_sequence'] as int,
        closeRequested: raw['close_requested'] as bool,
        playersConnected: raw['players_connected'] as int,
        playersSeated: raw['players_seated'] as int,
        activeHandId: raw['active_hand_id'] as String?,
        metadata: Map<String, Object?>.from(raw['metadata'] as Map),
      );

      const guards = <InvariantGuard>[
        ActiveHandRequiresLivePhaseGuard(),
        SeatCountCannotExceedConnectedGuard(),
        WipedPhaseMustNotHaveActiveStateGuard(),
      ];

      final violations = [for (final guard in guards) ...guard.evaluate(state)];

      expect(violations, isNotEmpty);
      expect(
        violations.map((e) => e.code),
        contains('ERR_WIPED_STATE_NOT_TERMINAL'),
      );
    });
  });
}

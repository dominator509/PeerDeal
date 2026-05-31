import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

void main() {
  group('baseline invariant guards', () {
    List<String> codesFor(TableState state) {
      return [
        for (final guard in baselineInvariantGuards)
          for (final violation in guard.evaluate(state)) violation.code,
      ];
    }

    test('accept clean initial table state', () {
      expect(codesFor(TableState.initial()), isEmpty);
    });

    test('flag missing table identity fields', () {
      final state = TableState.initial(
        tableId: ' ',
        sessionId: '',
        protocolVersion: ' ',
      );

      expect(
        codesFor(state),
        containsAll(<String>[
          CoreInvariantCodes.tableIdEmpty,
          CoreInvariantCodes.sessionIdEmpty,
          CoreInvariantCodes.protocolVersionEmpty,
        ]),
      );
    });

    test('flag negative counters and event sequence', () {
      final state = TableState.initial().copyWith(
        eventSequence: -1,
        playersConnected: -1,
        playersSeated: -1,
      );

      expect(
        codesFor(state),
        containsAll(<String>[
          CoreInvariantCodes.eventSequenceNegative,
          CoreInvariantCodes.connectedCountNegative,
          CoreInvariantCodes.seatedCountNegative,
        ]),
      );
    });

    test('flag empty active hand identity', () {
      final state = TableState.initial().copyWith(
        phase: TablePhase.liveActive,
        activeHandId: '',
      );

      expect(codesFor(state), contains(CoreInvariantCodes.activeHandIdEmpty));
    });

    test('flag active hand outside live phase', () {
      final state = TableState.initial().copyWith(
        phase: TablePhase.openReady,
        activeHandId: 'hand_001',
      );

      expect(
        codesFor(state),
        contains(CoreInvariantCodes.activeHandOutsideLivePhase),
      );
    });

    test('flag seated participants that exceed connected participants', () {
      final state = TableState.initial().copyWith(
        playersConnected: 1,
        playersSeated: 2,
      );

      expect(
        codesFor(state),
        contains(CoreInvariantCodes.seatedExceedsConnected),
      );
    });

    test('flag closing phase without close request marker', () {
      final state = TableState.initial().copyWith(phase: TablePhase.closing);

      expect(
        codesFor(state),
        contains(CoreInvariantCodes.closingWithoutCloseRequest),
      );
    });

    test('flag impossible closed state', () {
      final state = TableState.initial().copyWith(
        phase: TablePhase.closed,
        playersConnected: 1,
        playersSeated: 1,
      );

      expect(
        codesFor(state),
        containsAll(<String>[
          CoreInvariantCodes.closedStateNotTerminal,
          CoreInvariantCodes.closedStateNotCloseRequested,
        ]),
      );
    });

    test('flag impossible wiped state fixture', () {
      final raw =
          jsonDecode(
                File(
                  'test/fixtures/invalid_wiped_state.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

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

      expect(
        codesFor(state),
        contains(CoreInvariantCodes.wipedStateNotTerminal),
      );
    });

    test('flag wiped state without terminal close marker', () {
      final state = TableState.initial().copyWith(phase: TablePhase.wiped);

      expect(
        codesFor(state),
        contains(CoreInvariantCodes.wipedStateNotCloseRequested),
      );
    });
  });
}

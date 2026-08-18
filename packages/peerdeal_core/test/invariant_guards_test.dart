import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
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

    test('CoreReducer exposes configured state validation', () {
      final invalid = TableState.initial(
        tableId: ' ',
        sessionId: 'sess_001',
        protocolVersion: '1.0',
      ).copyWith(playersConnected: -1);

      final violations = const CoreReducer().validateState(invalid);

      expect(
        violations.map((violation) => violation.code),
        containsAll(<String>[
          CoreInvariantCodes.tableIdEmpty,
          CoreInvariantCodes.connectedCountNegative,
        ]),
      );
      expect(
        () => violations.add(
          const InvariantViolation(
            code: 'ERR_TEST_MUTATION',
            message: 'must remain immutable',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('CoreReducer rejects invalid current state before projection', () {
      final invalid = TableState.initial(
        tableId: ' ',
        sessionId: 'sess_001',
        protocolVersion: '1.0',
      );
      final event = EventEnvelope(
        eventId: 'evt_001',
        eventType: 'OpenTableSessionOpened',
        eventVersion: '1.0',
        protocolVersion: '1.0',
        eventSeq: 1,
        tableId: 'tbl_001',
        sessionId: 'sess_001',
        handId: null,
        emittedAt: '2026-08-17T00:00:00Z',
        actorRef: 'system',
        payload: const <String, Object?>{'mode_type': 'cash'},
        prevEventHash: genesisEventHash,
        eventHash: 'hash_001',
      );

      expect(
        () => const CoreReducer().apply(invalid, event),
        throwsA(
          isA<InvariantViolation>().having(
            (violation) => violation.code,
            'code',
            CoreInvariantCodes.tableIdEmpty,
          ),
        ),
      );
    });

    test('round-trips TableState JSON without losing typed fields', () {
      final state =
          TableState.initial(
            tableId: 'table_001',
            sessionId: 'session_001',
            protocolVersion: '1.0',
          ).copyWith(
            phase: TablePhase.liveActive,
            eventSequence: 7,
            closeRequested: true,
            playersConnected: 3,
            playersSeated: 2,
            activeHandId: 'hand_001',
            metadata: const <String, Object?>{'mode_type': 'open_table'},
          );

      final persisted = Map<String, Object?>.from(
        jsonDecode(jsonEncode(state.toJson())) as Map,
      );
      final restored = TableState.fromJson(persisted);

      expect(restored.toJson(), state.toJson());
    });

    test('rejects malformed TableState JSON', () {
      final malformed = TableState.initial().toJson()
        ..['phase'] = 'unknown_phase';

      expect(
        () => TableState.fromJson(malformed),
        throwsA(isA<FormatException>()),
      );

      final wrongType = TableState.initial().toJson()
        ..['players_connected'] = 'three';

      expect(
        () => TableState.fromJson(wrongType),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects structurally oversized metadata during hydration', () {
      final oversizedMetadata = <String, Object?>{
        for (var index = 0; index < 257; index++) 'metadata_$index': index,
      };
      final malformed = TableState.initial().toJson()
        ..['metadata'] = oversizedMetadata;

      expect(
        () => TableState.fromJson(malformed),
        throwsA(isA<FormatException>()),
      );
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

    test('flag unsafe table state identities', () {
      final state = TableState.initial(
        tableId: 'table\n1',
        sessionId: 'session_1\t',
        protocolVersion: '1.0\u0000',
      ).copyWith(phase: TablePhase.liveActive, activeHandId: 'hand\n1');

      expect(
        codesFor(state),
        containsAll(<String>[
          CoreInvariantCodes.tableIdUnsafe,
          CoreInvariantCodes.sessionIdUnsafe,
          CoreInvariantCodes.protocolVersionUnsafe,
          CoreInvariantCodes.activeHandIdUnsafe,
        ]),
      );
    });

    test('flag oversized table state identities', () {
      final oversizedId = String.fromCharCodes(
        List<int>.filled(const CanonicalJsonLimits().maxTextBytes + 1, 0x78),
      );
      final state = TableState.initial(
        tableId: oversizedId,
        sessionId: 'session_1',
        protocolVersion: '1.0',
      ).copyWith(phase: TablePhase.liveActive, activeHandId: oversizedId);

      expect(
        codesFor(state),
        containsAll(<String>[
          CoreInvariantCodes.tableIdUnsafe,
          CoreInvariantCodes.activeHandIdUnsafe,
        ]),
      );
    });

    test('flag non-round-tripping table state identities', () {
      final malformed = TableState.initial(
        tableId: String.fromCharCode(0xd800),
        sessionId: 'session_1',
        protocolVersion: '1.0',
      ).copyWith(phase: TablePhase.liveActive);

      expect(codesFor(malformed), contains(CoreInvariantCodes.tableIdUnsafe));
    });

    test('reject unsafe identities during TableState hydration', () {
      for (final entry in <String, String>{
        'table_id': 'table\n1',
        'session_id': ' session_1',
        'protocol_version': '1.0\u0000',
        'active_hand_id': 'hand\n1',
      }.entries) {
        final malformed = TableState.initial().toJson()
          ..[entry.key] = entry.value;

        expect(
          () => TableState.fromJson(malformed),
          throwsA(isA<FormatException>()),
          reason: entry.key,
        );
      }
    });

    test('reject oversized identities during TableState hydration', () {
      final oversizedId = String.fromCharCodes(
        List<int>.filled(const CanonicalJsonLimits().maxTextBytes + 1, 0x78),
      );
      final malformed = TableState.initial().toJson()
        ..['table_id'] = oversizedId;

      expect(
        () => TableState.fromJson(malformed),
        throwsA(isA<FormatException>()),
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

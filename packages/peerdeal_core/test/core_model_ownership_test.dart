import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

void main() {
  group('core model collection ownership', () {
    test('TableState deep-freezes metadata supplied by callers', () {
      final nestedValues = <Object?>['before'];
      final nested = <String, Object?>{'values': nestedValues};
      final metadata = <String, Object?>{'nested': nested};

      final state = TableState(
        tableId: 'table-1',
        sessionId: 'session-1',
        phase: TablePhase.draft,
        protocolVersion: '1.0',
        eventSequence: 0,
        closeRequested: false,
        playersConnected: 0,
        playersSeated: 0,
        activeHandId: null,
        metadata: metadata,
      );

      nestedValues.add('after');
      nested['later'] = true;
      metadata['outside'] = true;

      final stateNested = state.metadata['nested']! as Map<Object?, Object?>;
      final stateValues = stateNested['values']! as List<Object?>;
      expect(stateValues, <Object?>['before']);
      expect(stateNested.containsKey('later'), isFalse);
      expect(state.metadata.containsKey('outside'), isFalse);
      expect(() => stateValues.add('blocked'), throwsUnsupportedError);
      expect(() => stateNested['blocked'] = true, throwsUnsupportedError);
      expect(() => state.metadata['blocked'] = true, throwsUnsupportedError);
    });

    test('SettlementResult owns all caller-provided collections', () {
      final slices = <PotSlice>[_slice()];
      final awards = <PotAward>[
        const PotAward(sliceIndex: 0, seatId: 'seat-1', amount: 10),
      ];
      final ledgerDeltas = <LedgerDelta>[
        const LedgerDelta(seatId: 'seat-1', stackDelta: 10),
      ];
      final warnings = <String>['warning'];

      final result = SettlementResult(
        slices: slices,
        awards: awards,
        ledgerDeltas: ledgerDeltas,
        warnings: warnings,
      );

      slices.clear();
      awards.clear();
      ledgerDeltas.clear();
      warnings.clear();

      expect(result.slices, hasLength(1));
      expect(result.awards, hasLength(1));
      expect(result.ledgerDeltas, hasLength(1));
      expect(result.warnings, <String>['warning']);
      expect(() => result.slices.clear(), throwsUnsupportedError);
      expect(() => result.awards.clear(), throwsUnsupportedError);
      expect(() => result.ledgerDeltas.clear(), throwsUnsupportedError);
      expect(() => result.warnings.clear(), throwsUnsupportedError);
    });
  });
}

PotSlice _slice() {
  return PotSlice(
    sliceIndex: 0,
    amount: 10,
    contestedBySeatIds: <String>['seat-1'],
  );
}

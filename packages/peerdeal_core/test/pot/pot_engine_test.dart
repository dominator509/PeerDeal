import 'package:test/test.dart';
import 'package:peerdeal_core/peerdeal_core.dart';

void main() {
  test('settles split main pot and winner-only side pot', () {
    const engine = PotEngine();
    final result = engine.settle(
      commitments: const [
        PotCommitment(seatId: 'A', committed: 100, isEligibleForShowdown: true),
        PotCommitment(seatId: 'B', committed: 200, isEligibleForShowdown: true),
        PotCommitment(seatId: 'C', committed: 200, isEligibleForShowdown: true),
      ],
      winningSeatIdsBySliceIndex: const {
        0: ['A', 'B'],
        1: ['C'],
      },
    );

    expect(result.awards.length, 3);
    expect(result.awards.where((a) => a.seatId == 'A').first.amount, 150);
    expect(result.awards.where((a) => a.seatId == 'B').first.amount, 150);
    expect(result.awards.where((a) => a.seatId == 'C').first.amount, 200);
  });

  test('settles odd-chip main pot and side pot deterministically', () {
    const engine = PotEngine();

    SettlementResult settle() {
      return engine.settle(
        commitments: const [
          PotCommitment(
            seatId: 'seat-1',
            committed: 101,
            isEligibleForShowdown: true,
          ),
          PotCommitment(
            seatId: 'seat-2',
            committed: 101,
            isEligibleForShowdown: true,
          ),
          PotCommitment(
            seatId: 'seat-3',
            committed: 201,
            isEligibleForShowdown: true,
          ),
        ],
        winningSeatIdsBySliceIndex: const {
          0: ['seat-2', 'seat-1'],
          1: ['seat-3'],
        },
      );
    }

    final first = settle();
    final second = settle();

    expect(_awardTriples(first), <String>[
      '0:seat-1:152',
      '0:seat-2:151',
      '1:seat-3:100',
    ]);
    expect(_ledgerDeltas(first), <String>[
      'seat-1:51',
      'seat-2:50',
      'seat-3:-101',
    ]);
    expect(_awardTriples(second), _awardTriples(first));
    expect(_ledgerDeltas(second), _ledgerDeltas(first));
  });

  test('blocks settlement when a slice has no winners', () {
    const engine = PotEngine();
    final result = engine.settle(
      commitments: const [
        PotCommitment(seatId: 'A', committed: 100, isEligibleForShowdown: true),
        PotCommitment(seatId: 'B', committed: 100, isEligibleForShowdown: true),
      ],
      winningSeatIdsBySliceIndex: const {},
    );

    expect(result.isBlocked, isTrue);
    expect(result.isBalanced, isFalse);
    expect(result.totalPotAmount, 200);
    expect(result.totalAwardedAmount, 0);
    expect(result.awards, isEmpty);
    expect(result.ledgerDeltas, isEmpty);
    expect(result.warnings, <String>['ERR_CORE_SETTLEMENT_EMPTY_WINNERS']);
  });

  test('blocks settlement when a winner is not a slice contestant', () {
    const engine = PotEngine();
    final result = engine.settle(
      commitments: const [
        PotCommitment(seatId: 'A', committed: 100, isEligibleForShowdown: true),
        PotCommitment(seatId: 'B', committed: 100, isEligibleForShowdown: true),
      ],
      winningSeatIdsBySliceIndex: const {
        0: ['C'],
      },
    );

    expect(result.isBlocked, isTrue);
    expect(result.awards, isEmpty);
    expect(result.ledgerDeltas, isEmpty);
    expect(result.warnings, <String>[
      'ERR_CORE_SETTLEMENT_WINNER_NOT_CONTESTANT',
    ]);
  });

  test('blocks settlement when winners reference an unknown slice', () {
    const engine = PotEngine();
    final result = engine.settle(
      commitments: const [
        PotCommitment(seatId: 'A', committed: 100, isEligibleForShowdown: true),
        PotCommitment(seatId: 'B', committed: 100, isEligibleForShowdown: true),
      ],
      winningSeatIdsBySliceIndex: const {
        0: ['A'],
        1: ['B'],
      },
    );

    expect(result.isBlocked, isTrue);
    expect(result.awards, isEmpty);
    expect(result.ledgerDeltas, isEmpty);
    expect(result.warnings, <String>['ERR_CORE_SETTLEMENT_UNKNOWN_SLICE']);
  });

  test(
    'fails closed before side-pot construction on oversized commitments',
    () {
      const engine = PotEngine();
      final result = engine.settle(
        commitments: List<PotCommitment>.generate(
          CoreInputLimits.defaultMaxCommitments + 1,
          (index) => PotCommitment(
            seatId: 'seat-${index + 1}',
            committed: index + 1,
            isEligibleForShowdown: true,
          ),
          growable: false,
        ),
        winningSeatIdsBySliceIndex: const <int, List<String>>{},
      );

      expect(result.isBlocked, isTrue);
      expect(result.slices, isEmpty);
      expect(result.warnings, <String>['ERR_CORE_SETTLEMENT_COMMITMENT_COUNT']);
    },
  );

  test(
    'fails closed before side-pot construction on oversized winner maps',
    () {
      const engine = PotEngine();
      final result = engine.settle(
        commitments: const <PotCommitment>[
          PotCommitment(
            seatId: 'A',
            committed: 100,
            isEligibleForShowdown: true,
          ),
        ],
        winningSeatIdsBySliceIndex: <int, List<String>>{
          for (
            var index = 0;
            index < CoreInputLimits.defaultMaxWinningSliceEntries + 1;
            index++
          )
            index: <String>['A'],
        },
      );

      expect(result.isBlocked, isTrue);
      expect(result.slices, isEmpty);
      expect(result.warnings, <String>[
        'ERR_CORE_SETTLEMENT_WINNER_SLICE_COUNT',
      ]);
    },
  );

  test('fails closed on oversized winner lists within a slice', () {
    const engine = PotEngine();
    final result = engine.settle(
      commitments: const <PotCommitment>[
        PotCommitment(seatId: 'A', committed: 100, isEligibleForShowdown: true),
      ],
      winningSeatIdsBySliceIndex: <int, List<String>>{
        0: List<String>.generate(
          CoreInputLimits.defaultMaxWinnersPerSlice + 1,
          (index) => 'seat-${index + 1}',
          growable: false,
        ),
      },
    );

    expect(result.isBlocked, isTrue);
    expect(result.slices, isEmpty);
    expect(result.warnings, <String>['ERR_CORE_SETTLEMENT_WINNER_COUNT']);
  });
}

List<String> _awardTriples(SettlementResult settlement) {
  return [
    for (final award in settlement.awards)
      '${award.sliceIndex}:${award.seatId}:${award.amount}',
  ];
}

List<String> _ledgerDeltas(SettlementResult settlement) {
  return [
    for (final delta in settlement.ledgerDeltas)
      '${delta.seatId}:${delta.stackDelta}',
  ];
}

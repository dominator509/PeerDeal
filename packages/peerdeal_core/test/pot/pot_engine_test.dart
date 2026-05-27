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

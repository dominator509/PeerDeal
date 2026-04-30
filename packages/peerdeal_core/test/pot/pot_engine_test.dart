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
}

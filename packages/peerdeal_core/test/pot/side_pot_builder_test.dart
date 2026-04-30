import 'package:test/test.dart';
import 'package:peerdeal_core/peerdeal_core.dart';

void main() {
  test('builds main pot and one side pot deterministically', () {
    const builder = SidePotBuilder();
    final slices = builder.build(const [
      PotCommitment(seatId: 'A', committed: 100, isEligibleForShowdown: true),
      PotCommitment(seatId: 'B', committed: 200, isEligibleForShowdown: true),
      PotCommitment(seatId: 'C', committed: 200, isEligibleForShowdown: true),
    ]);

    expect(slices.length, 2);
    expect(slices[0].amount, 300);
    expect(slices[1].amount, 200);
    expect(slices[0].contestedBySeatIds, ['A', 'B', 'C']);
    expect(slices[1].contestedBySeatIds, ['B', 'C']);
  });
}

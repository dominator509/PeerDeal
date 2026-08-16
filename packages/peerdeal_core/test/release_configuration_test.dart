import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

void main() {
  test('rejects invalid configured limits at runtime', () {
    expect(
      () => const SidePotBuilder(maxCommitments: 0).build(const []),
      throwsArgumentError,
    );
    expect(
      () => const PotEngine(
        maxCommitments: 0,
      ).settle(commitments: const [], winningSeatIdsBySliceIndex: const {}),
      throwsArgumentError,
    );
  });
}

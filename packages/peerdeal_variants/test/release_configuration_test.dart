import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('rejects invalid configured limits at runtime', () {
    expect(
      () => const HoldemShowdownEvaluator(maxSeats: 0).evaluate(
        ShowdownEvaluationInput(boardCards: const [], seats: const []),
      ),
      throwsArgumentError,
    );
    expect(
      () => const ShowdownSettlementProjector(maxCommitments: 0)
          .projectUncontestedAndSettle(
            winningSeat: 1,
            commitments: const [],
            seatForId: (_) => 1,
          ),
      throwsArgumentError,
    );
  });
}

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  group('Holdem settlement projection', () {
    const adapter = HoldemAdapter();
    const projector = ShowdownSettlementProjector();

    test('settles from showdown through contested pot slices', () {
      final showdown = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['Th', '9d'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 2,
              holeCards: <String>['Ac', '3c'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 3,
              holeCards: <String>['Kh', 'Kc'],
              isFolded: true,
            ),
          ],
        ),
      );
      const commitments = <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'seat-2',
          committed: 200,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'seat-3',
          committed: 200,
          isEligibleForShowdown: false,
          isFolded: true,
        ),
      ];

      final outcome = projector.projectAndSettle(
        showdown: showdown,
        commitments: commitments,
        seatForId: _seatFromSeatId,
      );

      expect(outcome.projection.hasUnawardableSlices, isFalse);
      expect(outcome.settlement, isNotNull);
      expect(outcome.settlement!.awards.map((award) => award.seatId), <String>[
        'seat-1',
        'seat-2',
      ]);
      expect(outcome.settlement!.awards.map((award) => award.amount), <int>[
        300,
        200,
      ]);
    });

    test('blocks settlement when a contested slice is unawardable', () {
      final showdown = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['Th', '9d'],
              isFolded: false,
            ),
          ],
        ),
      );
      const commitments = <PotCommitment>[
        PotCommitment(
          seatId: 'seat-9',
          committed: 100,
          isEligibleForShowdown: true,
        ),
      ];

      final outcome = projector.projectAndSettle(
        showdown: showdown,
        commitments: commitments,
        seatForId: _seatFromSeatId,
      );

      expect(outcome.projection.unawardableSliceIndexes, <int>[0]);
      expect(outcome.settlement, isNull);
    });
  });
}

int? _seatFromSeatId(String seatId) {
  final marker = seatId.split('-').last;
  return int.tryParse(marker);
}

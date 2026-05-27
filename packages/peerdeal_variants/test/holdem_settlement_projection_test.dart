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

    test('blocks entire side-pot settlement when any slice is unawardable', () {
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
          committed: 100,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'unknown-seat',
          committed: 200,
          isEligibleForShowdown: true,
        ),
      ];

      final outcome = projector.projectAndSettle(
        showdown: showdown,
        commitments: commitments,
        seatForId: _seatFromSeatId,
      );

      expect(outcome.isBlocked, isTrue);
      expect(outcome.settlement, isNull);
      expect(outcome.projection.winningSeatIdsBySliceIndex[0], <String>[
        'seat-1',
      ]);
      expect(outcome.projection.unawardableSliceIndexes, <int>[1]);
    });

    test('settles odd-chip main pot and side pot deterministically', () {
      const showdown = ShowdownEvaluationResult(
        results: <RankedShowdownResult>[
          RankedShowdownResult(
            seat: 1,
            rankIndex: 0,
            summary: 'tied main pot winner',
          ),
          RankedShowdownResult(
            seat: 2,
            rankIndex: 0,
            summary: 'tied main pot winner',
          ),
          RankedShowdownResult(
            seat: 3,
            rankIndex: 1,
            summary: 'side-pot-only winner',
          ),
        ],
      );
      const commitments = <PotCommitment>[
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
      ];

      final first = projector.projectAndSettle(
        showdown: showdown,
        commitments: commitments,
        seatForId: _seatFromSeatId,
      );
      final second = projector.projectAndSettle(
        showdown: showdown,
        commitments: commitments,
        seatForId: _seatFromSeatId,
      );

      expect(first.isBlocked, isFalse);
      expect(first.settlement, isNotNull);
      expect(_awardTriples(first.settlement!), <String>[
        '0:seat-1:152',
        '0:seat-2:151',
        '1:seat-3:100',
      ]);
      expect(_ledgerDeltas(first.settlement!), <String>[
        'seat-1:51',
        'seat-2:50',
        'seat-3:-101',
      ]);
      expect(
        _awardTriples(second.settlement!),
        _awardTriples(first.settlement!),
      );
      expect(
        _ledgerDeltas(second.settlement!),
        _ledgerDeltas(first.settlement!),
      );
    });
  });
}

int? _seatFromSeatId(String seatId) {
  final marker = seatId.split('-').last;
  return int.tryParse(marker);
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

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

    test('fails closed before building too many contested commitments', () {
      const showdown = ShowdownEvaluationResult(
        results: <RankedShowdownResult>[
          RankedShowdownResult(seat: 1, rankIndex: 0, summary: 'winner'),
          RankedShowdownResult(seat: 2, rankIndex: 1, summary: 'runner-up'),
        ],
      );
      final commitments = List<PotCommitment>.generate(
        HoldemInputLimits.defaultMaxCommitments + 1,
        (index) => PotCommitment(
          seatId: 'seat-${index + 1}',
          committed: index + 1,
          isEligibleForShowdown: true,
        ),
        growable: false,
      );

      final outcome = projector.projectAndSettle(
        showdown: showdown,
        commitments: commitments,
        seatForId: _seatFromSeatId,
      );

      expect(outcome.isBlocked, isTrue);
      expect(outcome.slices, isEmpty);
      expect(outcome.warnings, <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_COMMITMENT_COUNT',
      ]);
    });

    test('fails closed before building too many uncontested commitments', () {
      final commitments = List<PotCommitment>.generate(
        HoldemInputLimits.defaultMaxCommitments + 1,
        (index) => PotCommitment(
          seatId: 'seat-${index + 1}',
          committed: index + 1,
          isEligibleForShowdown: true,
        ),
        growable: false,
      );

      final outcome = projector.projectUncontestedAndSettle(
        winningSeat: 1,
        commitments: commitments,
        seatForId: _seatFromSeatId,
      );

      expect(outcome.isBlocked, isTrue);
      expect(outcome.slices, isEmpty);
      expect(outcome.warnings, <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_COMMITMENT_COUNT',
      ]);
    });

    test(
      'propagates oversized showdown result warnings through settlement',
      () {
        final outcome = projector.projectAndSettle(
          showdown: ShowdownEvaluationResult(
            results: List<RankedShowdownResult>.generate(
              HoldemInputLimits.defaultMaxShowdownResults + 1,
              (index) => RankedShowdownResult(
                seat: index + 1,
                rankIndex: index,
                summary: 'result',
              ),
              growable: false,
            ),
          ),
          commitments: const <PotCommitment>[
            PotCommitment(
              seatId: 'seat-1',
              committed: 100,
              isEligibleForShowdown: true,
            ),
          ],
          seatForId: _seatFromSeatId,
        );

        expect(outcome.isBlocked, isTrue);
        expect(outcome.warnings, <String>['ERR_HOLDEM_SHOWDOWN_RESULT_COUNT']);
        expect(outcome.settlement, isNull);
      },
    );

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
      expect(outcome.warnings, <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
      ]);
      expect(outcome.settlement, isNull);
    });

    test('blocks settlement when a pot slice has no eligible contestant', () {
      const showdown = ShowdownEvaluationResult(
        results: <RankedShowdownResult>[
          RankedShowdownResult(
            seat: 1,
            rankIndex: 0,
            summary: 'winner cannot contest folded-only slice',
          ),
        ],
      );

      final outcome = projector.projectAndSettle(
        showdown: showdown,
        commitments: const <PotCommitment>[
          PotCommitment(
            seatId: 'seat-2',
            committed: 100,
            isEligibleForShowdown: false,
            isFolded: true,
          ),
          PotCommitment(
            seatId: 'seat-3',
            committed: 100,
            isEligibleForShowdown: false,
            isFolded: true,
          ),
        ],
        seatForId: _seatFromSeatId,
      );

      expect(outcome.isBlocked, isTrue);
      expect(outcome.projection.unawardableSliceIndexes, <int>[0]);
      expect(outcome.warnings, <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
      ]);
      expect(outcome.settlement, isNull);
    });

    test('settles uncontested winner without showdown ranking', () {
      final outcome = projector.projectUncontestedAndSettle(
        winningSeat: 1,
        commitments: const <PotCommitment>[
          PotCommitment(
            seatId: 'seat-1',
            committed: 100,
            isEligibleForShowdown: true,
          ),
          PotCommitment(
            seatId: 'seat-2',
            committed: 100,
            isEligibleForShowdown: false,
            isFolded: true,
          ),
          PotCommitment(
            seatId: 'seat-3',
            committed: 100,
            isEligibleForShowdown: false,
            isFolded: true,
          ),
        ],
        seatForId: _seatFromSeatId,
      );

      expect(outcome.isBlocked, isFalse);
      expect(outcome.settlement, isNotNull);
      expect(_awardTriples(outcome.settlement!), <String>['0:seat-1:300']);
      expect(_ledgerDeltas(outcome.settlement!), <String>[
        'seat-1:200',
        'seat-2:-100',
        'seat-3:-100',
      ]);
    });

    test(
      'blocks uncontested settlement when winner cannot contest a slice',
      () {
        final outcome = projector.projectUncontestedAndSettle(
          winningSeat: 1,
          commitments: const <PotCommitment>[
            PotCommitment(
              seatId: 'seat-1',
              committed: 100,
              isEligibleForShowdown: true,
            ),
            PotCommitment(
              seatId: 'seat-2',
              committed: 200,
              isEligibleForShowdown: false,
              isFolded: true,
            ),
          ],
          seatForId: _seatFromSeatId,
        );

        expect(outcome.isBlocked, isTrue);
        expect(outcome.projection.winningSeatIdsBySliceIndex[0], <String>[
          'seat-1',
        ]);
        expect(outcome.projection.unawardableSliceIndexes, <int>[1]);
        expect(outcome.warnings, <String>[
          'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
        ]);
        expect(outcome.settlement, isNull);
      },
    );

    test('blocks settlement when commitments are empty', () {
      const showdown = ShowdownEvaluationResult(
        results: <RankedShowdownResult>[
          RankedShowdownResult(
            seat: 1,
            rankIndex: 0,
            summary: 'winner without pot',
          ),
        ],
      );

      final outcome = projector.projectAndSettle(
        showdown: showdown,
        commitments: const <PotCommitment>[],
        seatForId: _seatFromSeatId,
      );

      expect(outcome.isBlocked, isTrue);
      expect(outcome.slices, isEmpty);
      expect(outcome.projection.winningSeatIdsBySliceIndex, isEmpty);
      expect(
        outcome.warnings,
        contains('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_COMMITMENTS'),
      );
      expect(
        outcome.warnings,
        contains('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT'),
      );
      expect(outcome.settlement, isNull);
    });

    test('blocks settlement when commitments produce no pot slices', () {
      const showdown = ShowdownEvaluationResult(
        results: <RankedShowdownResult>[
          RankedShowdownResult(
            seat: 1,
            rankIndex: 0,
            summary: 'winner without committed chips',
          ),
        ],
      );

      final outcome = projector.projectAndSettle(
        showdown: showdown,
        commitments: const <PotCommitment>[
          PotCommitment(
            seatId: 'seat-1',
            committed: 0,
            isEligibleForShowdown: true,
          ),
          PotCommitment(
            seatId: 'seat-2',
            committed: 0,
            isEligibleForShowdown: true,
          ),
        ],
        seatForId: _seatFromSeatId,
      );

      expect(outcome.isBlocked, isTrue);
      expect(outcome.slices, isEmpty);
      expect(outcome.projection.winningSeatIdsBySliceIndex, isEmpty);
      expect(outcome.warnings, <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT',
      ]);
      expect(outcome.settlement, isNull);
    });

    test('blocks settlement with invalid showdown reason code', () {
      const showdown = ShowdownEvaluationResult(
        results: <RankedShowdownResult>[],
        warnings: <String>['ERR_HOLDEM_SHOWDOWN_CARD_FORMAT'],
      );

      final outcome = projector.projectAndSettle(
        showdown: showdown,
        commitments: const <PotCommitment>[
          PotCommitment(
            seatId: 'seat-1',
            committed: 100,
            isEligibleForShowdown: true,
          ),
        ],
        seatForId: _seatFromSeatId,
      );

      expect(outcome.isBlocked, isTrue);
      expect(outcome.projection.unawardableSliceIndexes, isEmpty);
      expect(outcome.warnings, <String>[
        'ERR_HOLDEM_SHOWDOWN_CARD_FORMAT',
        'ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN',
      ]);
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
      expect(outcome.warnings, <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
      ]);
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
      expect(first.warnings, isEmpty);
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

import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

void main() {
  group('HoldemAdapter', () {
    const adapter = HoldemAdapter();

    test('returns locked launch identity', () {
      final identity = adapter.getIdentity();

      expect(identity.variantId, 'holdem_nlhe');
      expect(identity.holeCardCount, 2);
      expect(identity.boardCardCount, 5);
      expect(identity.bettingStructureType, 'no_limit');
    });

    test('builds flop-turn-river hand plan', () {
      final plan = adapter.buildHandPlan();

      expect(plan.privateCardsPerSeat, 2);
      expect(plan.boardStages, <int>[3, 1, 1]);
    });

    test('rejects invalid seat count', () {
      final result = adapter.validateConfig(
        seatCount: 10,
        modeType: 'open_table',
        bettingStructureType: 'no_limit',
      );

      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('showdown ranks active seats by best five-card hand', () {
      final result = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kh', 'Qh', 'Jh', '2c'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 3,
              holeCards: <String>['Tc', '9d'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['Th', '9c'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 2,
              holeCards: <String>['7c', '8d'],
              isFolded: true,
            ),
          ],
        ),
      );

      expect(result.results.map((entry) => entry.seat), <int>[1, 3]);
      expect(result.results.map((entry) => entry.rankIndex), <int>[0, 1]);
      expect(result.results.first.summary, startsWith('Straight flush'));
      expect(result.warnings, isEmpty);
    });

    test('showdown stub fails safely on malformed active inputs', () {
      final result = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kh', 'Qh', 'Jh'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['As'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 2,
              holeCards: <String>['7c'],
              isFolded: true,
            ),
          ],
        ),
      );

      expect(result.results, isEmpty);
      expect(result.warnings, contains('ERR_HOLDEM_SHOWDOWN_BOARD_CARD_COUNT'));
      expect(result.warnings, contains('ERR_HOLDEM_SHOWDOWN_HOLE_CARD_COUNT'));
    });

    test('showdown fails safely on malformed card identities', () {
      final result = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kh', 'Qh', 'Jh', '1x'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['As', 'Ad'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 2,
              holeCards: <String>['ZZ', '8d'],
              isFolded: false,
            ),
          ],
        ),
      );

      expect(result.results, isEmpty);
      expect(result.warnings, contains('ERR_HOLDEM_SHOWDOWN_CARD_FORMAT'));
    });

    test('showdown fails safely on duplicate active card identities', () {
      final result = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kh', 'Qh', 'Jh', '2c'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['As', 'Ad'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 2,
              holeCards: <String>['Ah', '8d'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 3,
              holeCards: <String>['Kh', 'Kh'],
              isFolded: true,
            ),
          ],
        ),
      );

      expect(result.results, isEmpty);
      expect(result.warnings, contains('ERR_HOLDEM_SHOWDOWN_DUPLICATE_CARD'));
    });

    test('showdown evaluator orders all launch hand categories', () {
      final cases = <_ShowdownCase>[
        _ShowdownCase(
          name: 'high card',
          boardCards: <String>['Ah', 'Kd', '8s', '5c', '2d'],
          winnerHoleCards: <String>['Qh', '9c'],
          loserHoleCards: <String>['Jh', '9d'],
          summaryPrefix: 'High card',
        ),
        _ShowdownCase(
          name: 'pair',
          boardCards: <String>['Ah', 'Kd', '8s', '5c', '2d'],
          winnerHoleCards: <String>['Qh', 'Qs'],
          loserHoleCards: <String>['Jh', '9d'],
          summaryPrefix: 'Pair',
        ),
        _ShowdownCase(
          name: 'two pair',
          boardCards: <String>['Ah', 'Kd', '8s', '5c', '2d'],
          winnerHoleCards: <String>['As', 'Ks'],
          loserHoleCards: <String>['Qh', 'Qd'],
          summaryPrefix: 'Two pair',
        ),
        _ShowdownCase(
          name: 'three of a kind',
          boardCards: <String>['Ah', 'Ad', '8s', '5c', '2d'],
          winnerHoleCards: <String>['As', 'Ks'],
          loserHoleCards: <String>['Qh', 'Qd'],
          summaryPrefix: 'Three of a kind',
        ),
        _ShowdownCase(
          name: 'straight',
          boardCards: <String>['9h', '8d', '7s', '5c', '2d'],
          winnerHoleCards: <String>['6s', 'Ks'],
          loserHoleCards: <String>['Ah', 'Ad'],
          summaryPrefix: 'Straight',
        ),
        _ShowdownCase(
          name: 'flush',
          boardCards: <String>['Ah', 'Jh', '8h', '5h', '2d'],
          winnerHoleCards: <String>['3h', 'Ks'],
          loserHoleCards: <String>['9s', '7d'],
          summaryPrefix: 'Flush',
        ),
        _ShowdownCase(
          name: 'full house',
          boardCards: <String>['Ah', 'Ad', '8s', '8c', '2d'],
          winnerHoleCards: <String>['As', 'Ks'],
          loserHoleCards: <String>['Qh', 'Qd'],
          summaryPrefix: 'Full house',
        ),
        _ShowdownCase(
          name: 'four of a kind',
          boardCards: <String>['Ah', 'Ad', 'As', '8c', '2d'],
          winnerHoleCards: <String>['Ac', 'Ks'],
          loserHoleCards: <String>['Qh', 'Qd'],
          summaryPrefix: 'Four of a kind',
        ),
        _ShowdownCase(
          name: 'straight flush',
          boardCards: <String>['Ah', 'Kh', 'Qh', 'Jh', '2d'],
          winnerHoleCards: <String>['Th', 'Ks'],
          loserHoleCards: <String>['Ac', 'Ad'],
          summaryPrefix: 'Straight flush',
        ),
      ];

      for (final showdownCase in cases) {
        final result = adapter.evaluate(
          ShowdownEvaluationInput(
            boardCards: showdownCase.boardCards,
            seats: <ShowdownSeatInput>[
              ShowdownSeatInput(
                seat: 1,
                holeCards: showdownCase.loserHoleCards,
                isFolded: false,
              ),
              ShowdownSeatInput(
                seat: 2,
                holeCards: showdownCase.winnerHoleCards,
                isFolded: false,
              ),
            ],
          ),
        );

        expect(result.warnings, isEmpty, reason: showdownCase.name);
        expect(result.results.first.seat, 2, reason: showdownCase.name);
        expect(
          result.results.first.summary,
          startsWith(showdownCase.summaryPrefix),
          reason: showdownCase.name,
        );
      }
    });

    test('showdown evaluator applies kicker and tie ordering', () {
      final kickerResult = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Ad', '8s', '5c', '2d'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['Kc', '7s'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 2,
              holeCards: <String>['Qc', '7d'],
              isFolded: false,
            ),
          ],
        ),
      );

      expect(kickerResult.results.map((entry) => entry.seat), <int>[1, 2]);
      expect(kickerResult.results.map((entry) => entry.rankIndex), <int>[0, 1]);

      final tieResult = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', 'Th'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 2,
              holeCards: <String>['2c', '3c'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['4d', '5d'],
              isFolded: false,
            ),
          ],
        ),
      );

      expect(tieResult.results.map((entry) => entry.seat), <int>[1, 2]);
      expect(tieResult.results.map((entry) => entry.rankIndex), <int>[0, 0]);
    });

    test(
      'showdown exposes deterministic winner groups for settlement input',
      () {
        final result = adapter.evaluate(
          const ShowdownEvaluationInput(
            boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', 'Th'],
            seats: <ShowdownSeatInput>[
              ShowdownSeatInput(
                seat: 4,
                holeCards: <String>['2c', '3c'],
                isFolded: false,
              ),
              ShowdownSeatInput(
                seat: 2,
                holeCards: <String>['4d', '5d'],
                isFolded: false,
              ),
              ShowdownSeatInput(
                seat: 1,
                holeCards: <String>['9c', '9d'],
                isFolded: false,
              ),
            ],
          ),
        );

        expect(result.warnings, isEmpty);
        expect(result.winnerGroups.length, 1);
        expect(result.winnerGroups.single.rankIndex, 0);
        expect(result.winnerGroups.single.seats, <int>[1, 2, 4]);
      },
    );

    test('showdown winner groups are empty for invalid evaluation', () {
      final result = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', 'bad'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['2c', '3c'],
              isFolded: false,
            ),
          ],
        ),
      );

      expect(result.results, isEmpty);
      expect(result.winnerGroups, isEmpty);
    });

    test('showdown projects slice winners for core pot settlement', () {
      final result = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['Ac', '3c'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 2,
              holeCards: <String>['Th', '9d'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 4,
              holeCards: <String>['Kh', 'Kc'],
              isFolded: false,
            ),
          ],
        ),
      );

      final winnersBySlice = result.winningSeatIdsBySliceIndex(
        eligibleSeatsBySliceIndex: const <int, Set<int>>{
          0: <int>{1, 2, 4},
          1: <int>{2, 4},
        },
        seatIdFor: (seat) => 'seat-$seat',
      );

      expect(winnersBySlice, <int, List<String>>{
        0: <String>['seat-2'],
        1: <String>['seat-2'],
      });

      const engine = PotEngine();
      final settlement = engine.settle(
        commitments: const <PotCommitment>[
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
            seatId: 'seat-4',
            committed: 200,
            isEligibleForShowdown: true,
          ),
        ],
        winningSeatIdsBySliceIndex: winnersBySlice,
      );

      expect(settlement.awards.length, 2);
      expect(settlement.awards[0].seatId, 'seat-2');
      expect(settlement.awards[0].amount, 300);
      expect(settlement.awards[1].seatId, 'seat-2');
      expect(settlement.awards[1].amount, 200);
    });

    test('showdown projection respects side-pot eligibility', () {
      final result = adapter.evaluate(
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

      const engine = PotEngine();
      final slices = engine.sidePotBuilder.build(const <PotCommitment>[
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
      ]);
      final eligibleSeatsBySliceIndex = <int, Set<int>>{
        for (final slice in slices)
          slice.sliceIndex: slice.contestedBySeatIds
              .map((seatId) => int.parse(seatId.split('-').last))
              .toSet(),
      };

      final winnersBySlice = result.winningSeatIdsBySliceIndex(
        eligibleSeatsBySliceIndex: eligibleSeatsBySliceIndex,
        seatIdFor: (seat) => 'seat-$seat',
      );
      final settlement = engine.settle(
        commitments: const <PotCommitment>[
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
        ],
        winningSeatIdsBySliceIndex: winnersBySlice,
      );

      expect(result.results.map((entry) => entry.seat), <int>[1, 2]);
      expect(slices.map((slice) => slice.amount), <int>[300, 200]);
      expect(slices[0].contestedBySeatIds, <String>['seat-1', 'seat-2']);
      expect(slices[1].contestedBySeatIds, <String>['seat-2']);
      expect(winnersBySlice, <int, List<String>>{
        0: <String>['seat-1'],
        1: <String>['seat-2'],
      });
      expect(settlement.awards.map((award) => award.seatId), <String>[
        'seat-1',
        'seat-2',
      ]);
      expect(settlement.awards.map((award) => award.amount), <int>[300, 200]);
    });
  });
}

class _ShowdownCase {
  const _ShowdownCase({
    required this.name,
    required this.boardCards,
    required this.winnerHoleCards,
    required this.loserHoleCards,
    required this.summaryPrefix,
  });

  final String name;
  final List<String> boardCards;
  final List<String> winnerHoleCards;
  final List<String> loserHoleCards;
  final String summaryPrefix;
}

import 'package:peerdeal_variants/peerdeal_variants.dart';
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

    test('showdown stub ranks active seats deterministically', () {
      final result = adapter.evaluate(
        const ShowdownEvaluationInput(
          boardCards: <String>['Ah', 'Kh', 'Qh', 'Jh', 'Th'],
          seats: <ShowdownSeatInput>[
            ShowdownSeatInput(
              seat: 3,
              holeCards: <String>['2c', '2d'],
              isFolded: false,
            ),
            ShowdownSeatInput(
              seat: 1,
              holeCards: <String>['As', 'Ad'],
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
      expect(
        result.warnings,
        contains('Showdown evaluator is a starter stub only.'),
      );
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
  });
}

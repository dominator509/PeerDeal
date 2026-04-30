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
  });
}

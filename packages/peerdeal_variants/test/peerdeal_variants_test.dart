import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('holdem adapter exposes locked baseline identity', () {
    const adapter = HoldemAdapter();
    expect(adapter.variantId, equals('holdem_nlhe'));
    expect(adapter.holeCardCount, equals(2));
    expect(adapter.boardCardCount, equals(5));
  });
}

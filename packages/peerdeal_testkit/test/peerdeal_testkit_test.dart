import 'package:peerdeal_testkit/peerdeal_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('scenario builder prefixes scenario name', () {
    final steps = const ScenarioBuilder().orderedSteps('join_flow', [
      'resolve',
      'bootstrap',
    ]);
    expect(steps.first, equals('scenario:join_flow'));
  });

  group('HoldemSettlementEmissionFixture', () {
    test('builds projected settlement and hand-settled events', () {
      final result = const HoldemSettlementEmissionFixture().projected();

      expect(result.settlement.isProjected, isTrue);
      expect(result.completion.isCompleted, isTrue);
      expect(result.emission.isProjected, isTrue);
      expect(result.emission.events.map((event) => event.eventType), <String>[
        'SettlementProjected',
        'HandSettled',
      ]);
    });

    test('builds blocked settlement event for unawardable slices', () {
      final result = const HoldemSettlementEmissionFixture()
          .blockedUnawardable();

      expect(result.settlement.isProjected, isFalse);
      expect(result.completion.isCompleted, isFalse);
      expect(result.emission.isBlocked, isTrue);
      expect(result.emission.events.map((event) => event.eventType), <String>[
        'SettlementBlocked',
      ]);
      expect(
        result.emission.settlementBlocked!.payload['reason_codes'],
        <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE'],
      );
    });
  });
}

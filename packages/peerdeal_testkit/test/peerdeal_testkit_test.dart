import 'package:peerdeal_testkit/peerdeal_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('scenario builder prefixes scenario name', () {
    final steps = const ScenarioBuilder().orderedSteps('join_flow', ['resolve', 'bootstrap']);
    expect(steps.first, equals('scenario:join_flow'));
  });
}

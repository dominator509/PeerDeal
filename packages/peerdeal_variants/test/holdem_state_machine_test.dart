import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const machine = HoldemStateMachine();

  test('allows canonical preflop to flop transition', () {
    final result = machine.canTransition(
      from: HoldemHandPhase.bettingPreflop,
      to: HoldemHandPhase.dealingFlop,
    );

    expect(result.isAllowed, isTrue);
  });

  test('rejects illegal early showdown transition', () {
    final result = machine.canTransition(
      from: HoldemHandPhase.blindsPosting,
      to: HoldemHandPhase.showdownPrep,
    );

    expect(result.isAllowed, isFalse);
  });
}

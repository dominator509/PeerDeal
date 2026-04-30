import 'odd_chip_policy.dart';

class SettlementPolicy {
  const SettlementPolicy({
    this.oddChipPolicy = OddChipPolicy.firstWinnerByDeterministicOrder,
  });

  final OddChipPolicy oddChipPolicy;
}

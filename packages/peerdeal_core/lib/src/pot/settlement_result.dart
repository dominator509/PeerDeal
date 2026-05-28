import 'ledger_delta_hook.dart';
import 'pot_slice.dart';

class PotAward {
  const PotAward({
    required this.sliceIndex,
    required this.seatId,
    required this.amount,
  });

  final int sliceIndex;
  final String seatId;
  final int amount;
}

class SettlementResult {
  const SettlementResult({
    required this.slices,
    required this.awards,
    required this.ledgerDeltas,
    this.warnings = const <String>[],
  });

  final List<PotSlice> slices;
  final List<PotAward> awards;
  final List<LedgerDelta> ledgerDeltas;
  final List<String> warnings;

  int get totalPotAmount {
    return slices.fold<int>(0, (total, slice) => total + slice.amount);
  }

  int get totalAwardedAmount {
    return awards.fold<int>(0, (total, award) => total + award.amount);
  }

  bool get isBalanced =>
      warnings.isEmpty && totalPotAmount == totalAwardedAmount;

  bool get isBlocked => warnings.isNotEmpty;
}

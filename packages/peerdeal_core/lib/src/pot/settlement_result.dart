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
  SettlementResult({
    required List<PotSlice> slices,
    required List<PotAward> awards,
    required List<LedgerDelta> ledgerDeltas,
    List<String> warnings = const <String>[],
  }) : slices = List<PotSlice>.unmodifiable(slices),
       awards = List<PotAward>.unmodifiable(awards),
       ledgerDeltas = List<LedgerDelta>.unmodifiable(ledgerDeltas),
       warnings = List<String>.unmodifiable(warnings);

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

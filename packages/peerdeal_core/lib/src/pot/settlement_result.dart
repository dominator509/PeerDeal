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
  });

  final List<PotSlice> slices;
  final List<PotAward> awards;
  final List<LedgerDelta> ledgerDeltas;
}

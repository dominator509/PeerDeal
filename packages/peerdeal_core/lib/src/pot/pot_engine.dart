import 'ledger_delta_hook.dart';
import 'pot_commitment.dart';
import 'settlement_policy.dart';
import 'settlement_result.dart';
import 'side_pot_builder.dart';

class PotEngine {
  const PotEngine({
    this.sidePotBuilder = const SidePotBuilder(),
    this.ledgerDeltaHook = const DefaultLedgerDeltaHook(),
  });

  final SidePotBuilder sidePotBuilder;
  final LedgerDeltaHook ledgerDeltaHook;

  SettlementResult settle({
    required List<PotCommitment> commitments,
    required Map<int, List<String>> winningSeatIdsBySliceIndex,
    SettlementPolicy policy = const SettlementPolicy(),
  }) {
    final slices = sidePotBuilder.build(commitments);
    final awards = <PotAward>[];
    final awardsBySeatId = <String, int>{};
    final committedBySeatId = <String, int>{
      for (final c in commitments) c.seatId: c.committed,
    };

    for (final slice in slices) {
      final winners = List<String>.from(
        winningSeatIdsBySliceIndex[slice.sliceIndex] ?? const <String>[],
      )..sort();

      if (winners.isEmpty) {
        continue;
      }

      final share = slice.amount ~/ winners.length;
      final remainder = slice.amount % winners.length;

      for (var i = 0; i < winners.length; i++) {
        final seatId = winners[i];
        final bonus = i == 0 ? remainder : 0;
        final amount = share + bonus;
        awards.add(PotAward(
          sliceIndex: slice.sliceIndex,
          seatId: seatId,
          amount: amount,
        ));
        awardsBySeatId.update(seatId, (v) => v + amount, ifAbsent: () => amount);
      }
    }

    final deltas = ledgerDeltaHook.buildDeltas(
      awardsBySeatId: awardsBySeatId,
      committedBySeatId: committedBySeatId,
    );

    return SettlementResult(
      slices: slices,
      awards: awards,
      ledgerDeltas: deltas,
    );
  }
}

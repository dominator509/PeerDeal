import '../models/core_input_limits.dart';
import 'ledger_delta_hook.dart';
import 'pot_commitment.dart';
import 'pot_slice.dart';
import 'settlement_policy.dart';
import 'settlement_result.dart';
import 'side_pot_builder.dart';

class PotEngine {
  const PotEngine({
    this.sidePotBuilder = const SidePotBuilder(),
    this.ledgerDeltaHook = const DefaultLedgerDeltaHook(),
    this.maxCommitments = CoreInputLimits.defaultMaxCommitments,
    this.maxWinningSliceEntries = CoreInputLimits.defaultMaxWinningSliceEntries,
    this.maxWinnersPerSlice = CoreInputLimits.defaultMaxWinnersPerSlice,
  }) : assert(maxCommitments > 0, 'maxCommitments must be positive'),
       assert(
         maxWinningSliceEntries > 0,
         'maxWinningSliceEntries must be positive',
       ),
       assert(maxWinnersPerSlice > 0, 'maxWinnersPerSlice must be positive');

  final SidePotBuilder sidePotBuilder;
  final LedgerDeltaHook ledgerDeltaHook;
  final int maxCommitments;
  final int maxWinningSliceEntries;
  final int maxWinnersPerSlice;

  SettlementResult settle({
    required List<PotCommitment> commitments,
    required Map<int, List<String>> winningSeatIdsBySliceIndex,
    SettlementPolicy policy = const SettlementPolicy(),
  }) {
    final inputWarning = _inputLimitWarning(
      commitments: commitments,
      winningSeatIdsBySliceIndex: winningSeatIdsBySliceIndex,
    );
    if (inputWarning != null) {
      return SettlementResult(
        slices: const <PotSlice>[],
        awards: const <PotAward>[],
        ledgerDeltas: const <LedgerDelta>[],
        warnings: <String>[inputWarning],
      );
    }

    final slices = sidePotBuilder.build(commitments);
    final warnings = _validateWinnersBySlice(
      slices: slices,
      winningSeatIdsBySliceIndex: winningSeatIdsBySliceIndex,
    );
    if (warnings.isNotEmpty) {
      return SettlementResult(
        slices: slices,
        awards: const <PotAward>[],
        ledgerDeltas: const <LedgerDelta>[],
        warnings: warnings,
      );
    }

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
        awards.add(
          PotAward(
            sliceIndex: slice.sliceIndex,
            seatId: seatId,
            amount: amount,
          ),
        );
        awardsBySeatId.update(
          seatId,
          (v) => v + amount,
          ifAbsent: () => amount,
        );
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

  List<String> _validateWinnersBySlice({
    required List<PotSlice> slices,
    required Map<int, List<String>> winningSeatIdsBySliceIndex,
  }) {
    final warnings = <String>[];
    final sliceIndexes = slices.map((slice) => slice.sliceIndex).toSet();

    void addWarning(String warning) {
      if (!warnings.contains(warning)) {
        warnings.add(warning);
      }
    }

    for (final slice in slices) {
      final winners = winningSeatIdsBySliceIndex[slice.sliceIndex] ?? const [];
      if (winners.isEmpty) {
        addWarning('ERR_CORE_SETTLEMENT_EMPTY_WINNERS');
      }

      final contestants = slice.contestedBySeatIds.toSet();
      for (final winner in winners) {
        if (!contestants.contains(winner)) {
          addWarning('ERR_CORE_SETTLEMENT_WINNER_NOT_CONTESTANT');
        }
      }
    }

    for (final sliceIndex in winningSeatIdsBySliceIndex.keys) {
      if (!sliceIndexes.contains(sliceIndex)) {
        addWarning('ERR_CORE_SETTLEMENT_UNKNOWN_SLICE');
      }
    }

    return List<String>.unmodifiable(warnings);
  }

  String? _inputLimitWarning({
    required List<PotCommitment> commitments,
    required Map<int, List<String>> winningSeatIdsBySliceIndex,
  }) {
    if (commitments.length > maxCommitments) {
      return 'ERR_CORE_SETTLEMENT_COMMITMENT_COUNT';
    }
    if (winningSeatIdsBySliceIndex.length > maxWinningSliceEntries) {
      return 'ERR_CORE_SETTLEMENT_WINNER_SLICE_COUNT';
    }
    if (winningSeatIdsBySliceIndex.values.any(
      (winners) => winners.length > maxWinnersPerSlice,
    )) {
      return 'ERR_CORE_SETTLEMENT_WINNER_COUNT';
    }
    return null;
  }
}

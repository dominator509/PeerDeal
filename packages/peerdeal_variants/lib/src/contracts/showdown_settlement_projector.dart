import 'package:meta/meta.dart';
import 'package:peerdeal_core/peerdeal_core.dart';

import 'showdown_models.dart';
import '../holdem/holdem_input_limits.dart';

class ShowdownSettlementProjector {
  const ShowdownSettlementProjector({
    this.engine = const PotEngine(),
    this.maxCommitments = HoldemInputLimits.defaultMaxCommitments,
  }) : assert(maxCommitments > 0, 'maxCommitments must be positive');

  final PotEngine engine;
  final int maxCommitments;

  ShowdownSettlementProjectionResult projectAndSettle({
    required ShowdownEvaluationResult showdown,
    required List<PotCommitment> commitments,
    required int? Function(String seatId) seatForId,
    SettlementPolicy policy = const SettlementPolicy(),
  }) {
    if (commitments.length > maxCommitments) {
      return _blockedForCommitmentOverflow();
    }

    final slices = engine.sidePotBuilder.build(commitments);
    if (commitments.isEmpty || slices.isEmpty) {
      return ShowdownSettlementProjectionResult.blocked(
        slices: slices,
        projection: ShowdownSliceWinnerProjection(
          winningSeatIdsBySliceIndex: <int, List<String>>{},
          unawardableSliceIndexes: <int>[],
        ),
        warnings: <String>[
          if (commitments.isEmpty)
            'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_COMMITMENTS',
          'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT',
        ],
      );
    }

    if (showdown.warnings.isNotEmpty || showdown.results.isEmpty) {
      return ShowdownSettlementProjectionResult.blocked(
        slices: slices,
        projection: ShowdownSliceWinnerProjection(
          winningSeatIdsBySliceIndex: <int, List<String>>{},
          unawardableSliceIndexes: <int>[],
        ),
        warnings: <String>[
          ...showdown.warnings,
          'ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN',
        ],
      );
    }

    final projection = showdown.projectContestedSeatIdsBySliceIndex(
      contestedSeatIdsBySliceIndex: <int, List<String>>{
        for (final slice in slices) slice.sliceIndex: slice.contestedBySeatIds,
      },
      seatForId: seatForId,
    );

    if (projection.hasUnawardableSlices) {
      return ShowdownSettlementProjectionResult.blocked(
        slices: slices,
        projection: projection,
        warnings: projection.warnings.isEmpty
            ? const <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE']
            : projection.warnings,
      );
    }

    final settlement = engine.settle(
      commitments: commitments,
      winningSeatIdsBySliceIndex: projection.winningSeatIdsBySliceIndex,
      policy: policy,
    );
    final settlementWarnings = _settlementWarnings(settlement);
    if (settlementWarnings.isNotEmpty) {
      return ShowdownSettlementProjectionResult.blocked(
        slices: slices,
        projection: projection,
        warnings: settlementWarnings,
      );
    }

    return ShowdownSettlementProjectionResult.settled(
      slices: slices,
      projection: projection,
      settlement: settlement,
    );
  }

  ShowdownSettlementProjectionResult projectUncontestedAndSettle({
    required int winningSeat,
    required List<PotCommitment> commitments,
    required int? Function(String seatId) seatForId,
    SettlementPolicy policy = const SettlementPolicy(),
  }) {
    if (commitments.length > maxCommitments) {
      return _blockedForCommitmentOverflow();
    }

    final slices = engine.sidePotBuilder.build(commitments);
    if (commitments.isEmpty || slices.isEmpty) {
      return ShowdownSettlementProjectionResult.blocked(
        slices: slices,
        projection: ShowdownSliceWinnerProjection(
          winningSeatIdsBySliceIndex: <int, List<String>>{},
          unawardableSliceIndexes: <int>[],
        ),
        warnings: <String>[
          if (commitments.isEmpty)
            'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_COMMITMENTS',
          'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT',
        ],
      );
    }

    final winnersBySlice = <int, List<String>>{};
    final unawardableSliceIndexes = <int>[];
    for (final slice in slices) {
      final winnerIds =
          slice.contestedBySeatIds
              .where((seatId) => seatForId(seatId) == winningSeat)
              .toList()
            ..sort();
      if (winnerIds.isEmpty) {
        unawardableSliceIndexes.add(slice.sliceIndex);
      } else {
        winnersBySlice[slice.sliceIndex] = winnerIds;
      }
    }

    final projection = ShowdownSliceWinnerProjection(
      winningSeatIdsBySliceIndex: winnersBySlice,
      unawardableSliceIndexes: List<int>.unmodifiable(unawardableSliceIndexes),
    );
    if (projection.hasUnawardableSlices) {
      return ShowdownSettlementProjectionResult.blocked(
        slices: slices,
        projection: projection,
        warnings: const <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE'],
      );
    }

    final settlement = engine.settle(
      commitments: commitments,
      winningSeatIdsBySliceIndex: projection.winningSeatIdsBySliceIndex,
      policy: policy,
    );
    final settlementWarnings = _settlementWarnings(settlement);
    if (settlementWarnings.isNotEmpty) {
      return ShowdownSettlementProjectionResult.blocked(
        slices: slices,
        projection: projection,
        warnings: settlementWarnings,
      );
    }

    return ShowdownSettlementProjectionResult.settled(
      slices: slices,
      projection: projection,
      settlement: settlement,
    );
  }

  ShowdownSettlementProjectionResult _blockedForCommitmentOverflow() {
    return ShowdownSettlementProjectionResult.blocked(
      slices: const <PotSlice>[],
      projection: ShowdownSliceWinnerProjection(
        winningSeatIdsBySliceIndex: <int, List<String>>{},
        unawardableSliceIndexes: <int>[],
      ),
      warnings: const <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_COMMITMENT_COUNT',
      ],
    );
  }

  List<String> _settlementWarnings(SettlementResult settlement) {
    if (settlement.warnings.isEmpty &&
        settlement.isBalanced &&
        settlement.awards.isNotEmpty) {
      return const <String>[];
    }

    final warnings = <String>[];
    void addWarning(String warning) {
      if (!warnings.contains(warning)) {
        warnings.add(warning);
      }
    }

    for (final warning in settlement.warnings) {
      addWarning(warning);
    }
    if (settlement.awards.isEmpty || !settlement.isBalanced) {
      addWarning('ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE');
    }

    return List<String>.unmodifiable(warnings);
  }
}

@immutable
class ShowdownSettlementProjectionResult {
  ShowdownSettlementProjectionResult._({
    required List<PotSlice> slices,
    required this.projection,
    required this.settlement,
    required List<String> warnings,
  }) : slices = List<PotSlice>.unmodifiable(slices),
       warnings = List<String>.unmodifiable(warnings);

  ShowdownSettlementProjectionResult.blocked({
    required List<PotSlice> slices,
    required ShowdownSliceWinnerProjection projection,
    List<String> warnings = const <String>[],
  }) : this._(
         slices: slices,
         projection: projection,
         settlement: null,
         warnings: warnings,
       );

  ShowdownSettlementProjectionResult.settled({
    required List<PotSlice> slices,
    required ShowdownSliceWinnerProjection projection,
    required SettlementResult settlement,
  }) : this._(
         slices: slices,
         projection: projection,
         settlement: settlement,
         warnings: const <String>[],
       );

  final List<PotSlice> slices;
  final ShowdownSliceWinnerProjection projection;
  final SettlementResult? settlement;
  final List<String> warnings;

  bool get isBlocked => settlement == null;
}

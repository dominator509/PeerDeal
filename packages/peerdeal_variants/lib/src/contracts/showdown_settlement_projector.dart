import 'package:meta/meta.dart';
import 'package:peerdeal_core/peerdeal_core.dart';

import 'showdown_models.dart';

class ShowdownSettlementProjector {
  const ShowdownSettlementProjector({this.engine = const PotEngine()});

  final PotEngine engine;

  ShowdownSettlementProjectionResult projectAndSettle({
    required ShowdownEvaluationResult showdown,
    required List<PotCommitment> commitments,
    required int? Function(String seatId) seatForId,
    SettlementPolicy policy = const SettlementPolicy(),
  }) {
    final slices = engine.sidePotBuilder.build(commitments);
    if (commitments.isEmpty || slices.isEmpty) {
      return ShowdownSettlementProjectionResult.blocked(
        slices: slices,
        projection: const ShowdownSliceWinnerProjection(
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
        projection: const ShowdownSliceWinnerProjection(
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
        warnings: const <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE'],
      );
    }

    return ShowdownSettlementProjectionResult.settled(
      slices: slices,
      projection: projection,
      settlement: engine.settle(
        commitments: commitments,
        winningSeatIdsBySliceIndex: projection.winningSeatIdsBySliceIndex,
        policy: policy,
      ),
    );
  }
}

@immutable
class ShowdownSettlementProjectionResult {
  const ShowdownSettlementProjectionResult._({
    required this.slices,
    required this.projection,
    required this.settlement,
    required this.warnings,
  });

  const ShowdownSettlementProjectionResult.blocked({
    required List<PotSlice> slices,
    required ShowdownSliceWinnerProjection projection,
    List<String> warnings = const <String>[],
  }) : this._(
         slices: slices,
         projection: projection,
         settlement: null,
         warnings: warnings,
       );

  const ShowdownSettlementProjectionResult.settled({
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

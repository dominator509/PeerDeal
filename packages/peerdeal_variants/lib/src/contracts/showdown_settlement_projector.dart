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
  });

  const ShowdownSettlementProjectionResult.blocked({
    required List<PotSlice> slices,
    required ShowdownSliceWinnerProjection projection,
  }) : this._(slices: slices, projection: projection, settlement: null);

  const ShowdownSettlementProjectionResult.settled({
    required List<PotSlice> slices,
    required ShowdownSliceWinnerProjection projection,
    required SettlementResult settlement,
  }) : this._(slices: slices, projection: projection, settlement: settlement);

  final List<PotSlice> slices;
  final ShowdownSliceWinnerProjection projection;
  final SettlementResult? settlement;

  bool get isBlocked => settlement == null;
}

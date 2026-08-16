import '../models/core_input_limits.dart';
import 'pot_commitment.dart';
import 'pot_slice.dart';

class SidePotBuilder {
  const SidePotBuilder({
    this.maxCommitments = CoreInputLimits.defaultMaxCommitments,
  });

  final int maxCommitments;

  List<PotSlice> build(List<PotCommitment> commitments) {
    _validatePositiveLimit(maxCommitments, 'maxCommitments');
    if (commitments.length > maxCommitments) {
      return const <PotSlice>[];
    }

    final active = commitments.where((c) => c.committed > 0).toList()
      ..sort((a, b) => a.committed.compareTo(b.committed));

    if (active.isEmpty) {
      return const [];
    }

    final uniqueLevels = active.map((c) => c.committed).toSet().toList()
      ..sort();
    final slices = <PotSlice>[];
    var previous = 0;

    for (var i = 0; i < uniqueLevels.length; i++) {
      final level = uniqueLevels[i];
      final contributors = active.where((c) => c.committed >= level).toList();
      final contestants =
          contributors
              .where((c) => !c.isFolded && c.isEligibleForShowdown)
              .map((c) => c.seatId)
              .toList()
            ..sort();
      final width = level - previous;
      final amount = width * contributors.length;
      previous = level;

      if (amount > 0) {
        slices.add(
          PotSlice(
            sliceIndex: slices.length,
            amount: amount,
            contestedBySeatIds: contestants,
          ),
        );
      }
    }

    return slices;
  }
}

void _validatePositiveLimit(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
}

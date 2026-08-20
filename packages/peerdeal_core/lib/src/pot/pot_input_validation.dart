import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'pot_commitment.dart';

class PotInputValidation {
  const PotInputValidation._();

  static bool hasInvalidCommitment(Iterable<PotCommitment> commitments) {
    return commitments.any(
      (commitment) =>
          commitment.committed < 0 || !isSafeSeatId(commitment.seatId),
    );
  }

  static bool hasDuplicateCommitmentSeatIds(
    Iterable<PotCommitment> commitments,
  ) {
    final seatIds = <String>{};
    for (final commitment in commitments) {
      if (!seatIds.add(commitment.seatId)) return true;
    }
    return false;
  }

  static bool hasInvalidWinnerSeatId(
    Map<int, List<String>> winningSeatIdsBySliceIndex,
  ) {
    return winningSeatIdsBySliceIndex.values.any(
      (winnerIds) => winnerIds.any((seatId) => !isSafeSeatId(seatId)),
    );
  }

  static bool hasDuplicateWinnerSeatId(
    Map<int, List<String>> winningSeatIdsBySliceIndex,
  ) {
    for (final winnerIds in winningSeatIdsBySliceIndex.values) {
      final seatIds = <String>{};
      for (final seatId in winnerIds) {
        if (!seatIds.add(seatId)) return true;
      }
    }
    return false;
  }

  static bool isSafeSeatId(String value) {
    if (value.isEmpty || value.trim() != value) return false;
    if (!const CanonicalJsonLimits().isWithinUtf8TextLimit(value)) {
      return false;
    }
    return value.codeUnits.every(
      (unit) => unit >= 0x20 && !(unit >= 0x7f && unit <= 0x9f),
    );
  }
}

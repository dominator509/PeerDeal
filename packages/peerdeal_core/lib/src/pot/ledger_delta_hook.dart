class LedgerDelta {
  const LedgerDelta({
    required this.seatId,
    required this.stackDelta,
  });

  final String seatId;
  final int stackDelta;
}

abstract class LedgerDeltaHook {
  const LedgerDeltaHook();

  List<LedgerDelta> buildDeltas({
    required Map<String, int> awardsBySeatId,
    required Map<String, int> committedBySeatId,
  });
}

class DefaultLedgerDeltaHook extends LedgerDeltaHook {
  const DefaultLedgerDeltaHook();

  @override
  List<LedgerDelta> buildDeltas({
    required Map<String, int> awardsBySeatId,
    required Map<String, int> committedBySeatId,
  }) {
    final seatIds = <String>{
      ...awardsBySeatId.keys,
      ...committedBySeatId.keys,
    }.toList()
      ..sort();

    return seatIds
        .map((seatId) => LedgerDelta(
              seatId: seatId,
              stackDelta:
                  (awardsBySeatId[seatId] ?? 0) - (committedBySeatId[seatId] ?? 0),
            ))
        .toList(growable: false);
  }
}

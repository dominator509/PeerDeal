class PotSlice {
  PotSlice({
    required this.sliceIndex,
    required this.amount,
    required List<String> contestedBySeatIds,
  }) : contestedBySeatIds = List<String>.unmodifiable(contestedBySeatIds);

  final int sliceIndex;
  final int amount;
  final List<String> contestedBySeatIds;
}

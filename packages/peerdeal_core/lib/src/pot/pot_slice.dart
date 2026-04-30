class PotSlice {
  const PotSlice({
    required this.sliceIndex,
    required this.amount,
    required this.contestedBySeatIds,
  });

  final int sliceIndex;
  final int amount;
  final List<String> contestedBySeatIds;
}

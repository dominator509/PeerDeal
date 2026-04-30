class PotCommitment {
  const PotCommitment({
    required this.seatId,
    required this.committed,
    required this.isEligibleForShowdown,
    this.isFolded = false,
  });

  final String seatId;
  final int committed;
  final bool isEligibleForShowdown;
  final bool isFolded;
}

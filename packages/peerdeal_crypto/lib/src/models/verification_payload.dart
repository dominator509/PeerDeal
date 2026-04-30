class VerificationPayload {
  const VerificationPayload({
    required this.verificationLayersPassed,
    required this.verificationLayersFailed,
    this.replayAnchor,
    this.fairDealAnchor,
    this.settlementAnchor,
    this.warnings = const <String>[],
  });

  final List<String> verificationLayersPassed;
  final List<String> verificationLayersFailed;
  final String? replayAnchor;
  final String? fairDealAnchor;
  final String? settlementAnchor;
  final List<String> warnings;
}

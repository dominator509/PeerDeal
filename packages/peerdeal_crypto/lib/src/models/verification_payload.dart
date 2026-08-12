class VerificationPayload {
  VerificationPayload({
    required List<String> verificationLayersPassed,
    required List<String> verificationLayersFailed,
    this.replayAnchor,
    this.fairDealAnchor,
    this.settlementAnchor,
    List<String> warnings = const <String>[],
  }) : verificationLayersPassed = List<String>.unmodifiable(
         verificationLayersPassed,
       ),
       verificationLayersFailed = List<String>.unmodifiable(
         verificationLayersFailed,
       ),
       warnings = List<String>.unmodifiable(warnings);

  final List<String> verificationLayersPassed;
  final List<String> verificationLayersFailed;
  final String? replayAnchor;
  final String? fairDealAnchor;
  final String? settlementAnchor;
  final List<String> warnings;
}

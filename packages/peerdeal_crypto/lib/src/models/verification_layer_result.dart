class VerificationLayerResult {
  const VerificationLayerResult({
    required this.layerId,
    required this.passed,
    this.reason,
  });

  final String layerId;
  final bool passed;
  final String? reason;
}

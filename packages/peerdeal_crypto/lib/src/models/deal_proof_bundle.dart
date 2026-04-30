class DealProofBundle {
  const DealProofBundle({
    required this.providerId,
    required this.providerVersion,
    required this.proofReference,
    required this.normalizedFields,
    this.rawPayload,
  });

  final String providerId;
  final String providerVersion;
  final String proofReference;
  final Map<String, Object?> normalizedFields;
  final Map<String, Object?>? rawPayload;
}

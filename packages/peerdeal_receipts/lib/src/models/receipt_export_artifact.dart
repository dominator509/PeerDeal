class ReceiptExportArtifact {
  const ReceiptExportArtifact({
    required this.artifactType,
    required this.encodedBody,
    required this.minimalMetadata,
    this.reason,
  });

  const ReceiptExportArtifact.unavailable({required this.reason})
    : artifactType = 'unavailable',
      encodedBody = '',
      minimalMetadata = const <String, Object?>{};

  final String artifactType;
  final String encodedBody;
  final Map<String, Object?> minimalMetadata;
  final String? reason;
}

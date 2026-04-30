class ReceiptExportArtifact {
  const ReceiptExportArtifact({
    required this.artifactType,
    required this.encodedBody,
    required this.minimalMetadata,
  });

  final String artifactType;
  final String encodedBody;
  final Map<String, Object?> minimalMetadata;
}

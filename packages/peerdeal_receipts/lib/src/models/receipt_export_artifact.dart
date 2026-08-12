import 'model_collection_ownership.dart';

class ReceiptExportArtifact {
  ReceiptExportArtifact({
    required this.artifactType,
    required this.encodedBody,
    required Map<String, Object?> minimalMetadata,
    this.reason,
  }) : minimalMetadata = freezeReceiptObjectMap(minimalMetadata);

  ReceiptExportArtifact.unavailable({required this.reason})
    : artifactType = 'unavailable',
      encodedBody = '',
      minimalMetadata = const <String, Object?>{};

  final String artifactType;
  final String encodedBody;
  final Map<String, Object?> minimalMetadata;
  final String? reason;
}

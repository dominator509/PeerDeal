import 'model_collection_ownership.dart';

class DealProofBundle {
  factory DealProofBundle({
    required String providerId,
    required String providerVersion,
    required String proofReference,
    required Map<String, Object?> normalizedFields,
    Map<String, Object?>? rawPayload,
  }) {
    final frozenNormalizedFields = freezeCryptoObjectMap(normalizedFields);
    return DealProofBundle._(
      providerId: providerId,
      providerVersion: providerVersion,
      proofReference: proofReference,
      normalizedFields: frozenNormalizedFields,
      rawPayload: rawPayload == null
          ? null
          : identical(rawPayload, normalizedFields)
          ? frozenNormalizedFields
          : freezeCryptoObjectMap(rawPayload),
    );
  }

  DealProofBundle._({
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

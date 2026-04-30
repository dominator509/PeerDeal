import '../contracts/provider_proof_normalizer.dart';
import '../models/deal_proof_bundle.dart';

class DefaultProviderProofNormalizer implements ProviderProofNormalizer {
  const DefaultProviderProofNormalizer();

  @override
  DealProofBundle normalize({
    required String providerId,
    required String providerVersion,
    required Map<String, Object?> rawProof,
  }) {
    return DealProofBundle(
      providerId: providerId,
      providerVersion: providerVersion,
      proofReference: (rawProof['proof_ref'] ?? rawProof['proofReference'] ?? 'unknown').toString(),
      normalizedFields: Map<String, Object?>.from(rawProof),
      rawPayload: Map<String, Object?>.from(rawProof),
    );
  }
}

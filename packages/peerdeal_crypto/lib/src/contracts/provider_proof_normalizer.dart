import '../models/deal_proof_bundle.dart';

abstract interface class ProviderProofNormalizer {
  DealProofBundle normalize({
    required String providerId,
    required String providerVersion,
    required Map<String, Object?> rawProof,
  });
}

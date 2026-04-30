import '../models/deal_provider_descriptor.dart';
import '../models/deal_proof_bundle.dart';

abstract interface class DealProvider {
  DealProviderDescriptor getDescriptor();

  DealProofBundle normalizeProofBundle(Map<String, Object?> rawProof);
}

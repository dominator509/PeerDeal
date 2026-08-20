import '../models/deal_proof_bundle.dart';

/// Provider-owned proof verification for the generic verification engine.
///
/// The crypto package owns the boundary, while each provider integration owns
/// the actual proof semantics and cryptographic verification.
abstract interface class DealProofVerifier {
  bool verify(DealProofBundle proofBundle);
}

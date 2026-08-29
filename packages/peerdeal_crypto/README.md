# peerdeal_crypto

Starter package for PeerDeal fair-deal provider normalization and fairness / verification logic.

## Owns
- provider proof models
- verification request/result models
- verification engine contract
- provider normalization boundary
- bounded, fail-closed JSON provider-proof normalization with safe provider
  metadata validation
- baseline verification service with fail-closed request and proof-boundary
  validation; provider proof bundles are not considered verified unless an
  injected `DealProofVerifier` confirms them
- Verification request fixtures are decoded through a typed test-only loader;
  the fixture suite covers verified hand, partial session, and wiped outcomes
  through the existing engine boundary.

## Must not own
- UI rendering
- receipt export packaging
- reducer truth
- transport behavior

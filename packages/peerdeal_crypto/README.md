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
  validation

## Must not own
- UI rendering
- receipt export packaging
- reducer truth
- transport behavior

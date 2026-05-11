# AGENTS.md — peerdeal_privacy

## Package mission
Own privacy-focused runtime policy for PeerDeal:
- retention modes
- wipe scheduling semantics
- metadata minimization
- diagnostics scrubbing
- protocol diagnostic detail scrubbing
- disappearing session/message policy models

## Hard boundaries
Do not place in this package:
- reducers or poker-rule truth
- receipt authorization logic that belongs in `peerdeal_receipts`
- capture-policy resolution that belongs in `peerdeal_capture`
- network/bootstrap logic
- UI widgets or platform-channel code

## Change discipline
1. Preserve explicit retention semantics.
2. Prefer simple, deterministic policy objects over hidden flags.
3. Keep privacy claims technically honest and minimum-collection oriented.
4. Add or update fixtures/tests with every meaningful policy change.

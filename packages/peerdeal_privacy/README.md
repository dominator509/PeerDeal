# peerdeal_privacy

Starter package for PeerDeal privacy policy, retention, wipe, metadata minimization, and diagnostics scrubbing.

## Owns
- retention modes
- wipe countdown policy
- disappearing session/message policy models
- metadata minimization policy
- diagnostics scrubbing policy
- protocol diagnostic detail scrubbing
- bounded recursive diagnostics output with stable truncation markers
- secure local storage policy seam

## Must not own
- poker truth
- receipt engine truth
- capture engine implementation
- transport/routing behavior
- UI rendering

## Fixture coverage
- Compact strict-ephemeral and timed-sandbox policy fixtures are decoded
  through a typed test-only loader and exercised through the retention engine's
  restore and wipe-decision boundary.

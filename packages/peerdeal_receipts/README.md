# peerdeal_receipts

Starter scaffold for PeerDeal receipt packaging, authorization, and wipe-aware resolution.

## Owns
- PeerDeal Receipt envelope and artifact models
- binding-mode and wipe-state models
- restore vs view authorization boundary
- signature / cipher contracts
- export opacity helpers
- receipt service orchestration
- receipt fixtures and package-local tests

## Must not own
- poker truth or ledger calculation truth
- transport bootstrap logic
- capture-engine behavior
- UI rendering
- money/value semantics

## Starter status
This scaffold is aligned to the locked PeerDeal receipt, retention, and privacy direction and is intended
as the first package drop for Sprint 11. It is not yet a production cryptographic implementation.

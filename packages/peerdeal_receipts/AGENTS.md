# AGENTS.md - peerdeal_receipts

## Mission
Implement PeerDeal receipts as privacy-centric, minimally identifying, signed/encrypted artifacts
without turning them into alternate truth or transferable value objects.

## Own
- receipt envelope and artifact models
- binding-mode and wipe-state behavior
- restore/view authorization rules
- signature and cipher integration seams
- export opacity helpers
- receipt fixtures and tests

## Do not own
- poker or ledger truth
- capture-engine behavior
- transport bootstrap logic
- UI rendering
- money, redemption, or settlement semantics

## Guardrails
- Receipts are session-bound and/or user-bound, never bearer-bound.
- Wrong-user and wrong-session restore must fail safely.
- Export artifacts stay opaque outside supported clients.
- Wiped receipts must resolve to unavailable/wiped state.
- Add or update fixtures whenever receipt semantics change.

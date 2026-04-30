# AGENTS.md — peerdeal_network (LAN + Relay Overlay)

## Package purpose
Own peer-session transport abstractions, LAN/remote path orchestration, relay fallback hooks, bootstrap candidate handling, and session path selection.

## Must not own
- canonical game truth
- reducer behavior
- receipt/ledger semantics
- capture policy
- UI presentation

## When modifying this package
1. Keep route/path logic transport-operational only.
2. Preserve deterministic path-selection behavior from the same inputs.
3. Prefer small changes within one service/model at a time.
4. Add or update fixtures when path-selection semantics change.
5. Do not leak platform APIs into this package; use native bridge contracts instead.

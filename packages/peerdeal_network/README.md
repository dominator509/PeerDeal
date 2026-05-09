# peerdeal_network

Network confidence and routing boundary for PeerDeal sessions.

## Purpose
This package owns transport-operational decisions that help a session choose,
score, and recover network paths without owning game truth.

## Owns
- LAN discovery
- relay fallback
- bootstrap candidate resolution
- session path selection
- direct-to-relay transition planning
- network confidence scoring
- primary peer election and transfer policy

## Must not own
- poker rules
- canonical game truth
- reducers or table state
- receipt or ledger semantics
- capture policy
- native platform APIs

## Related ownership
- `peerdeal_native_bridges` owns platform hooks and permission facts.
- `peerdeal_sync` owns sync and recovery behavior.
- app shells own user-facing connection flow orchestration.

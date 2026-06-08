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
- transport frame validation before platform transport send/receive code
- validating transport send boundary before platform transport adapters

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

## Hardened scaffold coverage
- Route-class semantics normalize `remoteDirect`/`p2pRemote` and
  `relayFallback`/`relay` compatibility names.
- Session path selection is deterministic across priority, route class, and
  peer id.
- Primary peer election fails closed when every peer is anchor-mismatched.
- Confidence classification degrades or requires recovery when peers lag the
  event index.
- Transport frame validation fails closed on missing session/peer identities,
  self-send frames, invalid sequence numbers, empty payloads, and oversized
  payloads before live transport implementations see the frame.
- The validating transport sender rejects invalid frames before calling a sink
  and converts sink exceptions into explicit failed send results.

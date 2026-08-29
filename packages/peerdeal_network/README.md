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
- validating transport receive boundary before session handlers

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
- Bootstrap candidate resolution drops blank, padded, control-character-bearing,
  or duplicate peer ids before assigning route class and priority.
- Bootstrap candidate resolution fails closed when its session or table scope
  identities are blank, padded, oversized, malformed UTF-8, or control-bearing.
- Direct network services bound peer IDs to 32, candidates to 32, and peer
  metrics to 64 before materialization; overflow fails closed without traversing
  an unbounded caller collection.
- Session path selection is deterministic across priority, route class, and
  peer id.
- Session path selection ignores malformed candidate peer ids and malformed
  elected-primary overrides before returning path descriptors.
- All actionable peer-id ingress now rejects the existing `none`, `unresolved`,
  and `::`-containing sentinels while retaining those values for generic
  session/table scope validation where appropriate.
- Primary peer election fails closed when every peer is anchor-mismatched.
- Primary peer election drops malformed peer metric identities and ignores
  malformed current-primary overrides before scoring or transfer decisions.
- Confidence classification and primary peer election fail closed on negative
  duration or counter measurements before they can influence scoring.
- Primary peer transfer and relay fallback planning fail closed on malformed or
  reserved path peer identities before emitting actionable plans.
- Confidence classification degrades or requires recovery when peers lag the
  event index.
- Transport frame validation fails closed on missing session/peer identities,
  self-send frames, sequence numbers outside the shared signed 32-bit ceiling,
  empty payloads, and oversized payloads. It also rejects payload entries
  outside the 0-through-255 byte range and C0/C1 control-bearing identities
  before live transport implementations see the frame.
- The validating transport sender rejects invalid frames before calling a sink
  and converts sink exceptions into explicit failed send results.
- The validating transport receiver rejects invalid frames before calling a
  session handler, converts handler exceptions into explicit failed receive
  results, applies bounded replay protection before handler dispatch, and
  rejects new unique frames when its active-plus-queued receive admission
  reaches the bounded in-flight limit (128 by default, configurable up to
  the existing 4,096-frame replay-window ceiling).
- `SlidingWindowTransportFrameReplayGuard` keys sequence windows by complete
  session/sender/recipient scope, rejects duplicate or stale sequences, allows
  unique frames inside its bounded window, and records a frame only after the
  handler accepts it.
- The network-owned discovery endpoint parser validates the existing
  `peer-id` and `peer-id@host[:port]` forms, bounds and deduplicates locations,
  drops malformed or sensitive values, and projects host/port metadata onto
  existing bootstrap candidates without overriding provider-owned metadata.

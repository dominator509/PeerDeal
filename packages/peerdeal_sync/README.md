# peerdeal_sync

Starter scaffold for the PeerDeal sync and snapshot-recovery lane.

## Scope
This package owns:
- event sequencing coordination
- snapshot application orchestration
- conflict detection
- reconciliation result shaping
- reconnect / handoff / transfer recovery coordination
- safe-close recommendation on irreconcilable mismatch

## Deliberate non-goals for this starter
- no live transport implementation
- no full persistence layer
- no production replay viewer
- no split-brain UI
- no real bootstrap service

## Expected next integration
This starter is meant to sit on top of `peerdeal_protocol` and `peerdeal_core`, and later connect to the replay and network lanes without letting transport or UI own truth.

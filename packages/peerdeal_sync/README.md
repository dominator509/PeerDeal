# peerdeal_sync

Starter scaffold for the PeerDeal sync and snapshot-recovery lane.

## Scope
This package owns:
- event sequencing coordination
- snapshot application orchestration
- conflict detection
- reconciliation result shaping
- reconnect / handoff / transfer recovery coordination
- recovery persistence contracts for snapshot/event windows
- safe-close recommendation on irreconcilable mismatch

## Deliberate non-goals for this starter
- no live transport implementation
- no production database or platform persistence implementation
- no production replay viewer
- no split-brain UI
- no real bootstrap service

## Expected next integration
This starter is meant to sit on top of `peerdeal_protocol` and `peerdeal_core`, and later connect to the replay and network lanes without letting transport or UI own truth.

## Hardened scaffold coverage
- Recovery requests fail closed when they have no snapshot and no events.
- Event windows without a snapshot must start at event sequence 1.
- Snapshot suffix windows must continue directly after the snapshot base event.
- The coordinator returns safe-close recommendations for fatal planning or
  apply-stage conflicts.
- Conflict-detector, snapshot-applier, and projector exceptions are normalized
  into fatal safe-close conflicts instead of escaping recovery callers.
- The recovery persistence contract has an in-memory gate that rejects
  table/session or protocol mismatches, sequence gaps, hash-chain breaks, and
  snapshots ahead of the stored event stream before mutating stored recovery
  windows.
- Recovery persistence scopes reject blank, padded, control-character, or
  delimiter-bearing identities before mutating memory or resolving file paths.
- Persisted snapshots cannot regress to an older checkpoint or replace an
  existing checkpoint with a different snapshot hash.
- A JSON file-backed recovery store can durably round-trip event/snapshot
  windows through protocol envelope parsers and fails closed when persisted
  data is corrupt.
- Protocol envelope parsers reject structurally oversized persisted payloads
  before file-backed recovery imports them into in-memory state.
- Recovery stores reject event windows above a configurable 4,096-event
  default and reject individual events above the protocol codec's configurable
  64 KiB default before mutating in-memory or durable state.
- File-backed recovery windows are written as canonical protocol JSON through
  a temporary file before replacing the durable window.
- Recovery stores expose an idempotent, scope-validated `wipe` operation;
  the JSON store removes the durable window and matching interrupted-write
  temporary files without touching other recovery scopes.

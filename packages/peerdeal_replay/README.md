# peerdeal_replay

Starter scaffold for PeerDeal replay, reconstruction, and mismatch diagnostics.

## Owns
- replay request / result contracts
- deterministic event replay seam
- anchor-hash generation and comparison
- snapshot + suffix replay seam
- replay mismatch diagnostics
- replay fixtures and package-local tests

## Must not own
- live networking or route choice
- UI rendering
- mode or variant config editing
- capture / receipt runtime behavior
- canonical truth outside verified config + ordered events

## Status
The generic replay boundary now verifies snapshot payload hashes and refuses to
apply a snapshot unless the supplied projector implements the optional typed
snapshot hydration contract. Product-owned projectors still own snapshot
payload interpretation and must preserve the invite-scoped state contract.

## Hardened scaffold coverage
- Replay rejects unsupported request, snapshot, and event protocol/catalog
  identities before projection.
- Replay event windows reject sequence gaps, non-increasing event sequences,
  hash-chain breaks, and snapshot suffix gaps before projection.
- Replay requests reject event windows above the configurable `EventWindowValidator`
  limit before protocol, scope, range, or projector traversal; the default is
  4,096 events and the failure code is `ERR_REPLAY_EVENT_WINDOW_TOO_LARGE`.
- Anchor hashing and snapshot-suffix planning apply the same default event
  bound. Canonical anchor hashing raises its configured input limit explicitly,
  while the replay engine converts selection and anchor failures into
  `ERR_REPLAY_SELECTION_FAILURE` and `ERR_REPLAY_ANCHOR_CALCULATION_FAILURE`.
- Replay request ranges reject non-positive or inverted event sequence bounds
  before filtering events or invoking reconstruction projectors.
- Replay now rejects event or snapshot table/session scope mismatches against
  the replay request before projection, so reconstruction cannot merge another
  table/session stream into verified state.
- Replay now converts projector construction/application failures into an
  explicit failed result instead of letting reconstruction exceptions escape.
- Snapshot replay recomputes the canonical payload hash and rejects negative
  snapshot base sequences or tampered payloads before projection. Snapshot
  requests require `ReplaySnapshotStateProjector` so the suffix is applied to
  verified typed snapshot state rather than a fresh base state.

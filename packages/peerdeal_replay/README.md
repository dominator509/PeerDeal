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

## Starter status
This scaffold is aligned to the locked PeerDeal replay/recovery direction and is intended
as the first package drop for Sprint 7. It is not yet a production reconstruction engine.

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

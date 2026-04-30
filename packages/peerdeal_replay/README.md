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

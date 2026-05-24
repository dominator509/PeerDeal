# peerdeal_protocol

Owns:
- command envelopes
- event envelopes
- snapshot envelopes
- snapshot artifact identity
- result codes
- stable public protocol failure code constants
- structured protocol diagnostics
- replay/sync result diagnostic projection
- protocol versions
- supported artifact catalog
- envelope-level compatibility checks
- Game File public schema contract
- invite payload public schema contract
- accepted and rejected protocol fixtures

Must not own:
- reducers
- transport implementation
- UI presentation
- mode or variant business logic

## Fixture convention
Accepted fixtures use supported protocol/catalog identities and should validate
cleanly. Rejected fixtures intentionally preserve valid JSON shape while
triggering fail-safe schema or catalog rejection.

## Catalog convention
The default protocol catalog is grouped by artifact family:
- `supportedCommandCatalogEntries`
- `supportedEventCatalogEntries`
- `supportedSnapshotCatalogEntries`

Envelope compatibility checks must reject unknown artifact identities before
downstream packages process them. New scaffold command, event, or snapshot
identities should be added to the matching catalog group with focused tests.

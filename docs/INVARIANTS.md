# PeerDeal Invariants

## Protocol
- commands do not mutate truth directly
- events are canonical truth
- protocol versions fail safe when unsupported

## Core
- live state is a projection of config + ordered events
- reducers are deterministic
- projected state identity fields are never empty
- event sequence and participant counters are never negative
- seated participant count never exceeds connected participant count
- active hand state only exists in `liveActive` and carries a non-empty hand id
- hand-scoped events must reference the active hand before they project
- closed and wiped states do not retain active hand or participant counts
- `SessionClosed` requires a prior close request and no active hand
- terminal closed states only accept a final wipe marker; wiped states never
  advance
- UI is never authoritative

## Repo
- dependencies point inward only
- no package owns truth outside its domain
- every major package must have local tests / fixtures

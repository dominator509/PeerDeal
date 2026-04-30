# PeerDeal Invariants

## Protocol
- commands do not mutate truth directly
- events are canonical truth
- protocol versions fail safe when unsupported

## Core
- live state is a projection of config + ordered events
- reducers are deterministic
- UI is never authoritative

## Repo
- dependencies point inward only
- no package owns truth outside its domain
- every major package must have local tests / fixtures

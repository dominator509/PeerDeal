# peerdeal_testkit

Shared test helpers for PeerDeal packages.

## Owns
- fixture loading helpers
- scenario builders
- shared adverse-condition simulator stubs

## Must not own
- production truth
- reducer behavior
- protocol schemas
- app orchestration

## Usage rule
Use this package to reduce test duplication. Do not make production packages
depend on it.

## Hold'em settlement emission fixture
`HoldemSettlementEmissionFixture` builds deterministic projected and blocked
settlement event emissions through the public `peerdeal_variants` emitter. Use it
from app/session tests that need a stable `SettlementBlocked` or
`SettlementProjected` -> `HandSettled` event boundary without calling the
individual variant event builders directly.

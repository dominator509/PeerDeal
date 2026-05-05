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

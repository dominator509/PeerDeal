# peerdeal_testkit agent rules

## Owns
- reusable test fixtures
- scenario builders
- fake/adverse-condition helpers for package tests

## Do not do
- move production logic into testkit
- make runtime packages depend on testkit
- define canonical protocol or reducer truth here

Keep helpers deterministic and package-agnostic.

# AGENTS.md - peerdeal_core

## Package mission
Own the deterministic universal poker-core boundary for PeerDeal.

## Allowed changes
- table state model
- reducer boundary and pure state transitions
- invariant evaluation
- validation contracts
- orchestrator contracts
- package-local fixtures and tests

## Forbidden changes
- no UI code
- no Flutter widgets
- no platform channels
- no routing / transport ownership
- no receipt or capture policy ownership
- no variant-specific showdown logic embedded in core
- no mode-specific open-table or tournament policy hacks hidden in reducers

## Change rules
1. Keep reducers deterministic and side-effect free.
2. Prefer explicit result objects over exceptions for expected validation failures.
3. Any new state field should have a test fixture or golden coverage.
4. Preserve inward dependency law.
5. If a change needs variant- or mode-specific logic, add or extend a contract instead of hardcoding.

## Required local checks
- `dart test`
- fixture-based reducer tests
- invariant guard tests

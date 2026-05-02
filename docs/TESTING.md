# PeerDeal Testing

## Required always-on CI gates
- protocol schema tests
- reducer determinism tests
- package-boundary checks

## Local baseline
Use `docs/MIGRATION_BASELINE.md` for the current green scaffold commands and
lane split.

## Required fixture ownership
- protocol fixtures -> peerdeal_protocol
- reducer fixtures -> peerdeal_core
- adapter fixtures -> peerdeal_variants / peerdeal_modes
- shared builders -> peerdeal_testkit

## Golden update rule
Goldens only change when:
- semantic behavior change is intended
- version notes exist where needed
- reviewer confirms invariants still hold

# peerdeal_core

Deterministic core starter scaffold for PeerDeal.

## Purpose
This package owns the universal deterministic core boundary:
- table/session state projection
- reducer boundary
- command validation contracts
- invariant guard contracts
- table orchestrator contract

It must **not** own:
- UI
- platform APIs
- network routing
- receipt/capture policy logic
- variant-specific showdown logic
- mode-specific session policy implementation

## Public entrypoint
Use `lib/peerdeal_core.dart` only. Do not import `lib/src/` from sibling packages or apps.

## Current scaffold contents
- starter table state model
- command and event envelopes for local core application
- reducer interface + default reducer
- invariant guard interface + baseline guards
- action validator and table orchestrator contracts
- deterministic fixture loader for starter tests

## Intended next implementation moves
1. expand command/event shapes to align with `peerdeal_protocol`
2. replace starter local envelopes with shared protocol models
3. wire real Hold'em hand lifecycle state machine
4. wire pot engine and settlement boundary
5. add replay-safe reducer coverage from canonical fixtures

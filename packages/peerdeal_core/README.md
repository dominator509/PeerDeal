# peerdeal_core

Deterministic protocol-native core for PeerDeal.

## Purpose
This package owns the universal deterministic core boundary:
- table/session state projection
- reducer boundary
- protocol-native command validation
- invariant guard contracts

It must **not** own:
- UI
- platform APIs
- network routing
- receipt/capture policy logic
- variant-specific showdown logic
- mode-specific session policy implementation

## Public entrypoint
Use `lib/peerdeal_core.dart` only. Do not import `lib/src/` from sibling packages or apps.

## Current core contents
- protocol `CommandEnvelope` and `EventEnvelope` models supplied by
  `peerdeal_protocol`
- deterministic table state model and protocol-native reducer
- invariant guard interface + baseline guards for identity, counters,
  participant counts, hand-scoped events, and terminal closed/wiped states
- deterministic fixture loader for starter tests
- replay-safe projection coverage for every accepted protocol event fixture
- protocol-native command validation against the catalog and safe envelope
  identity boundaries
- variant-agnostic pot settlement bounds before side-pot or award traversal:
  64 commitments, 64 winning slice-map entries, and 64 winners per slice

## Intended next implementation moves
1. wire real Hold'em hand lifecycle state machine output into core projection
2. wire pot engine and settlement boundary into ledger-safe core events
3. add broader replay-safe reducer coverage from canonical fixtures

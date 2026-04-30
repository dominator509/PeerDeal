# peerdeal_variants

Hold'em-first variant package for PeerDeal.

## Purpose
This package owns:
- variant adapter contracts
- Hold'em adapter implementation
- Hold'em hand lifecycle state model
- Hold'em action-order and action-validation seams
- showdown/evaluation hooks
- variant fixtures and tests

## Must not own
- session/mode policy
- transport/networking
- receipt/capture/privacy behavior
- app UI
- canonical table reducer truth outside the variant boundary

## Initial scope
This starter scaffold provides only enough structure to begin Sprint 4:
- canonical Hold'em hand phases
- betting-round model
- legal action boundary
- adapter identity/capabilities
- starter validator and state machine hooks
- starter showdown/evaluation contracts

It does **not** yet implement a full production poker engine.

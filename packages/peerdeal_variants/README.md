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

## Hold'em showdown to settlement
The intended app/session call order is:
1. Build a `ShowdownEvaluationInput` from the final board and active seat hole
   cards.
2. Call `HoldemAdapter.evaluate(input)`.
3. Build pot commitments in core terms with `PotCommitment`.
4. Call `ShowdownSettlementProjector.projectAndSettle(...)`.
5. Apply the returned settlement only when `result.isBlocked` is `false`.

The projector keeps the package boundary explicit:
- `peerdeal_variants` ranks Hold'em hands and maps ranked seats onto contested
  pot slices.
- `peerdeal_core` owns side-pot construction, award splitting, odd-chip policy,
  and ledger deltas.
- Apps/session code supplies the seat-id parser used to map core seat IDs back
  to showdown seat numbers.

Projection is fail-closed. If any contested pot slice cannot be matched to a
ranked showdown winner, `ShowdownSettlementProjectionResult.settlement` is
`null`, `isBlocked` is `true`, and `projection.unawardableSliceIndexes` names
the blocked slices. App/session orchestration should stop settlement and surface
a safe failure path instead of silently awarding partial pots.

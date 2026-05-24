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
- showdown/evaluation and settlement projection contracts

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

## Hold'em action application
`HoldemActionApplier` is a deterministic variant-local helper for applying a
validated table action to `HoldemHandState`. It updates stack, street
commitment, hand commitment, pot, folded/all-in flags, last aggressor, and last
action summary. It also reports the next actionable seat and obvious betting
round completion cases through `HoldemActionFlow`. Invalid actions return
`isApplied: false` and preserve the input state.

The applier only chooses the next actor within the current betting round. It
does not open streets or emit canonical core events; those remain session/core
orchestration responsibilities.

## Hold'em street advancement
`HoldemStateMachine.advanceAfterBettingRound(...)` advances from a completed
betting round to the next deal/showdown phase. Callers must provide the exact
new public board cards for that transition: three cards for the flop, one card
for the turn, one card for the river, and no cards when moving from river
betting to showdown prep.

Street advancement is fail-closed. Wrong board-card counts, malformed card
identities, duplicate public cards, or invalid source phases return
`isAdvanced: false`, preserve the input state, and report warning codes instead
of generating placeholder cards or throwing parser exceptions.

`HoldemActionStreetCoordinator.applyAndAdvanceIfComplete(...)` composes action
application with this street advancement contract. It first applies the
validated table action. If that action does not complete the betting round, the
coordinator returns the post-action state without touching board cards. If the
action completes the round, it attempts the supplied street advance and returns
either the advanced state or the post-action state plus street warning codes.
The coordinator does not emit protocol events, choose session policy, or perform
settlement.

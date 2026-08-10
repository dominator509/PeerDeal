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
`HoldemBlindPostingCoordinator.postBlinds(...)` is the deterministic
variant-local blind-posting gate. It runs only from `blindsPosting`, validates
positive blind amounts and eligible blind seats, posts partial all-in blinds
without exceeding stacks, updates pot/commitments/current bet, and advances to
`dealingHole`. Invalid or already-posted blind state fails closed without
mutation.

`HoldemActionApplier` is a deterministic variant-local helper for applying a
validated table action to `HoldemHandState`. It updates stack, street
commitment, hand commitment, pot, folded/all-in flags, last aggressor, and last
action summary. It also reports the next actionable seat and obvious betting
round completion cases through `HoldemActionFlow`. Invalid actions return
`isApplied: false` and preserve the input state.

The applier only chooses the next actor within the current betting round. It
does not open streets or emit canonical core events by itself; those remain
orchestration responsibilities.

`HoldemCoreProjectionAdapter` is the reusable orchestration boundary for that
handoff. It runs the action/street and showdown coordinators, emits only
catalog-approved `EventEnvelope` values, and applies them transactionally
through `peerdeal_core`'s `CoreReducer`. It also projects `HandStarted`,
`ShowdownStarted`, `ShowdownRevealed`, `SettlementProjected`,
`SettlementBlocked`, and `HandSettled` without moving Hold'em rules into core.
The adapter's immutable `HoldemEventCursor` owns contiguous sequence/hash
continuity; callers supply event-id and timestamp policy. If core rejects any
event in a batch, the returned core state, Hold'em state, cursor, and event list
remain unchanged.

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
When `openNextBettingRound` is true and the street advances into a deal phase,
the coordinator also attempts to open the next betting round. The coordinator
does not emit protocol events, choose session policy, or perform settlement.

`HoldemStateMachine.openBettingRoundAfterDeal(...)` completes the next half of
the street transition by moving a dealt flop, turn, or river into its betting
phase. It checks the public board-card count, chooses the first actionable seat
after the button, and fails closed with warning codes if the phase, board shape,
or actor state is not ready.

`HoldemShowdownCoordinator.reveal(...)` gates the transition from
`showdownPrep` to `showdownReveal`. It requires the showdown input board to
match the hand state board, requires at least two active non-folded showdown
seats, and only reveals when `HoldemShowdownEvaluator` returns no warnings. It
does not project settlement or mutate ledger state.
`HoldemShowdownCoordinator.prepareSettlement(...)` then gates
`showdownReveal` to `settling` only for a clean, non-empty showdown evaluation;
actual pot settlement remains in the settlement projector/core pot engine path.
`HoldemShowdownCoordinator.projectSettlement(...)` gates that projector call so
it only runs from `settling` with clean showdown data and non-empty commitments.
Blocked projections return warning codes and preserve state for the caller to
safe-close or recover.

`HoldemShowdownCoordinator.completeHand(...)` is the final lifecycle gate. It
only advances `settling` to `handComplete` after the settlement projection
succeeds, and otherwise returns warning codes without mutating state.

Uncontested hands skip showdown. `HoldemActionStreetCoordinator` routes a
completed action that leaves one active seat directly to `settling`, preserving
the post-action state and reporting the winning seat for later settlement.
`HoldemShowdownCoordinator.projectUncontestedSettlement(...)` then projects the
single winner through the same core pot engine path used by showdown
settlement, and fails closed if any pot slice cannot be contested by that
winner.

Zero-bet streets track `actedSeatsThisRound`, so checked flop/turn/river rounds
complete deterministically once every actionable seat has acted. Street
transitions reset that marker before the next betting round opens.

Full opening bets and full raises update `minimumRaiseAmount` to the actual
bet or raise increment for the next legal raise. Short all-ins can increase the
amount future seats must call, but they do not reset the minimum raise size or
claim last-aggressor/reopen semantics unless they meet the current full-raise
threshold.

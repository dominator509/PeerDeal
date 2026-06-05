# peerdeal_modes

Mode adapters and mode-scoped policy contracts for PeerDeal.

## Purpose
This package owns session-mode policy that sits above core poker truth and below
app orchestration.

## Owns
- open-table and tournament mode adapters
- participant role state
- seat state
- waitlist state
- governance actions and decisions
- governance engine behavior
- mode-scoped reload and ledger visibility policy

## Must not own
- transport or routing logic
- hand/action truth
- variant-specific poker rules
- receipt or capture implementation
- app UI or lifecycle orchestration

## Related ownership
- `peerdeal_core` owns deterministic table state truth.
- `peerdeal_variants` owns poker variant rules.
- app shells own user-facing flow orchestration.

## Hardened coverage
- Seat assignment and offer expiry now require manager authority and explicit
  lifecycle states before returning deterministic next participant/seat states.
- Co-host grant and revoke decisions now return explicit next role values and
  reject unauthorized or invalid role transitions.
- Waitlist promotion is deterministic: only a waitlisted participant at the head
  of the mode waitlist can be promoted, and promotion returns the next ordering
  without that participant.
- Mid-session waitlist promotion obeys mode policy and manager permissions.

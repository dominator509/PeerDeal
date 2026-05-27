# AGENTS.md - peerdeal_modes

## Scope
This subtree owns mode-aware governance policy scaffolding:
- role grants / revocations
- participant admission state
- seat offers / claims / release flow
- waitlist ordering / promotion
- governance decision outputs

## Must preserve
- Invite-only admission
- No silent privilege escalation
- Deterministic waitlist ordering
- Replay-safe administrative actions
- Separation from hand/action truth
- Separation from transport implementation

## Do not put here
- live networking code
- UI widgets
- hand reducers
- showdown logic
- receipt encryption or capture policy implementation

## Tests to keep green
- governance decision tests
- waitlist ordering fixtures
- role/seat transition fixture tests
- host/co-host permission boundary tests

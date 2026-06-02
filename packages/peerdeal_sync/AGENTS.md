# AGENTS.md - peerdeal_sync

## Purpose
Keep sync, snapshot recovery, and reconciliation logic isolated from poker-rule truth, UI rendering, and platform-specific transport details.

## Guardrails
- Do not move poker-rule logic into this package.
- Do not make snapshots authoritative over canonical events.
- Do not allow recovery to invent state.
- Prefer explicit conflict codes over silent fallback.
- Safe-close is better than undefined continuation.

## Local change rule
A safe patch in this package should usually touch:
- `lib/src/models/*`
- `lib/src/contracts/*`
- `lib/src/engine/*`
- `test/*`

If you need UI changes or network transport behavior, that probably belongs in another package.

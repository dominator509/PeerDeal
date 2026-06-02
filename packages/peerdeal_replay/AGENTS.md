# AGENTS.md - peerdeal_replay

## Mission
Implement deterministic reconstruction and replay-safe diagnostics without creating alternate truth.

## Own
- replay contracts and result models
- anchor-hash calculation
- verified event-window replay flow
- snapshot + suffix apply path
- mismatch diagnostics
- replay fixtures and tests

## Do not own
- live transport or bootstrap logic
- UI state
- mode/variant config editing
- receipt or capture policy logic
- hidden state unavailable to deterministic replay

## Guardrails
- Verified canonical events always outrank snapshots.
- Replay must fail safe on gaps, mismatched anchors, or unsupported versions.
- Keep replay outputs deterministic and machine-readable.
- Add or update fixtures whenever replay semantics change.
- Do not let local speculative cache become authority.

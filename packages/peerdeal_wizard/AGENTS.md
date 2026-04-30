# AGENTS.md — peerdeal_wizard

## Mission
Implement host setup capture and resolution into a strict, validated, replay-safe Game File without letting setup UX become runtime truth.

## Own
- setup intent normalization
- preset stack merge order
- helper suggestion ingestion
- setup draft / validated-plan generation
- Game File compilation orchestration
- tooltip/help metadata registry
- wizard fixtures and tests

## Do not own
- live gameplay mutation
- reducer logic
- invite handshake enforcement
- receipt or capture runtime behavior
- hidden flags that bypass Game File validation

## Guardrails
- The Game File is the source of truth; wizard surfaces only produce it.
- Simple, advanced, and conversational paths must converge on the same output boundary.
- Helper suggestions are advisory and must never bypass validation.
- Preset resolution must be deterministic and conflict order must be explicit.
- Add or update fixtures whenever setup semantics change.

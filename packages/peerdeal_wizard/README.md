# peerdeal_wizard

Starter scaffold for PeerDeal setup generation and preset resolution.

## Owns
- `SetupIntent` capture / normalization
- `ResolvedSetupDraft` construction
- `ValidatedSetupPlan` generation
- preset merge order
- helper / suggestion orchestration
- tooltip/help metadata registry
- Game File compilation orchestration

## Must not own
- live table mutation
- hand or session truth
- invite admission enforcement
- runtime capture-policy behavior
- hidden wizard-only flags that bypass validation

## Starter status
This is a scaffold aligned to the locked PeerDeal wizard/setup specs. It is intended
for wiring into the larger monorepo once the Game File, mode, and variant packages
are present.

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
- fail-closed Game File compile result shaping for app/session orchestration

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

## Hardened scaffold coverage
- `DefaultGameFileCompiler.compile(...)` remains strict and throws for direct
  callers that misuse a non-build-ready plan.
- `DefaultGameFileCompiler.tryCompile(...)` returns an explicit rejected result
  with validation errors and warnings so app flows can fail closed without
  letting setup compiler exceptions escape.
- `DefaultPresetResolver.validateDraft(...)` rejects unsupported variants
  before Game File compilation; the launch wizard only builds `holdem_nlhe`
  plans until additional variant packages are implemented.
- `DefaultPresetResolver.resolveIntent(...)` trims setup intent ids and marks
  blank setup intent or host identities as unresolved issues before validation,
  preventing malformed setup identity from becoming a build-ready plan.
- `DefaultGameFileCompiler.tryCompile(...)` rechecks build-ready mode and
  variant support plus non-empty plan identity, so manually constructed plans
  cannot bypass resolver validation.

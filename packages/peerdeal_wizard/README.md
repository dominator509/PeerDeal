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
- `DefaultPresetResolver.validateDraft(...)` rejects unsafe applied preset IDs
  before a draft is considered build-ready; the compiler repeats this check at
  its own output boundary.
- `DefaultPresetResolver.mergeLayers(...)` rejects unsafe layer IDs and uses
  supplied order as the deterministic tie-breaker for equal priorities.
- Resolver output carries the pseudonymous creator and applied preset IDs into
  the compiled Game File; the compiler emits the complete protocol-shaped
  object with the current protocol version and validates it against the locked
  Game File schema and catalog before returning success.
- Empty `SetupIntent.presetRefs` preserves the existing behavior of merging all
  supplied layers. Nonempty references select exactly one matching layer per
  reference; missing, duplicate, padded, control-bearing, or oversized
  references fail closed.
- Preset resolution and direct Game File compilation apply bounded collection
  and canonical JSON checks, failing closed with stable `ERR_WIZARD_*` codes.
- Direct Game File compilation also rejects unsafe or oversized validation
  diagnostics and never returns their original text through the compile result
  or compiled Game File.
- Test fixtures for simple, advanced, conversational, and preset-stack inputs
  are decoded through typed test-only loaders and routed through resolver
  validation, preserving deterministic priority and helper-advisory behavior.

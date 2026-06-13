# Project State

Generated: 2026-06-13

## Current Retrofit Position

- Branch: `retrofit/baseline-v1`
- Backup tag: `pre-retrofit-20260613T075234Z`
- Current tier: T1 docs-only retrofit baseline
- Scope: Additive documentation/spec artifacts only; no application code, dependency, CI, package-boundary, or architecture changes.

## T1 Artifacts

- `MASTER_BOOTSTRAP.md`
- `REPO_INVENTORY.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `DECISIONS.log`
- `spec/BUNDLE_SOURCE_MANIFEST.md`
- `spec/baseline_v1_retrofit/**`

## Required Gates

Run after each retrofit step:

- `rtk dart run melos run source-text`
- `rtk dart run melos run boundary-check`
- `rtk dart run melos run dependency-audit`
- `rtk dart run melos run analyze`
- `rtk dart run melos run test`
- `rtk git diff --check`

## Next Implementation Targets

1. Resolve `LEGACY-GAP-2026-06-13-006` by aligning CI Melos installation with the repository dependency strategy.
2. Continue production hardening items recorded in `docs/PRODUCTION_READINESS.md` without crossing locked package boundaries.
3. Keep native bridge contracts generic; map app-specific receipt semantics in app shells or receipt package seams only.

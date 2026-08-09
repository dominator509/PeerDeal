# Project State

Generated: 2026-06-13

## Current Retrofit Position

- Branch: `retrofit/baseline-v1`
- Backup tag: `pre-retrofit-20260613T075234Z`
- Current tier: T4 CI and dependency hardening slice following the T1 retrofit baseline
- Scope: Additive documentation/spec artifacts plus CI and workspace toolchain alignment; no application or package code, package-boundary, or architecture changes.

## T1 Artifacts

- `MASTER_BOOTSTRAP.md`
- `REPO_INVENTORY.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `DECISIONS.log`
- `spec/BUNDLE_SOURCE_MANIFEST.md`
- `spec/baseline_v1_retrofit/**`

## Recent T4 Changes

- `.github/workflows/ci.yml` activates Melos 8.2.2.
- `pubspec.yaml` and `pubspec.lock` align the workspace on Melos 8.2.2.
- Compatible transitive lock refresh raises `mustache_template` to 2.0.5.

## Required Gates

Run after each retrofit step:

- `rtk dart run melos run source-text`
- `rtk dart run melos run boundary-check`
- `rtk dart run melos run dependency-audit`
- `rtk dart run melos run analyze`
- `rtk dart run melos run test`
- `rtk git diff --check`

## Next Implementation Targets

1. Replace native bridge stubs with platform implementations behind the existing generic method-channel contracts.
2. Add platform-secure receipt key storage behind the existing receipt key-ring, cipher, and signer contracts.
3. Continue production hardening items recorded in `docs/PRODUCTION_READINESS.md` without crossing locked package boundaries.

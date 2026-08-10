# Project State

Generated: 2026-08-09

## Current Retrofit Position

- Branch: `retrofit/baseline-v1`
- Backup tag: `pre-retrofit-20260613T075234Z`
- Current tier: T4 native host hardening following the T1 retrofit baseline and CI/dependency alignment
- Scope: Additive Android and Windows secure-key and capture host implementations behind existing app/package boundaries; no protocol, reducer, package-boundary, or architecture rewrite.

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
- `apps/peerdeal_mobile/android/` now provides the generated Android host and
  registers the generic secure-key method channel.
- Android secure-key records use Keystore AES-GCM encryption and durable
  namespace-bound storage; release signing is operator-configured and never
  defaults to debug keys.
- `apps/peerdeal_desktop/windows/` now registers the generic secure-key channel
  and stores bounded versioned records through Windows Credential Manager.
- `apps/peerdeal_mobile/android/` now registers the generic capture channel and
  toggles `FLAG_SECURE` through the app-owned blocking action.
- `apps/peerdeal_desktop/windows/` now registers the generic capture channel and
  applies `SetWindowDisplayAffinity` through the app-owned blocking action.
- Mirrored app capture coordinators serialize native blocking/release, downgrade
  to visual obscuring when blocking fails, and receipt routes release blocking
  on disposal.
- Sync recovery persistence now exposes a scope-validated, idempotent wipe
  primitive; the JSON store removes matching interrupted-write temp files while
  preserving other recovery scopes.
- Mobile and desktop app shells now expose deterministic retention coordinators
  that invoke the recovery wipe primitive only when the app-owned policy is due,
  plus per-session close coordinators that cache the first success or failure so
  duplicate close signals cannot repeat policy or storage work. Wiring these
  coordinators to the real session owner remains open.
- Mirrored app session-close event adapters now ignore non-close events, reject
  unsupported versions, mismatched scopes, and invalid timestamps, and map a
  supported `SessionClosed` event's `emitted_at` value into the exactly-once
  coordinator without mutating protocol/core state.

## Required Gates

Run after each retrofit step:

- `rtk dart run melos run source-text`
- `rtk dart run melos run boundary-check`
- `rtk dart run melos run dependency-audit`
- `rtk dart run melos run analyze`
- `rtk dart run melos run test`
- `rtk git diff --check`

## Next Implementation Targets

1. Validate Android and Windows secure-key persistence and capture behavior at
   runtime, including an Android real-device pass and operator-owned release
   signing.
2. Add the remaining other-platform capture, local-network, and transport
   implementations behind the existing generic method-channel contracts.
3. Continue production hardening items recorded in `docs/PRODUCTION_READINESS.md` without crossing locked package boundaries.

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
  duplicate close signals cannot repeat policy or storage work.
- Mirrored app session-close event adapters now ignore non-close events, reject
  unsupported versions, mismatched scopes, and invalid timestamps, and map a
  supported `SessionClosed` event's `emitted_at` value into the exactly-once
  coordinator without mutating protocol/core state.
- Mirrored `AppTableSessionRuntime` owners now bind table/session/protocol
  scope, delegate ordered protocol events to `peerdeal_core`, and commit a
  `SessionClosed` projection only after the retention adapter succeeds.
  Production source provisioning and durable database/platform persistence
  remain open.
- Protocol now exposes a bounded canonical `EventEnvelopeCodec`; mirrored app
  transport handlers use it behind `peerdeal_network` receiver validation,
  enforce frame/event session identity, and reject runtime projection failures.
- Loaded app transport sessions can now create mirrored bounded source
  controllers that validate scope, serialize polls, and stop cleanly across
  route lifecycle changes. Native live transport implementation and
  production source provisioning remain open.
- Both app shells expose optional source injection through their runtime and
  table route; the route mount owns source start/replacement/disposal. A real
  production caller still must provision a loaded native session and handler.
- Mirrored app transport provisioners now perform that composition through one
  fail-closed load boundary, returning the bound handler, native session, and
  route-ready source while keeping platform transport generic.

## Recent T18 Changes

- Added the generic `AppStorageDirectoryBridge` and bounded method-channel
  contract for app-support directory discovery.
- Android now returns private no-backup app storage and Windows now returns
  `LocalAppData`; neither host owns recovery or receipt policy.
- Both app shells prefer the explicit `PEERDEAL_RECOVERY_ROOT` override and
  otherwise construct the app-owned JSON recovery store below native app-support
  storage. Missing or malformed native results fail closed.
- Focused Dart coverage passes and the Windows debug host build passes. Android
  host/runtime persistence, release-signing, and device/profile validation
  remain required; the current Android Gradle configuration also stops on an
  NDK installation missing `source.properties`.

## Recent T19 Changes

- Both production app entrypoints now construct the app with the existing
  app-owned `AppNativeReadinessLoader.methodChannel()` boundary.
- Missing or unavailable generic native capabilities now reach the default home
  as an explicit unavailable readiness state instead of leaving production
  entrypoint readiness inactive.
- Explicit runtime/widget injection remains available for focused tests and
  host integrations; no native transport or platform implementation was added.

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

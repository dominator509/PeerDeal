# Handoff

Generated: 2026-08-09

## Current Work

Trinity baseline retrofit T1 is complete, CI/dependency hardening is complete,
the T4 Android plus Windows secure-key and capture-enforcement host slices are
implemented, T19 production entrypoint native-readiness activation is wired,
and T20 local-network endpoint projection, T21 Android secure-storage bound
hardening, T22 protocol-native command validation, T23 removal of the
duplicate starter core API, and T24 variant-to-core Hold'em event projection
are implemented on branch
`retrofit/baseline-v1` from backup tag
`pre-retrofit-20260613T075234Z`.

## What Changed

- Added normalized retrofit bundle source under `spec/baseline_v1_retrofit/`.
- Added bundle provenance in `spec/BUNDLE_SOURCE_MANIFEST.md`.
- Added root bootstrap, inventory, queue, project state, handoff, and decision artifacts.
- Aligned CI's global Melos activation with the locked workspace version, 8.2.2.
- Upgraded the workspace Melos constraint and lockfile to 8.2.2, including compatible transitive refreshes.
- Added the generated mobile Android host and registered the generic secure-key method channel.
- Added Keystore AES-GCM encrypted, namespace-bound, durable generic key-record storage.
- Removed the generated release debug-signing fallback; operator-owned Android signing is environment-driven and fail-closed.
- Added the generated Windows desktop host and generic Credential Manager-backed
  secure-key channel with bounded versioned records.
- Added the generic app-support directory method-channel contract. Android
  returns private no-backup app storage and Windows returns `LocalAppData`.
- Both app shells now prefer `PEERDEAL_RECOVERY_ROOT` and otherwise use the
  native app-support directory to construct their app-owned JSON recovery store.
  Native lookup and root validation fail closed.
- Both production app entrypoints now install the app-owned method-channel native
  readiness loader. Missing host capabilities render as unavailable and do not
  silently bypass readiness-gated production routes.
- Both app shells now preserve validated host and optional port metadata from
  documented native `peer@host[:port]` discovery values on existing network
  bootstrap candidates; malformed endpoint locations are dropped without
  exposing raw values, and bare peer IDs remain supported.
- Android secure-key persistence now bounds the actual UTF-8 encoded envelope
  bytes on both reads and writes; the release manifest declares `INTERNET` for
  the existing native-network channel boundary without claiming live transport.
- Core command validation now rejects unsupported protocol catalog entries and
  padded or control-character envelope identities before command acceptance.
- The public `peerdeal_core` barrel no longer exports unused local `CoreCommand`
  or `CoreEvent` models, duplicate reducer contracts, or starter validators;
  protocol-native core models and reducer paths are now the sole package API.
- Added a scope-validated, idempotent recovery-persistence wipe operation for
  in-memory and JSON stores, including cleanup of matching interrupted-write
  temp files without crossing recovery scopes.
- Added mirrored app retention coordinators that validate scope, evaluate
  close-time policy with explicit timestamps, invoke wipe only when due, and
  fail closed on policy or storage exceptions.
- Added mirrored per-session close coordinators that bind scope and policy,
  cache the first retention outcome, and prevent duplicate close signals from
  repeating policy or storage work.
- Added mirrored session-close event adapters that ignore unrelated events,
  reject unsupported or mismatched `SessionClosed` envelopes, and map the
  protocol `emitted_at` timestamp into the app retention boundary.
- Added mirrored `AppTableSessionRuntime` owners that bind table/session/
  protocol scope, delegate event projection to `peerdeal_core`, and accept
  `SessionClosed` only after the app retention adapter succeeds. Failed close
  retention leaves the projected runtime state unchanged.
- Added the protocol-owned bounded `EventEnvelopeCodec` and mirrored app
  `AppTableSessionTransportHandler`s. Validating transport receivers can now
  decode canonical event bytes, bind frame/session identity, and reject events
  that the app runtime cannot commit.
- Added mirrored app-owned `AppTableSessionTransportSource` controllers.
  Loaded native transport sessions can now create exact-scope polling sources
  with bounded intervals, serialized polls, explicit start/stop/dispose state,
  and scrubbed bounded warnings.
- Added mirrored `AppTableSessionTransportSourceMount` route lifecycle owners
  and optional runtime injection through both app shells. Table routes now
  start an injected source and dispose it on source replacement or route exit.
- Added mirrored `AppTableSessionTransportProvisioner` factories. App callers
  can now bind a table runtime to its event handler, load the validated native
  transport session, and receive a route-ready source through one fail-closed
  app boundary.
- Added the generic capture action contract and mirrored app coordinator
  lifecycle, including serialized native block/release and fail-closed visual
  obscuring when blocking cannot be confirmed.
- Added Android `FLAG_SECURE` and Windows `SetWindowDisplayAffinity` host
  implementations behind the existing capture channel.
- Hardened the Windows host to gate capture exclusion on Windows 10 build
  19041 or newer and to reject unsafe Credential Manager blob shapes before
  envelope decoding.
- Receipt route disposal now releases native capture blocking.
- Did not modify protocol/core package code, secrets, or locked package boundaries.

## Review Notes

- Bundle text copied under `spec/` is normalized for repository source-text gates; original hashes are recorded in the manifest.
- Remaining production software gaps are tracked in `HANDOFF_QUEUE.md` and existing production-readiness docs.
- Android and Windows host work is available for runtime persistence and
  capture validation. Remaining native gaps are other-platform capture,
  local-network discovery, native peer transport implementation and platform
  source provisioning, production database persistence, other-platform
  storage, and non-demo production navigation/UI.

- Windows native hardening was compiled and smoke-tested after the capture and
  credential-shape checks; runtime OS/profile validation remains operator-owned.
- The Windows release host rebuild passed after T21. The Android release build
  still stops during Gradle configuration because the configured NDK is missing
  `source.properties`; no Android APK or host compile result is claimed.
- The T18 Android Gradle compile could not configure the app because the
  configured NDK is missing `source.properties`; no Android APK or host compile
  result is claimed until that installation is repaired.

## Gate Results

- `rtk dart run melos run source-text`: passed.
- `rtk dart run melos run boundary-check`: passed.
- `rtk dart run melos run dependency-audit`: passed; reported 0 actionable upgrades and 9 newer packages blocked by the current toolchain.
- `rtk dart run melos run analyze`: passed.
- `rtk dart run melos run test`: passed.
- `rtk git diff --check`: passed.
- T18 focused native app-storage bridge tests: passed, 49 tests.
- T18 focused mobile recovery factory tests: passed, 11 tests.
- T18 focused desktop recovery factory tests: passed, 12 tests.
- T18 `flutter build windows --debug --no-pub`: passed.
- T18 full repository `analyze`, `boundary-check`, `source-text`, `test`, and
  `dependency-audit` gates: passed; dependency audit reports 0 actionable
  upgrades.
- T19 mobile and desktop production-entrypoint focused tests: passed; the full
  repository `analyze`, `boundary-check`, `source-text`, `test`, and
  `dependency-audit` gates also passed.
- T20 mobile and desktop native bootstrap endpoint projection tests: passed,
  12 tests per app.
- T21 Android manifest contract test: passed.
- T21 Windows release host build: passed.
- T21 Android release APK build: not completed; Gradle stopped before source
  compilation because `C:\Users\domin\AppData\Local\Android\sdk\ndk\28.2.13676358\source.properties` is missing.
- T21 full repository `analyze`, `boundary-check`, `source-text`, `test`, and
  `dependency-audit` gates: passed; dependency audit reports 0 actionable
  upgrades.
- T22 focused `peerdeal_core` validation tests: passed, including unsupported
  command/protocol rejection and padded/control-character identity rejection.
- T23 focused protocol-native `peerdeal_core` suite: passed after removing the
  unused local-envelope reducer and validator seams.
- T24 focused `peerdeal_variants` lifecycle-to-core projection suite: passed,
  including accepted action/showdown/settlement chains and transactional
  rollback when core rejects an event.
- `flutter test --no-pub` in `apps/peerdeal_desktop`: passed.
- `flutter build windows --debug --no-pub`: passed.
- Windows host smoke launch: stayed alive for five seconds and stopped cleanly.
- Windows host rebuild after secure-key and capture hardening: passed.
- Focused native bridge and mirrored capture coordinator tests: passed.
- Focused recovery persistence wipe tests and mirrored app-shell regression
  tests: passed.
- Full repository gate/test run after the recovery wipe contract extension:
  passed.
- Mobile and desktop retention coordinator focused tests: passed.
- Mobile and desktop exactly-once session-close coordinator focused tests:
  passed.
- Mobile and desktop session-close event adapter focused tests: passed.
- Mobile and desktop `AppTableSessionRuntime` focused tests: passed.
- Mobile and desktop transport-source lifecycle and loaded-session composition
  focused tests: passed.
- Mobile and desktop route-level source mount and table-route focused tests:
  passed.
- Mobile and desktop transport provisioner and native-session composition
  focused tests: passed.
- Full repository gate/test run after retention wipe orchestration: passed.
- Full repository gate/test run after app session-runtime wiring: passed.
- Android debug APK build: not completed; both the initial and post-cache-cleanup
  attempts failed while installing NDK `28.2.13676358` because the volume
  exhausted during extraction. Flutter doctor itself is green; Kotlin/APK and
  Android-device validation remain open.

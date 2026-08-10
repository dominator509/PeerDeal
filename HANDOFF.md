# Handoff

Generated: 2026-08-09

## Current Work

Trinity baseline retrofit T1 is complete, CI/dependency hardening is complete,
and the T4 Android plus Windows secure-key and capture-enforcement host slices
are implemented on branch `retrofit/baseline-v1` from backup tag
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
  local-network discovery, native peer transport implementation and
  production source provisioning, durable platform persistence, and
  non-Windows platform storage.

- Windows native hardening was compiled and smoke-tested after the capture and
  credential-shape checks; runtime OS/profile validation remains operator-owned.

## Gate Results

- `rtk dart run melos run source-text`: passed.
- `rtk dart run melos run boundary-check`: passed.
- `rtk dart run melos run dependency-audit`: passed; reported 0 actionable upgrades and 9 newer packages blocked by the current toolchain.
- `rtk dart run melos run analyze`: passed.
- `rtk dart run melos run test`: passed.
- `rtk git diff --check`: passed.
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
- Full repository gate/test run after retention wipe orchestration: passed.
- Full repository gate/test run after app session-runtime wiring: passed.
- Android debug APK build: not completed; both the initial and post-cache-cleanup
  attempts failed while installing NDK `28.2.13676358` because the volume
  exhausted during extraction. Flutter doctor itself is green; Kotlin/APK and
  Android-device validation remain open.

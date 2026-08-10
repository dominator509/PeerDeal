# Project State

Generated: 2026-08-10

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

## Recent T20 Changes

- Both app-owned local-network bootstrap loaders now parse the documented
  `peer@host[:port]` discovery shape and project validated host/port metadata
  onto the existing `BootstrapCandidate` model.
- Bare peer IDs remain valid, while malformed, sensitive, or out-of-range
  endpoint locations are dropped before network bootstrap candidates are
  exposed.
- This retains discovery facts for future platform transport provisioning but
  does not claim that native peer transport is implemented.

## Recent T21 Changes

- Android secure-key persistence now checks the actual UTF-8 encoded envelope
  byte count on both read and write; the previous write guard measured JSON
  field count rather than encoded size.
- The release Android manifest now declares `INTERNET` for the existing native
  network boundary. No live local-network discovery or peer transport is
  claimed by this permission-only change.
- The Windows release host rebuild and all repository gates passed. Android
  APK compilation remains blocked before source compilation by the malformed
  local NDK installation missing `source.properties`.

## Recent T22 Changes

- `CoreCommandValidator` now uses the protocol catalog to reject unsupported
  command artifacts and protocol versions before command acceptance.
- Command, scope, timestamp, actor, and optional table/session/hand identity
  strings now reject leading or trailing whitespace and ASCII control
  characters when non-blank.
- Existing blank-field error ordering and fixture-backed command acceptance
  remain unchanged; the focused core suite passes.

## Recent T23 Changes

- Removed the unused starter local `CoreCommand`/`CoreEvent` models and their
  duplicate reducer, action-validator, orchestrator, and application-result
  contracts.
- The `peerdeal_core` public barrel now exposes the protocol-native
  `CommandEnvelope`/`EventEnvelope` path through the core reducer and validator,
  eliminating two competing core truths.
- The focused protocol-native core suite remains green after the migration.

## Recent T24 Changes

- Added `HoldemEventCursor` in `peerdeal_variants` for immutable contiguous
  event sequencing, caller-owned event IDs/timestamps, and deterministic
  canonical event hashes.
- Added `HoldemCoreProjectionAdapter`, which runs the existing Hold'em action,
  street, showdown, and settlement coordinators, emits catalog-approved
  protocol events, and applies each batch transactionally through
  `peerdeal_core.CoreReducer`.
- Invalid variant actions and core projection failures preserve the original
  Hold'em state, core state, cursor, and event list. App/session callers now
  have a mirrored app-owned route seam for adopting this adapter; the actual
  product route and state source remain app-owned.

## Recent T25 Changes

- Added mirrored app-owned `AppHoldemTableSessionRuntime` owners in the mobile
  and desktop shells. They expose start, action, showdown, and settlement
  operations without moving variant rules into app UI or core.
- Added atomic non-retention event-batch preflight/commit to both
  `AppTableSessionRuntime` owners. App core state, Hold'em state, and the event
  cursor advance only after the full adapter-produced batch is accepted.

## Recent T26 Changes

- `HoldemEventCursor.accept` now verifies remote event scope, sequence, hash
  chain, catalog support, and canonical event hash before advancing.
- Added the public variant-owned `HoldemEventReducer`. It reconstructs
  adapter-produced action/street state and public showdown/settlement lifecycle
  state without attempting to evaluate private showdown cards.
- Both app-owned Hold'em runtimes now expose `applyRemoteEvent`, preflighting
  cursor and variant state before committing through `AppTableSessionRuntime`;
  rejected core projections leave all app and variant state unchanged.
- Both transport handlers and provisioners can opt into the Hold'em runtime,
  while the existing generic core-only path remains available for non-variant
  sessions.

## Recent T27 Changes

- Added mirrored app-owned `AppHoldemTableSessionRoute` composition. It accepts
  a validated Hold'em runtime, provisions the existing transport/source seam,
  owns source lifecycle, and refreshes the supplied surface after accepted
  inbound events.
- Added mirrored `AppHoldemProjectionTransportPublisher`, which canonicalizes
  accepted Hold'em projections into validated network frames and reports
  partial sends without rerunning variant rules.

## Recent T28 Changes

- Added mirrored `AppHoldemProductionRouteRegistration` owners. They bind a
  validated Hold'em runtime, peer identity, surface builder, and optional
  native transport seam into one typed app-shell registration.
- Both app shells now merge that registration into the existing validated
  production route map, auto-register its navigation entry, and require native
  readiness for the route. Missing readiness fails closed before the route
  surface mounts.

## Recent T29 Changes

- Added mirrored `AppHoldemProductionTableSurface` owners. They render bounded
  Hold'em projection state and expose local controls only when the configured
  seat, betting phase, native transport, and canonical publisher are ready.
- Added default route-registration factories that mount the production surface
  without making UI or variant code responsible for route validation.
- Projection publishing now accepts an event offset, and the production
  surface resumes partial sends from the first unsent event instead of replaying
  an already-delivered prefix.

## Recent T30 Changes

- Android and Windows hosts now implement the existing generic native transport
  channel with bounded UDP multicast byte-frame envelopes, receive queues, and
  session/recipient filtering.
- Both hosts validate frame identity, sequence, payload size, and byte values;
  socket ownership and receiver teardown are tied to the Flutter host lifecycle.
- The pinned Android NDK was repaired and the mobile debug APK plus Windows
  debug host now compile through the native transport handlers.

## Recent T31 Changes

- Added mirrored app-owned `AppHoldemProductionSessionFactory` seams. They
  compose the existing table-session runtime, Hold'em runtime, and default
  production surface from injected canonical table state, hand state, event
  cursor, close-retention adapter, and local/remote peer identity.
- The factory rejects unsafe route metadata, peer identity reuse, missing local
  seats, invalid transport polling intervals, and cursor/session composition
  failures before a production route is exposed. It does not derive product
  IDs, persistence, or game state.

## Recent T32 Changes

- Added mirrored app-owned `AppHoldemProductionSessionSource` and
  `AppHoldemProductionSessionBootstrap` contracts. A product source now loads
  canonical table/hand state, event cursor, close-retention adapter, and local
  identity for a resolved invite; the bootstrap validates table/session/
  protocol correlation before invoking the T31 factory.
- Successful first-join and rejoin outcomes now carry the validated
  `ResolvedInvite`, allowing product orchestration to hand the joined identity
  to the production session bootstrap without deriving IDs from demo or Game
  File data.

## Recent T33 Changes

- Hardened the Android native transport method-call executor so calls received
  during or after teardown resolve with bounded fail-closed payloads instead of
  throwing on a rejected executor or abandoning accepted work.
- Hardened Windows native transport initialization so socket, multicast
  membership, TTL, and Winsock state are cleaned up on every partial setup
  failure before capability can report availability.
- Rebuilt the Android debug APK and Windows debug host after the native changes;
  device persistence, capture, and cross-device reachability remain runtime
  validation work.

## Recent T34 Changes

- Added a bounded five-second default deadline to generic secure-key
  method-channel load, save, and delete calls, returning stable fail-closed
  results when the native response does not arrive.
- Added focused bridge coverage for load and save timeout behavior. Native
  device persistence, key-store availability, and receipt runtime validation
  remain external checks.
- Mirrored receipt routes now reject unavailable export artifacts before native
  key verification, preventing failed export paths from opening an unnecessary
  secure-storage call.
- Final T34 validation passed for the mobile and desktop full Flutter suites,
  all serialized Melos gates, and `git diff --check`; dependency audit reports
  zero actionable upgrades.

## Recent T35 Changes

- Added a bounded five-second default deadline to generic native transport
  method-channel capability, send, and receive calls, returning stable
  fail-closed results when platform calls do not complete.
- Added caller cancellation for default transport calls so app-owned table
  route replacement and disposal cancel in-flight operations and their local
  deadline timers.
- Added focused timeout/cancellation coverage for all three transport
  operations and non-positive timeout validation. Runtime device, firewall,
  cross-device reachability, and other-platform transport remain external
  checks.

## Recent T36 Changes

- Added a bounded five-second default deadline to generic local-network
  method-channel capability and discovery calls, returning stable fail-closed
  facts when platform calls do not complete.
- Added caller cancellation to the default app bootstrap loader and table route
  replacement/disposal lifecycle, so in-flight local-network calls and local
  deadline timers do not outlive their route.
- Added focused timeout, cancellation, constructor-validation, and mirrored
  route lifecycle coverage. Real platform discovery, permission behavior,
  device/network reachability, and other-platform implementations remain
  external checks.

## Recent T37 Changes

- Hardened Android native multicast transport teardown against receiver-setup
  races. Socket and multicast-lock publication is now serialized with close,
  partial setup resources are released, and queued frames are cleared during
  teardown.
- `rtk flutter build apk --debug --no-pub` passed. The generic transport
  channel payload and app/native package boundaries are unchanged.
- Android device/network reachability, firewall behavior, runtime persistence,
  release signing, and other-platform implementations remain open.

## Recent T38 Changes

- Hardened Windows native multicast transport socket ownership across Flutter
  method calls, receive-thread startup, and teardown. Shutdown now invalidates
  the handle before closing and joining the receiver, and clears queued frames.
- `rtk flutter test --no-pub test/transport` passed with 45 tests.
- `rtk flutter build windows --debug --no-pub` passed, and the built host stayed
  alive for the bounded five-second smoke launch before clean termination.
- Windows profile/network reachability, Android device validation, runtime
  persistence/capture, release signing, and other-platform implementations
  remain open.

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
   implementations behind the existing generic method-channel contracts; the
   Android/Windows transport is now host-backed but still needs device/network
   reachability validation.
3. Supply the concrete product implementation of
   `AppHoldemProductionSessionSource` and invoke
   `AppHoldemProductionSessionBootstrap` from the real session/state and local
   identity flow; native peer transport device/network validation, and final UX
   validation remain separate.
4. Continue production hardening items recorded in `docs/PRODUCTION_READINESS.md`
   without crossing locked package boundaries.

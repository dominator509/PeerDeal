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

## Recent T39 Changes

- Hardened the Android secure-key method-channel worker against Flutter engine
  teardown. Queued storage work now fails closed after handler closure, and
  late main-looper results return unavailable mutations/snapshots instead of
  exposing native key material.
- `rtk flutter test --no-pub` focused mobile secure-key/receipt and Android
  manifest tests passed with 40 tests.
- `rtk flutter build apk --debug --no-pub` passed.
- Android device persistence/capture behavior, release signing, and other
  platform implementations remain open for operator/device validation.

## Recent T40 Changes

- Windows secure-key and capture method-channel hosts now unregister their
  handlers during destruction, preventing shutdown dispatch from targeting
  released native channel owners.
- `rtk flutter test --no-pub` focused desktop receipt, secure-key loader, and
  capture coordinator tests passed with 21 tests.
- `rtk flutter build windows --debug --no-pub` passed.
- Windows runtime/profile validation, Android device validation, release
  signing, and other-platform implementations remain open.

## Recent T48 Changes

- Added mirrored `AppHoldemProductionSessionConfiguration.fromSource(...)`
  configuration objects. Each app runtime derives one stable source-backed
  route registration and reuses it for production route merging, native
  readiness, and the default join handoff.
- Supplying both the existing explicit route registration and the new
  configuration fails closed with `StateError`; the configuration does not own
  product state, identity, persistence, or native transport. Focused mobile and
  desktop app-shell suites passed with 78 tests each. The Android debug APK and
  Windows debug host builds passed, as did the full analyze, boundary,
  source-text, serialized test, dependency audit, and diff-check gates.
  Dependency audit reports 0 actionable upgrades and 11 newer versions below
  the current toolchain ceiling.

## Recent T49 Changes

- Android release Gradle tasks now fail closed before artifact assembly when
  operator-owned signing values are missing, partial, padded, control-bearing,
  or backed by a nonexistent keystore. Release output cannot silently fall back
  to debug signing or remain unsigned; unsigned local validation uses debug
  builds instead.
- `flutter build apk --release --no-pub` was verified to stop with the stable
  signing configuration error, while `flutter build apk --debug --no-pub`
  passed. Operator signing credentials and Android device/profile validation
  remain external.

## Recent T50 Changes

- Shared app-shell action controls now expose their visible label and tap action
  through semantics, while info rows merge each fact into one readable semantic
  value and stack label/value content below 360px.
- Mirrored production Hold'em surfaces now render human-readable phase and
  betting-round labels, suppress the misleading idle `Seat 0` display, and mark
  the seats section as a semantic header. Focused UI-kit and mobile/desktop
  production-table suites passed; Android debug APK and Windows debug host
  builds also passed. Final visual/device UX validation remains external.

## Recent T51 Changes

- Shared app-shell action controls now own a focus node, expose focusable
  semantics, request focus on pointer activation, and bind Enter, numpad Enter,
  and Space to the same action callback. The focus outline uses a stable border
  width so keyboard navigation does not shift layout. The focused UI-kit suite
  passed with 4 tests; final device/accessibility validation remains external.

## Recent T52 Changes

- Shared app-shell action controls now enforce a 48 logical-pixel minimum
  interactive height without changing their public API or focus outline
  footprint. The focused UI-kit suite passed with 4 tests; device, text-scale,
  and final accessibility validation remain external.

## Recent T53 Changes

- Mirrored production Hold'em table surfaces now use the configured local seat
  for Fold, Call/Check, and All-in actions. Focused mobile and desktop route
  suites passed with 8 tests each, including canonical outbound event
  attribution for local seat 1.

## Recent T54 Changes

- `peerdeal_core` now provides strict `TableState.fromJson(...)` hydration that
  mirrors the existing `toJson()` fields, rejects unknown phases and malformed
  primitive values, and preserves only string-keyed metadata. The focused core
  invariant/model suite passed with 13 tests; full product source and
  durable product persistence wiring remain integration-owned.

## Recent T55 Changes

- `peerdeal_variants` now provides strict `HoldemHandState.toJson/fromJson` and
  `HoldemSeatState.toJson/fromJson` coverage for enum, nested seat, collection,
  nullable, and primitive fields. The focused variant persistence suite passed
  with 3 tests; product source, database wiring, and local identity remain
  integration-owned.

## Recent T56 Changes

- `peerdeal_variants` now provides strict `HoldemEventCursor.toJson/fromJson`
  coverage for scope, sequence, hash-chain, actor, and last-event state. The
  parser requires caller-owned event-id, timestamp, and optional hash factories;
  focused cursor persistence tests passed with 3 tests. Product persistence and
  local identity wiring remain integration-owned.

## Recent T57 Changes

- `peerdeal_variants` now provides `HoldemStateSnapshot`, composing strict
  table, hand, and cursor JSON hydration with matching scope and snapshot
  sequence checks.
- Mirrored mobile and desktop `AppPersistedHoldemProductionSessionSource`
  adapters load that typed snapshot from the existing recovery store and pass
  it through a caller-owned input factory. Missing, unsupported, mismatched,
  or unreplayed suffix data fails closed; product database wiring, local
  identity, and event replay remain integration-owned. Focused mobile and
  desktop tests passed with 4 tests each.

## Recent T58 Changes

- `HoldemCoreProjectionAdapter.replay(...)` now applies persisted suffix events
  atomically. Cursor acceptance verifies scope, sequence, catalog support, and
  event hashes; `CoreReducer` applies universal table truth; and
  `HoldemEventReducer` applies hand-scoped variant truth.
- Mirrored persisted production sources now use that replay path. Valid
  recovery suffixes advance the typed snapshot before input-factory mapping,
  while tampered or unsupported events fail closed with no partial state.
  Focused variant replay tests passed with 2 tests and mobile/desktop source
  tests passed with 5 tests each. Product database wiring and local identity
  remain integration-owned.

## Recent T59 Changes

- Mirrored mobile and desktop app shells now provide
  `NativeLocalPeerIdentityLoader`, `NativeLocalPeerIdentityWriter`, and
  `NativeLocalPeerIdentityProvisioner` over the existing generic secure-key
  bridge. The app boundary owns the `peerdeal.identity` namespace and
  `peer_identity`/`opaque-peer-id` record mapping; the native bridge remains
  generic.
- One active persisted identity is reused, missing identity is provisioned
  with a secure-random default, and unavailable, invalid, inactive, or
  ambiguous records fail closed. Focused mobile and desktop tests passed with
  5 tests each. Wiring the identity into the concrete production source and
  route policy remains integration-owned.

## Recent T60 Changes

- Mirrored app shells now expose
  `AppPersistedHoldemProductionSessionSource.fromProvisionedLocalIdentity(...)`
  and `AppPersistedHoldemProductionSessionRoutePolicy`. The composition edge
  provisions or reuses the local identity, maps it to `localPeerId`, and passes
  caller-owned route, remote-peer, local-seat, and close-event policy into the
  existing typed persisted source.
- Focused mobile and desktop persisted-source tests passed with 6 tests each.
  Concrete product database selection, remote-peer discovery, native runtime
  validation, and release credentials remain outside this app-owned factory.

## Recent T61 Changes

- Mirrored `NativeLocalPeerIdentityProvisioner` implementations now share one
  in-flight load/generate/save operation across concurrent first-use callers.
  This prevents two app tasks from generating and overwriting different local
  peer IDs. The in-flight guard clears on success or failure so transient native
  storage failures remain retryable.
- Focused mobile and desktop identity suites passed with 6 tests each,
  including overlapping provisioning calls. Cross-process identity locking and
  Android/Windows runtime persistence validation remain external.

## Recent T62 Changes

- Mirrored local identity provisioners now reload native storage after a
  generated identity save and require the persisted peer ID to match exactly.
  Save success without matching read-back fails closed, preventing the app from
  continuing with an identity that was replaced or not durably visible.
- Focused mobile and desktop identity suites passed with 7 tests each,
  including competing-writer detection. Cross-process locking and real-device
  persistence validation remain external.

## Recent T63 Changes

- Mirrored accepted first-join outcomes now carry a typed
  `JoinFlowSessionContext` only when bootstrap supplies a selected reachable
  peer and governance supplies a positive assigned seat.
- App shells now prefer the context-aware production handoff when configured;
  the existing invite-only callback remains available for legacy sources.
- Persisted Hold'em sources can consume the typed context and apply its remote
  peer and local seat while retaining strict snapshot scope and recovery replay
  checks.
- Accepted rejoin governance results can now supply the remote peer binding and
  assigned seat for the same typed context; missing binding fails closed.
- Concrete product database/source provisioning, native transport reachability,
  and device validation remain external integration work.

## Recent T64 Changes

- Added the optional app-owned `GovernanceCommitResult.assignedPeerId` field.
  Rejoin session contexts use this governance-owned binding, while first joins
  continue to use the bootstrap-selected peer.
- Mirrored orchestrator and route tests prove accepted rejoin handoff and
  fail-closed behavior when governance does not return a peer.

## Recent T65 Changes

- Added mirrored async
  `AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(...)`.
  It composes the existing persisted Hold'em source, native local identity
  provisioner, recovery store, route policy, and event factories into one
  stable bootstrap-route configuration.
- Focused mobile and desktop persisted-session suites passed with 8 tests each;
  app analyzers reported no issues. This remains recovery-backed composition,
  not a claim that a product database or product route policy exists.

## Recent T66 Changes

- Mirrored configuration factories reject non-positive source-load timeouts
  before route assembly or native local-identity provisioning.
- Focused mobile and desktop persisted-session suites passed with 9 tests each,
  including the regression proving invalid configuration performs no secure-key
  mutation. Product database/state provisioning and runtime validation remain
  integration-owned.

## Recent T67 Changes

- Mirrored persisted Hold'em route policies now validate route metadata, remote
  peer identity, and positive local seat before native local-identity
  provisioning.
- Focused mobile and desktop persisted-session suites passed with 10 tests each,
  including the invalid-policy no-secure-key-mutation regression. Product
  database/state provisioning and runtime validation remain integration-owned.

## Recent T68 Changes

- Production persisted-session configuration now defers native local-identity
  provisioning until the invite-scoped snapshot has passed validation and any
  recovery suffix has replayed successfully.
- Missing or rejected persisted state causes no secure-key mutation. Focused
  mobile and desktop persisted-session suites passed with 12 tests each.

## Recent T69 Changes

- Persisted invite and session-context loads now propagate route cancellation
  through recovery access and lazy identity provisioning boundaries.
- Cancelled loads fail closed before work begins. Focused mobile and desktop
  persisted-session suites passed with 13 tests each, including the
  no-secure-key-mutation regression.

## Recent T47 Changes

- Added mirrored `AppHoldemProductionSessionBootstrapRouteRegistration.fromSource(...)`
  factories. They assemble an injected product source with the existing
  bootstrap, optional production session factory, and positive load timeout at
  one app boundary before route registration.
- The factory does not create table state, Hold'em state, local identity,
  persistence, or native transport; those remain owned by the product source
  and its injected dependencies. Focused mobile and desktop app-shell suites
  passed with 77 tests each. Android debug APK and Windows debug host builds
  passed, as did the full analyze, boundary, source-text, serialized test,
  dependency audit, and diff-check gates; dependency audit reports 0 actionable
  upgrades and 11 newer versions blocked by the current toolchain.

## Recent T46 Changes

- Added mirrored `AppHoldemProductionSessionBootstrapRouteRegistration`
  descriptors. Supplying one to either app runtime now mounts the existing
  bootstrap route, merges it into the production route map, and includes its
  path in the native-readiness gate.
- When no explicit `JoinFlowReadyHandler` is supplied, accepted joined/rejoined
  outcomes navigate to the registered bootstrap path with the identity-safe
  `ResolvedInvite`. The cached callback avoids repeated navigation when the app
  rebuilds; an explicit handler still takes precedence.
- Focused mobile and desktop app-shell suites passed with 77 tests each. The
  registration remains route plumbing only; concrete product source hydration,
  local identity, durable persistence, native/device validation, and final UX
  remain open. Full analyze, boundary, source-text, serialized test, dependency
  audit, and diff-check gates also passed; dependency audit reports 0 actionable
  upgrades and 11 newer versions blocked by the current toolchain.

## Recent T45 Changes

- Mirrored `AppHoldemProductionSessionSource` contracts now accept an optional
  cancellation signal. The bootstrap races source completion, cancellation,
  and the positive five-second-default timeout, cleaning up its deadline timer
  when any outcome wins.
- Mounted bootstrap routes complete the cancellation signal when replaced or
  disposed, so stale product hydration is no longer awaited by the UI. The
  concrete product source still owns cancellation of its underlying persistence
  or network operation.
- Focused mobile and desktop bootstrap plus route tests passed with 13 tests
  each. Full analyze, boundary, source-text, serialized test, dependency audit,
  and diff-check gates passed; product source hydration, local identity,
  native/device validation, durable database persistence, and final UX remain
  open.

## Recent T44 Changes

- Mirrored `AppHoldemProductionSessionBootstrap` owners now enforce a positive
  configurable source-load timeout with a five-second default. Their mounted
  route adapters render a loading surface while product state is pending and
  fail closed after timeout or source failure rather than presenting a pending
  route as immediately unavailable.
- Focused mobile and desktop bootstrap plus route tests passed with 10 tests
  each. Product source hydration, local identity, native/device validation,
  durable database persistence, and final UX remain open.

## Recent T43 Changes

- Mounted join routes now preserve an identity-safe `ResolvedInvite` only for
  the authoritative joined/rejoined state and status pairs. An optional
  `JoinFlowReadyHandler` runs post-frame after successful join/rejoin and is
  wired through both app runtime objects, allowing product callers to push the
  T41 route adapter with `RouteSettings.arguments`.
- Rejected outcomes, malformed invite identities, stale async outcomes, and
  handler exceptions do not trigger production handoff. Focused mobile and
  desktop join/app-shell suites passed with 92 tests each.

## Recent T42 Changes

- Added an optional opaque route-argument payload to mirrored
  `PeerDealAppNavigationEntry` values. Default app-home production navigation
  now forwards that payload through `RouteSettings.arguments`; the shell does
  not interpret or persist it, so the destination retains type and identity
  validation.
- Focused mobile and desktop app-shell tests passed with 74 tests each.
  Concrete product source hydration, local identity, device/runtime
  validation, and final product navigation/UX validation remain open.

## Recent T41 Changes

- Added mirrored app-owned `AppHoldemProductionSessionBootstrapRoute` adapters.
  Product route maps can pass a real `ResolvedInvite` through route arguments,
  invoke the existing session bootstrap, and mount its validated production
  route without deriving state or identity from demo data.
- Missing invite arguments, product-source failures, and a mismatch between
  the requested route path and the bootstrapped route path fail closed through
  the existing route-unavailable surface.
- Focused mobile and desktop bootstrap-route tests passed with four tests each.
  Durable state hydration, local identity, device/runtime validation, and
  final product navigation/UX validation remained open after the route mount;
  T42 now supplies only the generic app-shell argument handoff.

## Recent T70 Changes

- Generic capture protection method-channel capability and blocking calls now
  use a bounded five-second default deadline and return stable fail-closed
  timeout results.
- Non-positive capture bridge timeout configuration is rejected before any
  platform call. Runtime Android/Windows capture behavior and other-platform
  implementations remain external validation work.

## Recent T71 Changes

- Generic secure-key method-channel load/save/delete calls now support additive
  per-call cancellation and return stable unavailable/failure results when the
  caller lifecycle ends before the bounded deadline.
- Mirrored app local-identity loaders, writers, provisioners, and persisted
  Hold'em sources forward route cancellation into the native-backed identity
  path without changing the base secure-storage interface.
- A cancellation stops the Dart wait; a host mutation already dispatched cannot
  be withdrawn by Dart and remains an atomic/idempotent host responsibility.

## Recent T72 Changes

- Receipt key-ring loading, artifact verification, and safe-surface presentation
  now carry an additive route-cancellation capability through both app shells.
- Mounted receipt routes complete that cancellation signal on replacement and
  disposal, preventing pending native-backed verification from outliving the
  route; base bridge implementations remain compatible.
- Focused mirrored receipt route suites prove cancellation reaches the native
  secure-key seam.

## Recent T73 Changes

- Mirrored app transport provisioners now fail closed when route cancellation
  wins during injected native session loading.
- Transport session factories pass route cancellation into mounted sources;
  source disposal and route cancellation cancel the visible poll wait while
  the underlying drain remains registered until settlement, preventing
  overlapping native drains.
- Focused mobile and desktop transport source/provisioner suites passed.

## Recent T74 Changes

- Android and Windows native transport hosts now reject malformed UTF-8 and
  C1-control-bearing session/peer identity fields before queueing or sending
  frames.
- Both mirrored debug host builds passed after the decoder hardening.

## Recent T75 Changes

- Android and Windows now register the locked generic local-network channel.
- Both hosts report bounded active-interface availability and generic interface
  hints; no adapter paths or peer identifiers cross the bridge.
- Host discovery remains fail-closed with an empty endpoint list because the
  repository has no discovery advertisement protocol or endpoint provisioning
  contract.
- Android APK and Windows debug host builds passed.

## Recent T76 Changes

- Added additive cancellable capture capability/action bridge interfaces while
  preserving the existing base interfaces.
- Generic capture method-channel capability and blocking calls now race the
  five-second deadline against caller cancellation and fail closed.
- Mirrored receipt presenters and capture coordinators forward mounted-route
  cancellation; teardown release remains uncancelled so native blocking can be
  disabled.
- Focused native bridge, coordinator, and receipt presenter suites passed.

Already-dispatched native calls remain host-owned. Runtime/device capture
validation, release signing, other-platform hosts, and product database/state
provisioning remain external or integration-owned.

## Recent T77 Changes

- Added additive cancellation support to the generic app-support directory
  bridge without changing the base app-storage interface.
- App-support method-channel lookups now have a positive five-second default
  deadline and fail-closed timeout/cancellation results.
- Mirrored recovery persistence factories forward cancellation to cancellable
  directory bridges while preserving compatibility with existing fakes.

Runtime persistence validation, product database/state provisioning,
other-platform storage, and already-dispatched native call semantics remain
external or integration-owned.

## Recent T78 Changes

- Added optional per-call cancellation to generic local-network and native
  transport capability bridges while preserving base integrations.
- Mirrored readiness loaders now pass cancellation through all supported native
  capability lookups and continue to return stable fail-closed readiness facts.
- Mobile and desktop app states cancel the prior readiness operation on loader
  replacement and cancel the active operation during disposal.

Already-dispatched host calls remain host-owned; runtime/device validation,
network reachability, other-platform native implementations, and product
database/state provisioning remain external or integration-owned.

## Recent T79 Changes

- Repository CI now compiles an Android debug APK and a Windows debug host in
  separate platform jobs.
- Local verification produced the Android debug APK and Windows host artifact.

These are host compilation gates only. Release signing, runtime/device
validation, network reachability, other-platform hosts, and product
database/state provisioning remain external or integration-owned.

## Recent T80 Changes

- CI now expects an Android release build without signing credentials to fail at
  the Gradle signing guard before artifact assembly.
- The negative check is credential-free and does not weaken debug builds or
  operator-owned release signing.

Signed release output, runtime/device validation, network reachability,
other-platform hosts, and product database/state provisioning remain external
or integration-owned.

## Recent T81 Changes

- The Android release-signing CI check now explicitly clears every signing
  variable and matches the exact expected Gradle guard diagnostic.
- An unrelated release-build failure now fails the CI check instead of being
  mistaken for proof that signing is enforced.

Signed release output, operator credentials, and runtime/device validation
remain external or integration-owned.

## Recent T82 Changes

- Mounted join routes now complete an app-owned cancellation signal on outcome
  replacement or disposal.
- Both orchestrators stop between pre-commit stages, and native bootstrap passes
  cancellation to cancellable local-network bridges.
- Mirrored focused tests prove route teardown and governance protection.

Already-dispatched host or governance calls remain owner-hosted. Signed release
output, operator credentials, and runtime/device validation remain external.

## Recent T83 Changes

- Mirrored app receipt key-ring provisioners now single-flight concurrent
  `ensureActiveKeys()` calls, preventing duplicate native key writes and
  divergent in-memory key rings within one process.
- The guard is cleared after either outcome, so transient native-storage
  failures remain retryable.

Cross-process storage atomicity and runtime/native persistence validation remain
external or integration-owned.

## Recent T84 Changes

- Mirrored receipt key-ring provisioning now performs a native read-back after
  successful key creation and compares both active key IDs and secrets.
- Any mismatch or unavailable read-back returns an empty key ring and a stable
  failure, preventing exports from relying on unverified persistence.

Cross-process storage atomicity and runtime/device validation remain external
or integration-owned.

## Recent T85 Changes

- Mirrored receipt routes now pass their lifecycle cancellation signal through
  the optional export callback and app-owned native key provisioning path.
- Key-ring loaders, writers, and provisioners forward cancellation to the
  additive native secure-storage capabilities when available.
- Existing one-argument export callbacks and generic native bridge contracts
  remain compatible; conflicting receipt export sources fail closed.

Already-dispatched native mutations, cross-process atomicity, runtime/device
validation, and concrete product state wiring remain external or
integration-owned.

## Recent T86 Changes

- Windows secure-key load/save/delete now use a per-namespace Local named
  mutex, closing the PeerDeal cross-process read-modify-write race.
- Mutex acquisition is bounded at five seconds and returns the existing stable
  unavailable/failure result when the host lock cannot be acquired.

Android multi-process behavior, compare-and-swap semantics, runtime/device
validation, and concrete product state wiring remain external or
integration-owned.

## Recent T87 Changes

- Android secure-key load/save/delete now use a hash-named private file lock per
  namespace and encrypted private files, closing the PeerDeal cross-process
  read-modify-write race. Legacy preference records migrate under that lock.
- Lock acquisition retries `tryLock` for at most five seconds and returns the
  existing stable unavailable/failure result when it cannot acquire the lock.

Compare-and-swap semantics, runtime/device validation, and concrete product
state wiring remain external or integration-owned.

## Recent T88 Changes

- Generic secure-key snapshots now expose a nonnegative namespace revision, with
  additive conditional save/delete channel methods and explicit conflict results.
- Mirrored receipt and local-identity provisioners pass expected revisions when
  supported, refresh after a conflict, and fail closed if no valid competing
  record is available. Existing bridge implementations remain compatible.
- Android encrypted private-file envelopes and Windows Credential Manager v2
  envelopes persist revisions, including empty-namespace tombstones; legacy
  storage formats remain readable with revision zero.
- Focused bridge and mirrored identity tests passed. Android and Windows debug
  host builds passed, as did the full analyze, boundary-check, source-text,
  serialized test, dependency-audit, and `git diff --check` gates. Dependency
  audit reports zero actionable upgrades and 11 newer versions below the
  current toolchain ceiling.

Runtime/device validation, other-platform native storage and capture, release
signing, and concrete product state wiring remain external or integration-owned.

## Recent T89 Changes

- Added `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart` to exercise
  the registered Windows method channels through the actual built runner.
- Direct execution passed app storage, capture enable/release, local-network
  capability/discovery, transport capability/receive, secure-key read-back and
  revision-conflict checks, conditional replacement/delete, and cleanup.
- UDP multicast send returned the host's stable send failure in this environment
  and is recorded as a network/firewall validation warning rather than a pass.
  Android runtime validation remains unavailable because no device or emulator
  is attached.
- Full analyze, boundary-check, source-text, serialized test, dependency-audit,
  and `git diff --check` gates passed. Dependency audit reports zero actionable
  upgrades and 11 newer versions below the current toolchain ceiling.

## Recent T90 Changes

- Fixed the nested `frame` payload contract mismatch in the Android and Windows
  native transport handlers.
- Windows now selects an operational IPv4 multicast interface for membership
  and sends. Direct host smoke passed transport send and receive, and Android
  debug APK compilation passed.
- Android now selects an operational non-loopback IPv4 multicast interface for
  send and receive, preferring Wi-Fi/Ethernet and failing closed otherwise.

## Recent T92 Changes

- Added `apps/peerdeal_desktop/tool/run_windows_native_host_smoke.ps1`, a
  bounded runner that captures output, requires the native smoke pass marker,
  rejects nonzero exits, and terminates timed-out hosts.
- CI now builds and executes the Windows native host smoke target instead of
  stopping at compilation. Local execution passed all existing checkpoints.

## Recent T93 Changes

- Added mirrored app-owned `AppHoldemProductionSessionConfigurationFactory`
  implementations. They compose the existing recovery root factory, lazy
  native local identity provisioner, persisted Hold'em source, route policy,
  and deterministic replay/event dependencies.
- Composition fails closed with stable warnings when persistence or route policy
  is unavailable and does not select product state or invent route policy.
- Focused mirrored factory tests and all repository gates passed.

## Recent T94 Changes

- Added mirrored app-owned `AppHoldemProductionSessionSnapshotWriter`
  implementations over the existing `RecoveryPersistenceStore` boundary.
- The writer validates snapshot identity, recovery scope, event cursor sequence,
  and last-event hash consistency, then persists a typed `HoldemStateSnapshot`
  with a canonical payload hash and stable fail-closed results.
- T93 configuration-factory results expose the writer over the same validated
  store; product state selection, event-log policy, database persistence,
  startup invocation, and native/device validation remain separate.

## Recent T95 Changes

- Hardened `JsonFileRecoveryPersistenceStore` with a stable per-scope OS file
  lock around hydrate-modify-write transactions, reads, and wipes.
- The lock is released by the closed OS file handle, including after process
  termination, and lock failures return stable fatal persistence results.
- The public recovery-store contract and package boundaries remain unchanged;
  production database replacement and platform/runtime validation remain open.

## Recent T96 Changes

- Added mirrored app-owned `AppHoldemProductionSessionPersistenceWriter`
  implementations. They validate caller-supplied event suffix scope and
  continuity, append events, and then persist the resulting typed snapshot.
- Retention events fail before storage, append failure prevents checkpoint
  writes, and checkpoint failure reports that the event log is durable for
  recovery-suffix replay.
- T93 configuration-factory results expose this writer over the same store;
  product state selection, event identity, snapshot IDs, startup invocation,
  database replacement, and native/device validation remain separate.

## Recent T97 Changes

- Mirrored `AppPersistedHoldemProductionSessionRoutePolicy.buildInput(...)`
  now revalidates context-supplied remote peer IDs and local seats before
  constructing production session input.
- Direct source consumers therefore retain the same fail-closed peer and seat
  gates as the context-aware production bootstrap.
- Product state, route policy ownership, database replacement, and runtime
  validation remain separate.

## Recent T98 Changes

- Mirrored app persistence writers now preflight snapshot identity, metadata,
  scope/cursor/hash consistency, and typed Hold'em state before appending an
  event suffix.
- Invalid checkpoint input cannot leave a durable event suffix behind; genuine
  checkpoint storage failures still retain the durable suffix for replay.
- Focused mobile and desktop persistence suites and all repository gates pass.

## T99 Identity Single-Flight Hardening

- Mirrored local-peer identity provisioners now clear only the exact tracked
  non-cancellable Future, so a completed cancellable call cannot clear a newer
  shared operation.
- Caller cancellation propagation remains intact; focused mobile and desktop
  identity suites pass.
- Cross-process/native/device persistence validation remains external.

## T100 Receipt Processing Bounds

- `peerdeal_receipts` now exposes shared `ReceiptExportLimits` across opaque
  export encoding, inspection, and the HMAC receipt cipher.
- Encoded body, decoded body, payload, ciphertext, and nonce sizes are checked
  before base64, JSON, or keystream processing; oversized values fail closed.
- Existing receipt formats and package boundaries remain unchanged.
- Native key storage, device/runtime validation, product persistence, and
  release signing remain external.

## T101 Recovery File Size Bounds

- `JsonFileRecoveryPersistenceStore` now applies a positive configurable
  `maxFileBytes` cap, defaulting to 4 MiB.
- Persisted files are size-checked before JSON decoding, and serialized windows
  are size-checked before temporary-file replacement.
- Oversized input/output returns
  `ERR_RECOVERY_PERSISTENCE_FILE_TOO_LARGE` and does not hydrate or write state.
- Production database replacement and platform filesystem/runtime validation
  remain external.

## T102 Generic Native Bridge Payload Bounds

- `peerdeal_native_bridges` now shares explicit generic limits for transport,
  discovery, secure-key, and diagnostic method-channel values.
- Collection sizes are checked before iteration. Frame payloads, transport
  identities, discovery strings, secure-key fields, and diagnostics are bounded
  before model construction; oversized values fail closed.
- Receipt semantics remain app-owned, and native host/device, cross-device
  network, production database, and release-signing validation remain external.

## T103 Generic App Storage and Capture Payload Bounds

- Generic app-storage bridge decoding now caps platform directory paths at
  4096 UTF-8 bytes before they can become persistence roots.
- Generic capture capability and action decoding now caps notes and warnings at
  512 UTF-8 bytes before app orchestration receives them.
- Oversized values fail closed; native host/device behavior, cross-device
  network, production database, and release-signing validation remain external.

## T104 Native Local-Network Enumeration Bounds

- Android local-network host enumeration now stops at 64 interfaces before
  active-state and hint projection.
- Windows local-network host enumeration rejects address buffers above 1 MiB,
  caps adapters at 64, and caps each adapter's unicast-address scan at 256.
- Android and Windows debug builds plus the direct Windows native-host smoke
  pass. Device behavior, cross-device reachability, other-platform hosts,
  production persistence, and release signing remain external.

## T105 Native Transport Interface Enumeration Bounds

- Android transport interface selection now caps interfaces at 64 and each
  interface-address scan at 256 entries.
- Windows transport interface selection rejects adapter buffers above 1 MiB and
  caps adapters at 64 and unicast-address scans at 256 entries.
- Android and Windows debug builds plus the direct Windows native-host smoke
  pass. Device behavior, cross-device reachability, other-platform hosts,
  production persistence, and release signing remain external.

## T106 Recovery Event-Window Bounds

- `peerdeal_sync` in-memory and JSON recovery stores now enforce configurable
  event-count and per-event byte limits, defaulting to 4,096 events and the
  protocol codec's 64 KiB event bound.
- Oversized append batches, hydrated JSON windows, and individual events fail
  closed before mutating recovery state, with stable fatal conflict codes.
- Focused recovery persistence tests and package analysis pass. Production
  database replacement and platform/runtime persistence validation remain
  external.

## T107 Privacy Diagnostics Bounds

- `DefaultDiagnosticsScrubber` now bounds recursive maps and lists at 64
  entries, nested depth at 8, text at 512 UTF-8 bytes, and protocol
  diagnostics at 64 items.
- Overflow emits stable truncation markers while existing sensitive-field
  redaction remains intact. Focused privacy tests and package analysis pass.

## T108 Provider-Proof Normalization Bounds

- `DefaultProviderProofNormalizer` now uses public `DealProofLimits` defaults
  for provider identity/reference text, maps, lists, nesting, nodes, and
  canonical UTF-8 proof bytes.
- Unsupported values, non-finite numbers, non-string object keys, and every
  limit overflow fail closed before `DealProofBundle` construction. The raw
  and normalized views share one immutable bounded payload; focused crypto
  tests and package analysis pass.

## T109 Canonical JSON Materialization Bounds

- `peerdeal_protocol` now writes deterministic canonical JSON through bounded
  map/list, nesting, UTF-8 text, node, and encoded-byte limits instead of
  recursively materializing an unbounded intermediate tree.
- `EventEnvelopeCodec` applies the configured wire-byte limit during canonical
  encode and decode validation, rejecting unsupported values and non-string
  object keys. Focused protocol tests and package analysis pass.

## T110 Receipt JSON Structure Bounds

- `OpaqueExportDecoder` now validates decoded artifact-body and plaintext-payload
  JSON through bounded canonical protocol serialization before receipt shape
  inspection, using the receipt-owned decoded-body and payload byte limits.
- Structurally oversized maps, deep values, unsupported values, and invalid
  object keys fail closed without changing signature, cipher, opacity, or
  authorization semantics. Focused receipt tests and package analysis pass.

## T111 Typed State Hydration Bounds

- `TableState`, `HoldemSeatState`, `HoldemHandState`, `HoldemEventCursor`, and
  `HoldemStateSnapshot` now validate materialized JSON through the existing
  bounded canonical protocol serializer before reading typed fields or copying
  collections.
- Oversized maps/lists and unsupported nested values fail closed without moving
  deterministic truth out of `peerdeal_core` or variant rules out of
  `peerdeal_variants`. Focused core/variant tests and package analysis pass.

## T112 Protocol Envelope Hydration Bounds

- `EventEnvelope.fromJson` and `SnapshotEnvelope.fromJson` now validate the
  complete materialized JSON tree through the bounded canonical protocol
  serializer before typed field access.
- The file-backed recovery store now fails closed when persisted snapshot
  payload structure exceeds the protocol limits. Focused protocol and recovery
  tests and package analysis pass.

## T113 Replay Event Window Bounds

- `EventWindowValidator` now applies a configurable positive event-count limit,
  defaulting to 4,096 events, and reports the structured
  `ERR_REPLAY_EVENT_WINDOW_TOO_LARGE` mismatch when exceeded.
- `BasicReplayEngine` checks the raw request event list before protocol, scope,
  range, selection, or projector traversal; the selected window remains
  validated after filtering and snapshot-suffix planning. Focused replay tests
  and package analysis pass.

## T115 Direct Sync Event Window Bounds

- `BasicConflictDetector` and `BasicSnapshotApplier` now enforce the shared
  configurable 4,096-event recovery-window default on direct caller-provided
  event lists before protocol, scope, sequence, or projector traversal.
- Oversized direct sync requests return the fatal
  `ERR_RECOVERY_EVENT_COUNT_TOO_LARGE` conflict; persistence stores retain
  their existing durable-window limits and persistence-specific conflict codes.
- Focused `peerdeal_sync` tests (61) and package analysis pass.

## T114 Replay Anchor And Selection Fail-Closed Bounds

- Oversized replay requests now return immediately before protocol, scope, range,
  or event traversal; the prior eager validation list could otherwise continue
  processing after the count mismatch was found.
- `AnchorHashCalculator` and `SnapshotSuffixReplayer` enforce the same default
  4,096-event bound. Anchor hashing passes explicit canonical list/node limits,
  and `BasicReplayEngine` converts selection and anchor failures into stable
  `ERR_REPLAY_SELECTION_FAILURE` and `ERR_REPLAY_ANCHOR_CALCULATION_FAILURE`
  mismatches. Focused replay/protocol tests and package analysis pass.

## Required Gates

Run after each retrofit step:

- `rtk dart run melos run source-text`
- `rtk dart run melos run boundary-check`
- `rtk dart run melos run dependency-audit`
- `rtk dart run melos run analyze`
- `rtk dart run melos run test`
- `rtk git diff --check`

## Next Implementation Targets

1. Validate Android secure-key/capture behavior on a real device and validate
   cross-device Android/Windows multicast reachability, including
   operator-owned release signing.
2. Add the remaining other-platform capture, local-network, and transport
   implementations behind the existing generic method-channel contracts; the
   Android/Windows transport is now host-backed but still needs device/network
   reachability validation.
3. Supply the concrete product implementation of
   `AppHoldemProductionSessionSource` and invoke
   `AppHoldemProductionSessionBootstrap` from the real session/state and local
   identity flow through the typed first-join and rejoin handoff, using the
   persisted configuration factory where its recovery-backed inputs are valid;
   add native peer transport device/network validation and final UX validation
   separately.
4. Continue production hardening items recorded in `docs/PRODUCTION_READINESS.md`
   without crossing locked package boundaries.

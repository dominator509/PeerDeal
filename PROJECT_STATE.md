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

- `.github/workflows/ci.yml` invokes the repository-pinned Melos 8.5.0.
- `pubspec.yaml` and `pubspec.lock` align the workspace on Melos 8.5.0.
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
- Native transport contract bounds now have a repository checker that compares
  the canonical Dart payload, identity, batch, and signed sequence limits with
  both Android and Windows host declarations; Melos and CI run the checker and
  its negative-path tests.
- Protocol tests now route every `invalid_` and `unsupported_` fixture through
  its catalog/schema family and require rejection, preventing rejected fixture
  additions from silently becoming accepted.
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

## T120 Network Collection Bounds

- `peerdeal_network` now bounds direct peer-id, bootstrap-candidate, and
  peer-metric collections before routing or confidence materialization.
- Shared defaults are 32 peer IDs, 32 candidates, and 64 peer metrics.
  Overflow fails closed as empty bootstrap candidates, unresolved path
  selection, unsafe confidence, or unsafe primary election. Focused network
  tests (42) and package analysis pass.

## T121 Hold'em Showdown Seat Bound

- `HoldemShowdownEvaluator` now rejects caller-provided seat collections above
  the shared nine-seat Hold'em launch invariant before sorting, card expansion,
  or hand evaluation with `ERR_HOLDEM_SHOWDOWN_SEAT_COUNT`.
- `HoldemAdapter` identity and configuration validation reuse the same limit;
  focused variant tests (147) and package analysis pass.

## T122 Hold'em Settlement Commitment Bound

- `ShowdownSettlementProjector` now rejects commitment collections above the
  shared nine-seat Hold'em limit before core side-pot construction for both
  contested and uncontested settlement paths.
- Overflow fails closed with
  `ERR_HOLDEM_SETTLEMENT_PROJECT_COMMITMENT_COUNT`; focused settlement,
  coordinator, and evaluator tests pass.

## T123 Hold'em Showdown Projection Bounds

- `ShowdownEvaluationResult` now bounds direct result collections, pot-slice
  maps, and per-slice contested seat-ID lists before projection materialization.
- Overflow carries `ERR_HOLDEM_SHOWDOWN_RESULT_COUNT`,
  `ERR_HOLDEM_SHOWDOWN_SLICE_COUNT`, or
  `ERR_HOLDEM_SHOWDOWN_SLICE_SEAT_COUNT` through blocked settlement projection;
  focused variant projection tests (52) and analysis pass.

## T130 App Session Event-Batch Bound

- Mirrored `AppTableSessionRuntime` owners now enforce the shared 4,096-event
  default, with a positive caller-owned override, before copying or reducing
  caller-supplied non-retention event batches.
- Oversized batches fail closed with `ERR_APP_SESSION_EVENT_BATCH_TOO_LARGE`
  without mutating app state; focused mobile and desktop runtime suites cover
  overflow and invalid limits.

## T137 Production Handoff Staleness Hardening

- Mirrored app shells now associate each asynchronous loaded production-session
  handoff with a private generation token.
- Late results from an older join/load are ignored after a newer handoff, and
  disposal or a higher-precedence configured route invalidates the token before
  any fallback or production navigation is pushed.
- Focused mobile and desktop app-shell suites cover delayed stale completion.
- Product state/source selection, database persistence, device/network
  validation, other-platform hosts, and release signing remain open.

## T138 Production Configuration Lifecycle Hardening

- Mirrored app shells now invalidate the active asynchronous production-session
  handoff when the optional configuration factory is removed or replaced.
- Delayed results from a loader created under the previous configuration cannot
  push a stale route after a runtime/widget rebuild changes that contract.
- Focused mobile and desktop app-shell suites cover factory removal with a
  delayed stale result.
- Product state/source selection, database persistence, device/network
  validation, other-platform hosts, and release signing remain open.

## T139 Android Secure-Key UTF-8 Boundary Hardening

- Android secure-key namespaces and record fields now enforce UTF-8 byte
  limits, matching the locked Dart channel contract and Windows host behavior.
- Shared native-bridge tests cover oversized multibyte secure-key material.
- Android debug APK compilation passes after the host change.
- Android device/runtime validation, cross-device networking, other-platform
  hosts, database persistence, and release signing remain open.

## T140 Dart Secure-Key Namespace Boundary Hardening

- The shared native-bridge contract now defines a 128-byte UTF-8 secure-key
  namespace limit.
- Dart method-channel requests reject oversized multibyte namespaces before
  platform dispatch, matching Android and Windows host validation.
- Focused secure-key bridge tests cover the rejection path without a platform
  call.
- Android device/runtime validation, cross-device networking, other-platform
  hosts, database persistence, and release signing remain open.

## T141 Dart Secure-Key Text Validation Hardening

- Shared native-bridge validation now applies UTF-8 byte and control-character
  rules consistently to secure-key namespaces, IDs, purposes, algorithms, and
  secrets.
- Oversized or control-bearing save/delete requests fail before native dispatch.
- Focused method-channel and channel-contract tests cover multibyte and control
  rejection paths.
- Android device/runtime validation, cross-device networking, other-platform
  hosts, database persistence, and release signing remain open.

## T142 Generic Native Bridge Text Boundary Hardening

- Shared Dart bridge validation now rejects padded or C0/C1-control-bearing
  transport identities and receive scopes, local-network values, capture
  diagnostics, and app-storage paths/warnings.
- Focused contract and transport preflight tests plus the full native bridge
  Flutter package suite pass.
- Other-platform hosts, Android/Windows device and network validation, database
  persistence, and release signing remain open.

## T143 Native App-Storage Path Boundary Hardening

- Android no-backup and Windows `LocalAppData` host results now enforce the
  shared 4096-byte safe UTF-8 path boundary, rejecting padding and C0/C1
  controls before returning an available directory.
- Android debug compilation, Windows debug compilation, and the Windows native
  host smoke pass; the smoke target asserts the returned path contract.
- Production database persistence, device/runtime reachability, other-platform
  hosts, and release signing remain open.

## T144 Production Join-Context Propagation

- Mirrored configuration factories now accept an optional accepted join context
  and context-aware route-policy factory.
- The generated loader forwards the exact `JoinFlowSessionContext` before route
  and source composition, with the prior no-context policy path preserved.
- Focused mobile and desktop configuration suites pass; product state/database
  provisioning and platform/runtime validation remain open.

## T145 Production Configuration Warning Preservation

- Mirrored production-session configuration factories retain recovery-store
  warnings when route-policy or persisted-source composition fails after store
  creation, while preserving the stable unavailable result and suppressing
  exception detail.
- Focused mobile and desktop configuration suites cover the fail-closed
  composition path; product state/database provisioning and platform/runtime
  validation remain open.

## T146 CI Branch Gate Coverage

- `.github/workflows/ci.yml` now runs on direct pushes to `retrofit/**` and
  `hardening/**`, in addition to `main` and `master`, and supports manual
  `workflow_dispatch` runs.
- Existing repository, Android, Windows, signing-guard, and native-host smoke
  jobs are unchanged; hosted workflow execution and operator-owned release
  credentials remain external.

## T147 Production Table Lifecycle Invalidation

- Mirrored production Hold'em surfaces reset pending projection/retry state when
  the runtime, coordinator, peer, or local seat identity changes.
- Generation guards prevent late persistence, transport, retry, and disposal
  completions from mutating a replacement session's UI state.
- Focused mobile and desktop route tests cover delayed native-send completion
  after runtime replacement.

## T148 Inbound Checkpoint Lifecycle Invalidation

- Mirrored table routes capture accepted inbound events with their owning
  runtime, snapshot coordinator, and lifecycle generation.
- Replaced or disposed transport callbacks cannot checkpoint a replacement
  route or refresh its UI state.
- Focused mobile and desktop route tests cover delayed inbound completion after
  runtime replacement.

## T149 Cancelled Native Receive Suppression

- Mirrored native frame drains race native receive and frame-handler work
  against source cancellation and fail closed before late frame delivery.
- Native sessions forward route cancellation into the drain, preventing old
  runtimes from mutating after route replacement or disposal.
- Focused mobile and desktop transport/route tests cover late receive
  suppression.

## T154 Snapshot Coordinator Recovery Bound

- Mirrored snapshot coordinators now reject event suffixes above their
  configured recovery limit before copying input or persisting state.
- Persisted configuration composition passes one validated recovery limit into
  the persistence writer and snapshot coordinator.
- Focused mobile and desktop coordinator/configuration suites cover the bound.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## T155 Snapshot Checkpoint Queue Bound

- Mirrored snapshot coordinators retain at most 64 failed checkpoints by
  default, with a positive caller-owned pending-checkpoint limit.
- A full retry queue fails closed with a stable warning and does not retain
  another checkpoint, preventing unbounded memory growth during store outage.
- Configuration factories pass the same pending-checkpoint limit into the
  coordinator.
- Focused mobile and desktop coordinator/configuration suites cover queue
  capacity and invalid-limit failure.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds
  passed; the smoke run passed all bridge checkpoints.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## T167 Shared Sync Snapshot Hash Verification

- `peerdeal_sync` conflict planning and snapshot application now recompute the
  canonical payload hash and reject envelope mismatches before recovery state
  projection.
- The stable fatal code is `ERR_SNAPSHOT_PAYLOAD_HASH_MISMATCH`; canonical
  snapshot fixtures remain valid.
- The full shared sync package suite passes.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## T174 Immutable Native-Bridge Collections

- Generic native bridge models now defensively copy and freeze local-network
  discovery lists, secure-key record lists, native receive frame lists, and
  transport frame payload bytes.
- Native bridge contract tests plus affected mobile and desktop suites prove
  caller-owned collections cannot alter package-boundary results.
- Android debug, Windows debug, and Windows native-host smoke artifacts passed.
- Remaining work is unchanged: durable database replacement, real product
  state selection, device/network validation, other-platform hosts, release
  signing, and final UX.

## T175 Immutable Network Collections

- Generic network models now defensively copy and freeze bootstrap peer/candidate
  lists, LAN discovery lists, transport payload bytes, warning diagnostics, and
  peer-election rankings.
- Focused network and mirrored mobile/desktop transport suites prove caller-owned
  collections cannot alter package-boundary results.
- Remaining work is unchanged: durable database replacement, real product state
  selection, device/network validation, other-platform hosts, release signing,
  and final UX.

## T176 Immutable Sync/Recovery Collections

- Sync and recovery models now defensively copy and freeze recovery event
  requests/windows, conflict results, warning diagnostics, snapshot results,
  persistence results, and reconciliation notes.
- Focused sync ownership, conflict, snapshot, and coordinator suites prove
  caller-owned collections cannot alter recovery-boundary results.
- Remaining work is unchanged: durable database replacement, real product state
  selection, device/network validation, other-platform hosts, release signing,
  and final UX.

## T177 Immutable Replay Collections

- Replay requests, snapshot suffix plans, and replay results now defensively
  copy and freeze event windows, warning diagnostics, and replay mismatches.
- Focused replay ownership, engine, mismatch, suffix, and anchor suites prove
  caller-owned collections cannot alter deterministic replay results.
- Remaining work is unchanged: durable database replacement, real product state
  selection, device/network validation, other-platform hosts, release signing,
  and final UX.

## T173 Immutable App-Boundary Collections

- Mirrored native bootstrap candidate, native transport session/drain, and
  receipt key-ring result constructors now defensively copy and freeze exposed
  collection diagnostics.
- Focused mobile and desktop transport, bootstrap, and receipt suites prove
  caller-owned collections cannot alter projected results.
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## T172 Immutable Readiness/Transport Diagnostics

- Mirrored native-readiness snapshots and transport-source poll/start result
  constructors now defensively copy and freeze warning diagnostics.
- Focused mobile and desktop readiness and transport-source tests prove
  caller-owned warning lists cannot alter projected results.
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## T171 Immutable Local-Identity Diagnostics

- Mirrored local-identity loader and provisioner result constructors now
  defensively copy and freeze warning diagnostics.
- Focused mobile and desktop local-identity tests prove caller-owned warning
  lists are isolated and result warning collections reject mutation.
- Remaining work is unchanged: durable database replacement, real product state
  selection, device/network validation, other-platform hosts, release signing,
  and final UX.

## T170 Immutable Startup Diagnostics

- Mirrored recovery-store and production-session configuration load results now
  defensively copy and freeze warning diagnostics.
- Focused mobile and desktop configuration, recovery, and app-shell tests prove
  caller-owned warning lists are isolated and result warning collections reject
  mutation.
- Remaining work is unchanged: durable database replacement, real product state
  selection, device/network validation, other-platform hosts, release signing,
  and final UX.

## T169 Immutable App-Session Diagnostics

- Mirrored app session and Hold'em inbound result constructors now defensively
  copy and freeze warning diagnostics.
- Focused mobile and desktop runtime tests prove caller-owned warning lists are
  isolated and result warning collections reject mutation.
- Remaining work is unchanged: durable database replacement, real product state
  selection, device/network validation, other-platform hosts, release signing,
  and final UX.

## T168 Inbound Event Checkpoint Identity

- Mirrored app session event results now carry the exact accepted
  `EventEnvelope` for successful single-event projection.
- Mirrored Hold'em table routes pass that callback-owned event into snapshot
  checkpointing instead of rereading mutable runtime `lastAcceptedEvent` state.
- Focused mobile and desktop runtime and transport-handler tests cover the
  event identity fields after canonical transport decoding.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## T166 Persisted Snapshot Hash Verification

- Mirrored persisted Hold'em sources now verify the canonical payload hash in
  each persisted snapshot envelope before decoding typed state.
- Hash mismatches fail closed before identity provisioning or route input
  construction; canonical snapshot fixtures remain valid.
- Focused mobile and desktop source suites cover the integrity boundary.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## T165 Orphaned Recovery Event Guard

- Mirrored persisted Hold'em sources now fail closed when durable recovery
  events exist without a typed snapshot anchor.
- Initial product-state loading, local identity provisioning, and checkpoint
  work are skipped; the orphaned suffix remains unchanged for operator or
  product recovery handling.
- Focused mobile and desktop source suites cover the integrity boundary.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## T164 First-Join Typed State Checkpoint

- Mirrored persisted Hold'em sources and configuration factories now accept an
  optional product-owned initial typed-state loader for an empty recovery
  window.
- Invite scope, event/cursor sequence, and protocol genesis invariants are
  validated before local identity provisioning; the initial state is then
  checkpointed through the existing snapshot coordinator before app input is
  returned.
- Focused mobile and desktop source/configuration tests cover first join,
  invalid scope, missing persistence, and checkpoint failure. Full repository
  gates, Android/Windows builds, and Windows native-host smoke pass.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## T163 Receipt Key-Ring Native Text Bound

- Mirrored receipt key-ring loaders and writers now reuse the locked native
  secure-key UTF-8/C1 and byte limits for namespaces, key IDs, and secrets.
- C1-bearing or byte-oversized namespace values fail closed before native
  load/save/delete calls; invalid key metadata cannot become a receipt key-ring
  entry.
- Focused mobile and desktop receipt suites and package analysis pass.

Remaining: full repository gates, Android/Windows runtime key-store validation,
cross-device networking, other-platform hosts, product state/database
provisioning, and release signing remain separate.

## T162 Production Session Peer Identity Bound

- Mirrored local identity loaders and writers now enforce the shared 256-byte
  safe UTF-8/control-free native transport identity boundary.
- Persisted Hold'em route policies and production-session factories reject
  invalid C1-bearing or byte-oversized peer identities before native save or
  route construction.
- Focused mobile and desktop identity, route-policy, and factory suites cover
  the boundary.

Remaining:
- Full repository gates, Android/Windows runtime and cross-device network
  validation, other-platform hosts, product state/database provisioning, and
  release signing remain separate.

## T161 Hold'em Projection Publisher Peer Bound

- Mirrored app Hold'em projection publishers now enforce the shared 256-byte
  safe UTF-8/control-free transport identity boundary before sender calls.
- Invalid C1-bearing or oversized local/remote peer IDs fail closed without
  emitting projection frames.
- Focused mobile and desktop Hold'em runtime suites cover the boundary.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## T160 Native Readiness Secure-Key Namespace Bound

- Mirrored app-native readiness loaders now enforce the shared 128-byte safe
  UTF-8/control-free secure-key namespace boundary before bridge lookup.
- Invalid C1-bearing or oversized namespaces fail closed without invoking
  secure-key storage.
- Focused mobile and desktop readiness suites cover the boundary.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## T159 Native Transport Source Scope Bound

- Mirrored app transport sources and provisioners now enforce the shared
  256-byte safe UTF-8/control-free transport identity boundary before source
  start, poll, or native capability lookup.
- Invalid C0/C1-bearing, padded, empty, or oversized scopes fail closed before
  route source scheduling or native provisioning.
- Focused mobile and desktop source/provisioner suites cover the lifecycle
  boundary.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## T158 Native Transport Send Model Bound

- Mirrored app-native transport sinks now validate converted
  `NativeTransportFrame` values before injected bridge calls.
- Outbound identities, sequence, and payload cannot bypass the native model's
  safe UTF-8/control and size invariants through the trim-only network layer.
- Focused mobile and desktop transport-adapter suites cover rejection before
  native send lookup.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## T157 Native Transport Receive Scope Bound

- Mirrored app-native transport drains now enforce the shared native bridge
  safe UTF-8/control-free transport identity boundary before invoking receive.
- Direct drain callers cannot bypass the 256-byte transport identity limit or
  inject C0/C1-control-bearing, padded, or empty session/peer scope values.
- Focused mobile and desktop transport-adapter suites cover rejection before
  native receive lookup.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## T156 Native Bootstrap Provider Output Bound

- Mirrored native join bootstrap coordinators now cap, normalize, and
  deduplicate reachable peer IDs returned by the candidate provider before
  creating `BootstrapPlan.peerCandidates`.
- Provider output cannot bypass the configured discovery candidate limit or
  inject malformed peer identity text into the accepted join handoff.
- Focused mobile and desktop native-bootstrap suites cover the output bound.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds
  passed; the smoke run passed all app-storage, capture, local-network,
  transport, and secure-key checks.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## T153 Snapshot Serialization Preflight Hardening

- Mirrored snapshot writers now preflight canonical serialization of typed
  snapshots before event-log append.
- Unsupported snapshot values fail closed with stable persistence warnings;
  event and snapshot stores remain unchanged.
- Focused mobile and desktop persistence-writer and snapshot-writer suites cover
  the unsupported metadata path.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## T152 Snapshot ID Factory Failure Hardening

- Mirrored production snapshot coordinators now invoke caller-owned snapshot ID
  factories inside the serialized checkpoint operation.
- Factory exceptions return the stable `Holdem snapshot ID could not be
  created.` persistence warning without store mutation or pending state.
- Focused mobile and desktop snapshot coordinator suites cover the fail-closed
  path.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## T151 Transport Provisioning Cancellation Recheck

- Mirrored `AppTableSessionTransportProvisioner` implementations now perform a
  post-load cancellation recheck before constructing and returning a source.
- A cancellation signaled during native session creation fails closed with the
  existing stable session-load cancellation warning.
- Focused mobile and desktop provisioner, source, drain, and session-factory
  suites cover the cancellation race.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## T150 Source-Owned Drain Disposal Cancellation

- Mirrored transport sources expose an additive cancellable drain callback and
  complete its signal on disposal or external route cancellation.
- Native session factories use the callback so standalone source mounts cannot
  leave in-flight native receives active after disposal.
- Focused mobile and desktop source, drain, and session-factory tests cover
  disposal propagation.

## T136 Production Snapshot Retry Ordering Hardening

- Mirrored mobile and desktop snapshot coordinators now retain newer accepted
  checkpoints behind a failed older checkpoint in FIFO order, preserving the
  latest state across repeated store failures.
- Retry requests resolve the current pending queue only after their serialized
  turn begins, preventing concurrent retry calls from writing an older
  checkpoint after a newer checkpoint has completed.
- Focused mobile and desktop coordinator suites cover repeated failure,
  durable event-suffix retry, and concurrent retry ordering.
- Product state/source selection, database persistence, device/network
  validation, other-platform hosts, and release signing remain open.

## T135 Production Snapshot Checkpoint Wiring

- Mirrored production session factories now share the existing typed snapshot
  writer with the existing event-plus-snapshot persistence writer and a
  serialized route snapshot coordinator.
- Accepted local projection suffixes and accepted remote events are persisted
  through the existing event-log policy before snapshot checkpointing; failed
  checkpoints remain ordered and retryable, while accepted close/wipe events
  clear pending snapshot state after retention.
- The default production surface exposes persistence-pending status and retry
  without claiming event-log, database, device, or platform implementation.
- Focused mobile and desktop coordinator, persistence, route, bootstrap, and
  factory suites pass.

## T134 Production Session Factory Loader Wiring

- Mirrored mobile and desktop runtimes now accept a configured
  `AppHoldemProductionSessionConfigurationFactory` and adapt it to the typed
  join/rejoin loader when no explicit loader is supplied.
- Stable adapter identity prevents rebuild churn; explicit loader and route
  precedence remain unchanged, and the accepted session context still reaches
  the existing bootstrap route.
- Focused mobile and desktop app-shell suites cover the factory fallback and
  fail-closed missing-snapshot boundary.
- Product state/source selection, database persistence, device/network
  validation, other-platform hosts, and release signing remain open.

## T133 Native Host Build and Smoke Validation

- Android debug APK and Windows debug host compilation pass.
- The dedicated Windows smoke target passes app storage, capture,
  local-network, transport, and secure-key mutation checkpoints through the
  default RTK-safe wrapper path.
- The wrapper derives its executable path when RTK invokes the script with an
  empty `PSScriptRoot`.
- This is local host evidence only; real device/cross-device behavior,
  other-platform implementations, product state/database wiring, and release
  signing remain open.

## T132 Typed Production Session Handoff Loader

- Mirrored mobile and desktop app shells now expose an optional typed loader
  from accepted `JoinFlowSessionContext` into the existing production
  configuration-factory result.
- Available loader results are mounted only after route collision/path checks
  and through the existing native readiness-gated bootstrap route; explicit
  handlers and prebuilt routes remain unchanged.
- Loader failures, unavailable results, invalid writer/configuration output,
  and unsafe or colliding dynamic paths fail closed to the safe route surface.
- Focused app-shell tests and the full local gate set pass. This does not claim
  concrete product state/database wiring or real-device/platform readiness.

## T131 Production Recovery-Limit Propagation

- Mirrored production bootstrap and configuration composition now carry one
  validated recovery-event limit into the app session runtime.
- Persisted configuration passes that same limit to the persisted source and
  persistence writer, avoiding default-limit drift between hydration, runtime
  ingestion, and checkpoint writes.
- Focused mobile and desktop production-session tests cover propagation and
  invalid-limit fail-closed behavior.

## T129 Persisted Session Writer Event Bound

- Mirrored `AppHoldemProductionSessionPersistenceWriter` instances now enforce
  the shared 4,096-event default, with a positive caller-owned override, before
  event traversal, snapshot validation, or store append.
- Oversized suffixes fail closed without creating a durable event or snapshot;
  focused mobile and desktop writer suites cover overflow and invalid limits.

## T128 Persisted Session Recovery Window Bound

- Mirrored `AppPersistedHoldemProductionSessionSource` adapters now enforce
  the shared 4,096-event recovery-window default, with a positive caller-owned
  override, before snapshot decoding, suffix materialization, identity
  provisioning, or deterministic replay.
- Oversized windows fail closed at the app store boundary; focused mobile and
  desktop source suites cover overflow and invalid limits.

## T127 Receipt Key-Ring Collection Bounds

- `ReceiptKeyRingSnapshot` and `StaticReceiptSigningKeyProvider` now bound
  retained verification and decryption collections to 128 entries by default
  before lookup traversal, with configurable positive limits and fail-closed
  overflow behavior.
- Active usable keys remain directly available; focused receipt signing and
  encryption tests cover overflow and invalid limit inputs.

## T126 Wizard Input and Compilation Bounds

- `DefaultPresetResolver` now bounds preset layers, per-layer and merged values,
  conflicts, helper suggestions, partial settings, ambiguities, and resolved
  fields; nested values use bounded protocol canonical JSON validation.
- Direct drafts and compiler plans reject oversized or unsupported resolved
  fields, policy profiles, and validation messages; focused wizard resolver and
  compiler suites plus package analysis pass.

## T125 Mode Governance Collection Bounds

- `DefaultGovernanceEngine` now applies configurable limits before participant,
  seat, or waitlist traversal: 256 participants, 64 seats, and 256 waitlist
  entries by default.
- Oversized contexts and waitlist growth at capacity fail closed with stable
  governance result codes; focused mode-governance tests (17) and package
  analysis pass.

## T124 Core Pot Settlement Bounds

- `SidePotBuilder` and `PotEngine` now apply variant-agnostic core limits of 64
  commitments, 64 winning slice-map entries, and 64 winners per slice before
  side-pot or award traversal.
- Overflow fails closed with explicit core settlement warnings; focused core pot
  tests (10) and package analysis pass.

## T119 Direct Sync Request Scope Validation

- `BasicConflictDetector` and `BasicSnapshotApplier` now validate direct
  table/session/protocol request identities through the shared
  `RecoveryPersistenceScope` rules before event traversal, snapshot projection,
  or projector access.
- Invalid direct scopes return fatal `ERR_RECOVERY_SCOPE_INVALID` or
  `ERR_SNAPSHOT_APPLY_SCOPE_INVALID` conflicts. Focused `peerdeal_sync` tests
  (70) and package analysis pass.

## T118 Recovery Scope Storage-Key Bound

- `RecoveryPersistenceScope` now rejects storage keys above the shared 180-byte
  UTF-8 limit before in-memory indexing or base64url filename generation.
- In-memory and JSON recovery stores return the existing fatal
  `ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID` conflict without mutating state or
  creating files for oversized scopes. Focused `peerdeal_sync` tests (68) and
  package analysis pass.

## T117 Direct Sync Snapshot Bounds

- `BasicConflictDetector` and `BasicSnapshotApplier` now validate supplied
  `SnapshotEnvelope` values through bounded canonical JSON before protocol,
  scope, or snapshot/suffix projection work.
- The shared default is 4 MiB with the protocol map/list/depth/text/node
  limits; oversized or unencodable snapshots return fatal
  `ERR_RECOVERY_SNAPSHOT_TOO_LARGE` or `ERR_RECOVERY_SNAPSHOT_INVALID`
  conflicts.
- `JsonFileRecoveryPersistenceStore.defaultMaxFileBytes` now shares the same
  recovery snapshot limit constant. Focused `peerdeal_sync` tests (66) and
  package analysis pass.

## T116 Direct Sync Event Codec Bounds

- `BasicConflictDetector` and `BasicSnapshotApplier` now run each direct
  caller-provided event through the existing `EventEnvelopeCodec` before
  protocol, scope, sequence, or projector traversal.
- The shared default is 64 KiB per event with the protocol canonical structure
  limits; oversized or unencodable events return fatal
  `ERR_RECOVERY_EVENT_TOO_LARGE` or `ERR_RECOVERY_EVENT_INVALID` conflicts.
- Focused `peerdeal_sync` tests (64) and package analysis pass.

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

## T178 Protocol Session Message Authentication

- `peerdeal_protocol` now exposes a bounded, versioned
  `SessionAuthenticatedPayloadCodec` and HMAC-SHA256
  `SessionMessageAuthenticator` contract.
- Mirrored mobile and desktop production Hold'em routes authenticate canonical
  event bytes with transport session, sender, recipient, and sequence scope;
  bootstrap fails closed when the app does not provide an authenticator.
- Full mobile (577) and desktop (576) Flutter suites, protocol tests, mirrored
  route/bootstrap tests, analyzer, boundary, source-text, and diff checks pass.
  Native transport remains generic; app-owned key provisioning, session
  authorization, key rotation, real-device/network validation, product
  session/database wiring, other-platform hosts, release signing, and final
  UX remain open.

## T179 Transport Replay Admission Guard

- `peerdeal_network` now applies bounded replay protection in the validating
  receive boundary, keyed by session, sender, recipient, and sequence scope.
- Duplicate and stale sequences are rejected before session-handler dispatch;
  unique out-of-order frames inside the configured window remain admissible,
  and accepted sequences are recorded only after handler success so retries
  remain possible after downstream failure.
- The default guard fails closed when its bounded scope limit is exhausted and
  does not evict established replay state. Network package tests (73) and
  analyzer pass. Native queue deduplication, authentication key policy,
  real-device reachability, product session authorization, and durable
  persistence remain separate gates.

## T318 Production Route Failure Surface

- Mirrored `AppHoldemTableSessionRoute` owners now render the shared
  `PeerDealAppScaffold` and error status when an injected production surface
  throws during build, instead of dropping to an unstructured bare widget.
- The fallback exposes only bounded state/action text and does not project the
  caught exception into the UI. Focused mobile and desktop route suites cover
  the fail-closed surface; final visual, device, and product-flow validation
  remain external.

## T319 Production Table Operational UI Hierarchy

- Mirrored production Hold'em surfaces now use explicit Session, Table state,
  Seats, Connection, and Controls sections for operational scanning.
- Seat rows retain bounded values and semantics while distinguishing the local
  and current acting seats through the existing app-owned surface.
- This is a presentation-only hardening slice. State truth, transport,
  persistence, and package boundaries are unchanged; final visual/device and
  non-demo product-flow validation remain external.

## T320 Transport Replay-Scope Admission Serialization

- `ValidatingTransportFrameReceiver` now serializes unrecorded replay-scope
  admission and per-scope receive lifecycles before handler dispatch and replay
  recording.
- This prevents concurrent first frames from reaching a handler when a bounded
  replay scope limit can reject the later record, while preserving retry after
  handler failure and leaving protocol/network contracts unchanged.
- Focused and full network tests plus package analysis pass. Device/network
  reachability and product transport wiring remain external.

## T321 Cross-Platform Transport Sequence Bounds

- Generic native transport models and channel decoding now reject sequence IDs
  above the shared signed 32-bit maximum required by Android and the native wire
  envelope.
- Windows host argument and wire decoding now apply the same maximum instead
  of accepting its broader unsigned 32-bit range.
- Package analysis and source checks pass. Flutter widget and Windows native
  build/runtime validation remain external.

## T322 Cross-Platform Transport Payload Bounds

- The shared native transport payload ceiling is now 60 KiB, matching the
  Android and Windows host implementations and their private wire envelope.
- Oversized payloads therefore fail closed at the Dart model/channel boundary
  before reaching a host that would reject them.
- Direct package analysis and source checks pass. Flutter widget and native
  runtime/build validation remain external.

## Recent T325 Changes

- The existing `holdem_opening_hand.json` fixture now includes the current
  `HoldemHandState` persistence fields, including betting round, hand
  commitments, acted seats, pot, and nullable action metadata.
- Variant persistence coverage now loads that fixture through
  `HoldemHandState.fromJson` and asserts its opening-hand state, so this
  fixture cannot silently drift from the typed parser.
- No Hold'em rule, core truth, protocol, app, or package boundary changed.

## Recent T326 Changes

- Variant persistence fixtures now cover a valid all-in/five-card edge state
  and invalid duplicate-seat and negative-stack states.
- The persistence suite generically rejects every `invalid_` Hold'em fixture
  through `HoldemHandState.fromJson`, preventing fixture additions from
  bypassing typed validation.
- No Hold'em rule, core truth, protocol, app, or package boundary changed.

## Recent T327 Changes

- Mode governance fixtures now include an invalid duplicate-participant case.
- The governance test suite discovers every JSON fixture and requires invalid
  fixtures to return `ERR_GOVERNANCE_CONTEXT_INVALID` through the existing
  policy engine.
- No mode policy, state model, protocol, app, or package boundary changed.

## Recent T328 Changes

- Replay fixtures now cover hand-scoped replay, snapshot-plus-suffix replay,
  anchor mismatch, and protocol mismatch.
- The replay test suite discovers every JSON fixture and decodes each through
  the typed `ReplayRequest` boundary before exercising the scenario assertions.
- No replay engine, protocol, projector, app, or package boundary changed.

## Recent T329 Changes

- Sync recovery fixtures now include a valid snapshot-plus-suffix window and an
  unsupported snapshot protocol safe-close case.
- The sync coordinator suite discovers every JSON fixture and decodes each
  through a typed `RecoveryRequest` boundary before exercising recovery
  assertions.
- No sync engine, protocol, projector, app, or package boundary changed.

## Recent T330 Changes

- Wizard fixtures now cover simple, advanced, conversational, and preset-stack
  inputs through typed test-only decoders.
- The resolver suite discovers every setup-intent fixture and requires a
  build-ready validated plan, deterministic preset priority, and advisory
  helper behavior.
- No wizard resolver, compiler, protocol, app, or package boundary changed.

## Recent T331 Changes

- Crypto fixtures now cover verified-hand, partial-session, and wiped-request
  inputs through a typed test-only `VerificationRequest` decoder.
- The verification suite discovers every request fixture and asserts the
  existing verified, partial, and wiped engine outcomes.
- No crypto verifier, protocol, receipt, app, or package boundary changed.

## Recent T332 Changes

- Receipt fixtures now cover live, wiped, and wrong-user authorization inputs
  through typed test-only receipt and authorization decoders.
- The fixture suite discovers every receipt fixture and asserts matching access,
  wrong-user restore rejection, and wiped-receipt rejection.
- No receipt authorizer, crypto, protocol, app, or package boundary changed.

## Recent T333 Changes

- Privacy fixtures now cover strict-ephemeral and timed-sandbox policies through
  a typed test-only `RetentionPolicy` decoder.
- The fixture suite discovers every policy fixture and asserts restore
  eligibility, derived wipe/export behavior, and the exact timed wipe boundary.
- No retention engine, receipt, protocol, app, or package boundary changed.

## Recent T334 Changes

- Core pot fixtures now cover side-pot slices and folded dead money through a
  typed test-only decoder.
- The fixture suite discovers every pot JSON fixture and exercises deterministic
  `SidePotBuilder` slices plus balanced `PotEngine` settlement.
- No pot engine, ledger, protocol, variant, app, or package boundary changed.

## Recent T335 Changes

- The root core event-sequence fixture now contains canonical event hashes and a
  contiguous hash chain instead of placeholders.
- A typed test-only loader validates every root core event fixture's sequence
  and chain, and the fixture replays through the default `CoreReducer`.
- No reducer, protocol, variant, app, or package boundary changed.

## Recent T336 Changes

- Centralized the existing operational peer-identity rule in
  `NetworkInputLimits` and applied it across network bootstrap, path selection,
  election, endpoint parsing, transport validation, replay protection, and
  confidence classification.
- Generic session/table scope identities continue to use the existing safe
  identity predicate; reserved peer sentinels cannot become actionable route
  or transport identities.
- Complete `peerdeal_network` test suite: passed (79 tests); direct package
  analysis: passed.

## Recent T337 Changes

- Applied the existing signed 32-bit transport sequence ceiling to network
  frame validation and replay protection, matching the native bridge and
  Android/Windows host envelope.
- Extended the native contract-bound checker and its tests to detect drift
  between the network and native sequence declarations.
- Complete `peerdeal_network` test suite: passed (81 tests); direct package
  analysis, checker tests, and native contract-bound check: passed.

## Recent T338 Changes

- Mirrored mobile and desktop native transport session factories now default to
  `NativeBridgePayloadLimits.maxTransportPayloadBytes` (60 KiB), matching the
  existing native bridge and Android/Windows host contract.
- This removes the prior self-rejecting 64 KiB default while preserving the
  existing fail-closed validation for explicit invalid or oversized limits.
- Direct analysis of both app packages passed. The focused Flutter runner
  produced no output during a bounded attempt and was stopped; no Flutter test
  pass is claimed.

## Recent T339 Changes

- Extended `scripts/check_native_contract_bounds.py` to load both mirrored app
  native transport factories and require their default `maxPayloadBytes` to
  reference the canonical native 60 KiB limit.
- Added negative-path checker coverage for app-default drift; the live checker
  and its 7-test unit suite pass.
- Runtime behavior and package ownership remain unchanged.

## Recent T340 Changes

- Mirrored direct native transport sinks now validate against the existing
  60 KiB native payload ceiling by default.
- Mirrored native transport drains reject oversized custom-bridge frames before
  network receiver or session-handler dispatch.
- Direct analysis of both app packages passed. The focused Flutter runner
  produced no output during a bounded attempt and was stopped; no Flutter test
  pass is claimed.

## Recent T341 Changes

- Mirrored direct native receive drains now require an operational peer identity
  before bridge receive lookup; reserved `none`, `unresolved`, and
  `peer::reserved` scopes fail closed.
- Mirrored app table session sources and provisioners use the same existing
  operational-peer predicate while keeping the native safe-text contract for
  session IDs.
- Added invalid-scope regressions. Direct analysis of both app packages and
  repository static gates passed; the focused Flutter runner produced no output
  during a bounded attempt and was stopped, so no Flutter test pass is claimed.

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
   `AppHoldemProductionSessionConfigurationFactory` from the real
   session/state and local identity flow through the app-owned typed loader
   after first-join and rejoin handoff, using the persisted configuration
   factory where its recovery-backed inputs are valid;
   add native peer transport device/network validation and final UX validation
   separately.
4. Continue production hardening items recorded in `docs/PRODUCTION_READINESS.md`
   without crossing locked package boundaries.

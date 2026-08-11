# Handoff

Generated: 2026-08-10

## Current Work

Trinity baseline retrofit T1 is complete, CI/dependency hardening is complete,
the T4 Android plus Windows secure-key and capture-enforcement host slices are
implemented, T19 production entrypoint native-readiness activation is wired,
and T20 local-network endpoint projection, T21 Android secure-storage bound
hardening, T22 protocol-native command validation, T23 removal of the
duplicate starter core API, T24 variant-to-core Hold'em event projection, and
T25 app-owned Hold'em session adoption, T26 remote Hold'em event
reconstruction, T27 app-owned Hold'em route orchestration, T28 typed
Hold'em production-route registration, T29 production Hold'em surface and
resumable publication hardening, T30 bounded Android/Windows host transport,
T31 app-owned production session composition, T32 resolved-invite production
session source/bootstrap handoff, T33 native transport lifecycle hardening,
T34 bounded secure-key method-channel calls, T35 bounded native transport
method-channel calls, T36 bounded local-network method-channel calls, T37
Android native transport receiver lifecycle hardening, T38 Windows native
transport socket lifecycle hardening, T39 Android secure-key teardown
hardening, T40 Windows native channel teardown hardening, T41 app-owned
production session bootstrap-route mounting, and T42 app-shell route-argument
handoff, T43 join-to-production session handoff, T44 bounded production-session
source loading, T45 cancellable production-session source loading, T46
app-shell bootstrap-route registration with default join-ready navigation,
T47 source-backed bootstrap-route assembly, T48 runtime-owned production
session configuration, T49 fail-closed Android release signing, T50 production
table UI accessibility/responsive hardening, T51 keyboard/focus control
hardening, T52 action hit-target hardening, T53 local-seat action routing,
T54 typed core table-state hydration, T55 typed Hold'em state hydration, and
T56 typed Hold'em event-cursor hydration, T57 typed persisted Hold'em source
hydration, T58 deterministic persisted recovery-suffix replay, T59 app-owned
local peer identity persistence, T60 provisioned-identity persisted-source
composition, T61 single-flight local identity provisioning, T62 post-save
identity verification, and T63 typed join-to-session context handoff
and T75 Android/Windows local-network host registration
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
- Hardened Android secure-key worker teardown so queued storage work fails closed
  after engine cleanup and late main-looper results cannot return key material.
- Removed the generated release debug-signing fallback; operator-owned Android signing is environment-driven and fail-closed.
- Hardened the shared app-shell action/fact semantics and narrow-layout behavior;
  mirrored production Hold'em surfaces now render human-readable phase, round,
  actor, and seats state without exposing enum internals.
- Shared action controls now own pointer/keyboard focus and bind Enter, numpad
  Enter, and Space to the same visible action without layout shift.
- Shared action controls now guarantee a 48 logical-pixel minimum interactive
  height for touch and pointer use.
- Mirrored production Hold'em table actions now emit the configured local seat
  for Fold, Call/Check, and All-in actions instead of assuming seat zero.
- Core `TableState` now has a strict JSON hydration parser matching its existing
  persistence shape, including phase and metadata-key validation.
- Variant-owned `HoldemHandState` and `HoldemSeatState` now have strict JSON
  serialization and hydration for durable source integrations.
- Variant-owned `HoldemEventCursor` now has strict JSON serialization and
  hydration while requiring caller-owned event policy factories.
- Added `HoldemStateSnapshot` plus mirrored app-owned persisted production
  session sources. They hydrate the typed table, Hold'em hand, and event
  cursor state from the existing recovery store and fail closed on missing,
  unsupported, mismatched, or unreplayed snapshot data.
- Added variant-owned atomic recovery replay. It validates cursor/hash-chain
  continuity, applies universal core events, applies hand-scoped Hold'em
  events, and never exposes a partially replayed state.
- Added mirrored app-owned local peer identity loaders, writers, and
  provisioners over the generic secure-key bridge. They persist one active
  identity, fail closed on unavailable or ambiguous storage, and generate a
  cryptographically random ID only when no identity is present.
- Added mirrored app-owned composition factories that provision or reuse the
  local identity, map it into the existing persisted production-session input,
  and apply caller-owned route, remote-peer, local-seat, and close-event policy.
  They do not invent database selection or remote-peer discovery.
- Hardened mirrored local identity provisioners with a single-flight guard so
  concurrent first-use callers share one load/generation/save operation instead
  of racing to overwrite the persisted identity. Failed operations clear the
  guard so a later caller can retry.
- Added fail-closed read-back verification after a newly generated identity is
  saved. The provisioner only returns success when native storage reloads the
  same peer ID, detecting competing writers or inconsistent persistence.
- Added mirrored typed first-join session context handoff. The join bootstrap
  selects the first reachable peer from its bounded candidate plan, accepted
  governance carries the assigned seat, and the app shell passes both through
  a context-aware persisted source/bootstrap route. Invite-only handoff stays
  available for legacy sources. Accepted rejoin governance can now provide the
  remote peer binding and assigned seat for the same context path; missing
  governance peer data still fails closed.
- Added mirrored async `AppHoldemProductionSessionConfiguration
  .fromPersistedLocalIdentity(...)` composition. It provisions the app-owned
  local identity, connects the existing recovery store to the validated
  bootstrap route, and retains caller-owned route policy and event factories.
- Added the generated Windows desktop host and generic Credential Manager-backed
  secure-key channel with bounded versioned records.
- Generic secure-key method-channel load, save, and delete calls now use a
  bounded five-second default deadline and return stable fail-closed timeout
  results.
- Mirrored receipt routes now stop at a stable unavailable-artifact rejection
  before invoking native key verification, so failed export factories cannot
  leave secure-storage calls pending.
- Generic native transport capability, send, and receive method-channel calls
  now use a bounded five-second default deadline and return stable fail-closed
  timeout results.
- App-owned table routes now pass lifecycle cancellation to the default native
  transport bridge, canceling in-flight calls during replacement or disposal.
- Generic local-network capability and discovery method-channel calls now use a
  bounded five-second default deadline and stable fail-closed timeout results.
  Default app bootstrap loaders carry caller cancellation, and table routes
  cancel them during replacement or disposal.
- Generic capture capability and blocking method-channel calls now use a
  bounded five-second default deadline and stable fail-closed timeout results;
  non-positive timeout configuration is rejected before platform calls.
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
- Added mirrored app-owned `AppHoldemTableSessionRuntime` owners. They project
  local start/action/showdown/settlement operations through the variant adapter,
  then commit the resulting envelopes through the app session boundary.
- Added atomic non-retention event-batch preflight to both app table runtimes;
  variant state and event cursors advance only after the complete batch commits.
- Added exact remote `HoldemEventCursor` acceptance and the public
  variant-owned `HoldemEventReducer`. Mirrored app runtimes now preflight
  remote cursor and variant state before committing the event through core;
  optional transport handlers/provisioners can use this path without changing
  the generic non-variant route.
- Added mirrored `AppHoldemTableSessionRoute` owners that compose the validated
  runtime with transport provisioning, source lifecycle, and accepted-event
  surface refresh. Route contexts can create an
  `AppHoldemProjectionTransportPublisher` for canonical outbound frames; a
  partial send is reported without replaying variant rules.
- Added mirrored typed `AppHoldemProductionRouteRegistration` owners. App
  shells merge them into validated production route maps, auto-register
  navigation metadata, and native-gate the route before mounting its surface.
- Added mirrored `AppHoldemProductionTableSurface` owners and default route
  registration factories. They render bounded runtime projection state, expose
  local-seat controls only when transport-backed publication is ready, and
  resume partial projection sends from the first unsent event.
- Added mirrored `AppHoldemProductionSessionFactory` owners. They compose the
  existing table and Hold'em runtimes plus the default production surface from
  injected canonical state, cursor, close-retention adapter, and peer identity;
  they do not derive product IDs, persistence, or game state.
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
- Added mirrored app-owned production session source/bootstrap contracts. A
  resolved invite now reaches the bootstrap with product-loaded canonical state,
  close-retention wiring, and local identity; table/session/protocol mismatches
  fail before the production route is composed.
- Added mirrored app-owned production session bootstrap-route adapters. Product
  callers can pass a resolved invite through route arguments, invoke the
  existing bootstrap, and mount its validated route; missing arguments, source
  failures, and route-path mismatches fail closed without exposing raw errors.
- Added an optional opaque route-argument payload to mirrored
  `PeerDealAppNavigationEntry` values. Default home navigation forwards the
  payload through `RouteSettings.arguments`, allowing a product caller to
  launch the T41 adapter without moving session semantics into the app shell.
- Mounted join routes now preserve only identity-safe invites from accepted
  joined/rejoined outcomes and expose an optional post-frame
  `JoinFlowReadyHandler` through both app runtimes. Product callers can use the
  handler to push the T41 adapter; rejected outcomes, stale async outcomes, and
  handler failures do not expose or navigate with unsafe data.
- Successful first-join and rejoin outcomes now retain their validated resolved
  invite for product session handoff. Demo and compiled Game File data remain
  non-authoritative and are not used to derive live session identity.
- Mirrored production session bootstraps now bound product-owned source loading
  with a configurable positive timeout and a five-second default. Mounted
  bootstrap routes show a loading surface while hydration is pending and use
  the existing route-unavailable fallback after timeout or other failure. The
  source remains responsible for cancellation beneath this boundary.
- Mirrored app shells now accept an optional
  `AppHoldemProductionSessionBootstrapRouteRegistration`. It mounts the
  existing bootstrap adapter, merges its path into the production route map and
  native-readiness gate, and supplies cached default join-ready navigation when
  no explicit handler is configured. The registration does not create product
  state, local identity, persistence, or a concrete source.
- The mirrored registration now exposes `fromSource(...)`, assembling a
  product-owned source with the existing bootstrap, optional factory, and
  positive load timeout at one app boundary. It does not invent or persist
  product state.
- Added mirrored `AppHoldemProductionSessionConfiguration.fromSource(...)`
  runtime configuration. Each shell derives one stable registration for route
  merging, readiness, and default join handoff; supplying both explicit and
  configured registrations fails closed with `StateError`.
- Android release Gradle tasks now fail before artifact assembly when all four
  operator-owned signing values are not present and valid; debug builds remain
  the explicit unsigned validation path.
- Hardened Android native transport teardown and executor rejection handling so
  accepted method calls resolve with bounded fail-closed payloads.
- Hardened Windows native transport setup cleanup so partial Winsock/socket
  initialization cannot leave resources alive or advertise a broken host.
- Hardened Windows native transport socket ownership across method calls, the
  receive thread, and teardown; shutdown invalidates the handle before closing
  and joining the receiver, then clears queued frames.

## Review Notes

- Bundle text copied under `spec/` is normalized for repository source-text gates; original hashes are recorded in the manifest.
- Remaining production software gaps are tracked in `HANDOFF_QUEUE.md` and existing production-readiness docs.
- Android and Windows host work is available for runtime persistence, capture,
  and transport validation. The app-owned non-demo Hold'em route orchestration,
  typed route registration, default production surface, and production session
  composition and source/bootstrap seams are implemented. Remaining gaps are
  device/network validation, endpoint/source provisioning, other-platform
  native work, production database persistence, concrete product route-policy
  and state provisioning, and final product navigation/UX validation. The
  generic app-shell route-argument handoff is implemented; it does not create
  a product source or durable session state. The registered route now closes the
  default app-flow handoff while preserving explicit callback overrides. T48
  also closes the runtime configuration path without inventing product state.

- Windows native hardening was compiled and smoke-tested after the capture and
  credential-shape checks; runtime OS/profile validation remains operator-owned.
- The T30 Windows debug host rebuild and five-second smoke launch passed. The
  T30 Android debug APK build passed after the pinned NDK installation was
  repaired. No Android device or emulator was attached, so runtime persistence,
  capture, and cross-device transport remain unverified.

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
- T25 focused mobile and desktop Hold'em app-session suites: passed, including
  local action rejection, atomic batch preflight, and showdown/settlement.
- T26 focused variant reducer, mobile/desktop Hold'em app-session, and
  mobile/desktop transport-handler suites: passed, including cursor tamper
  rejection, action/street parity, public showdown/settlement reconstruction,
  core-rejection rollback, and canonical frame routing.
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
- T26 full repository analyze, boundary, source-text, serialized test, and
  dependency-audit gates: passed. Dependency audit reported 0 actionable
  upgrades; 10 newer versions remain blocked by the current toolchain.
- T26 `git diff --check`: passed.
- T27 focused mobile and desktop route and projection-publisher tests: passed,
  including inbound accepted-event surface refresh, unavailable transport
  fallback, canonical outbound frames, and partial-send reporting.
- T28 focused mobile and desktop route-registration tests: passed, including
  automatic navigation registration, native-ready mounting, and fail-closed
  mounting without readiness.
- T29 focused mobile and desktop production-surface route tests: passed, including
  default surface mounting, transport-gated controls, and canonical local-call
  publication.
- T29 mobile and desktop runtime/publisher tests: passed, including resumable
  partial-send publication from the first unsent event.
- T29 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed. Dependency audit reported 0 actionable
  upgrades; 11 newer versions remain blocked by the current toolchain.
- T30 Windows `flutter build windows --debug --no-pub`: passed after adding the
  bounded native multicast transport host.
- T30 Windows host smoke launch: stayed alive for five seconds and was stopped
  cleanly.
- T30 Android `flutter build apk --debug --no-pub`: passed after repairing the
  pinned NDK and fixing the existing Kotlin secure-key nullability errors.
- T30 `adb devices`: no Android device or emulator attached; Android runtime
  persistence, capture, and cross-device transport behavior remain unverified.
- T33 Windows `flutter build windows --debug --no-pub`: passed.
- T33 Android `flutter build apk --debug --no-pub`: passed.
- T30 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 toolchain-blocked newer versions.
- T31 focused mobile and desktop production-session factory tests: passed, 2
  tests per app.
- T32 focused mobile and desktop production-session bootstrap tests: passed, 3
  tests per app; join orchestrator tests also passed with resolved-invite
  propagation assertions.
- T31 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 toolchain-blocked newer versions.
- T31 `git diff --check`: passed.
- T33 focused native transport bridge tests: passed, 7 tests.
- T33 native transport lifecycle hardening host builds: passed on Windows and
  Android debug targets.
- T34 focused secure-key method-channel tests: passed, 12 tests; mirrored
  receipt-route tests passed with unavailable-artifact coverage.
- T34 mobile and desktop full Flutter test suites: passed.
- T34 final `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `diff --check` gates: passed; dependency audit reported zero actionable
  upgrades.
- T35 focused native transport method-channel tests: passed, 13 tests,
  including capability, send, receive, timeout, cancellation, and validation.
- T35 mobile and desktop full Flutter suites plus the final serialized Melos
  test gate: passed.
- T36 focused local-network method-channel tests: passed, 10 tests; mirrored
  mobile and desktop bootstrap-loader/table-route tests: passed, 17 tests each.
- T36 full analyzer, boundary-check, source-text, serialized test, and
  dependency-audit gates: passed; dependency audit reported zero actionable
  upgrades.
- T37 Android debug APK build: passed. Android receiver setup/teardown now
  closes partial socket and multicast-lock resources and clears queued frames.
- T38 focused desktop transport tests: passed, 45 tests.
- T38 `flutter build windows --debug --no-pub`: passed.
- T38 Windows host smoke launch: stayed alive for five seconds and stopped
  cleanly.
- T38 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- T38 `git diff --check`: passed.
- T39 focused mobile secure-key/receipt and Android manifest tests: passed, 40
  tests.
- T39 Android `flutter build apk --debug --no-pub`: passed.
- T39 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- T39 `git diff --check`: passed.
- T40 focused desktop receipt, secure-key loader, and capture coordinator tests:
  passed, 21 tests.
- T40 `flutter build windows --debug --no-pub`: passed.
- T40 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- T40 `git diff --check`: passed.
- T41 focused mobile and desktop bootstrap-route tests: passed, four tests each.
- T41 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- T41 Dart format and `git diff --check`: passed.
- T42 focused mobile and desktop app-shell tests: passed, 74 tests each.
- T43 focused mobile and desktop join-flow/app-shell suites: passed, 92 tests
  each.
- T45 focused mobile and desktop production-session bootstrap and route suites:
  passed, 13 tests each.
- T45 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- T45 `git diff --check`: passed.
- T46 focused mobile and desktop app-shell suites: passed, 77 tests each.
- T46 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- T46 Dart format and `git diff --check`: passed.
- T47 focused mobile and desktop app-shell suites: passed, 77 tests each.
- T47 Android `flutter build apk --debug --no-pub`: passed.
- T47 Windows `flutter build windows --debug --no-pub`: passed.
- T47 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- T47 Dart format and `git diff --check`: passed.
- T48 focused mobile and desktop app-shell suites: passed, 78 tests each.
- T48 Android `flutter build apk --debug --no-pub`: passed.
- T48 Windows `flutter build windows --debug --no-pub`: passed.
- T48 full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions below the current toolchain ceiling.
- T48 Dart format and `git diff --check`: passed.
- T49 Android release build without signing values: failed closed at Gradle
  configuration with the expected stable signing error.
- T49 Android debug `flutter build apk --debug --no-pub`: passed.
- T50 focused UI-kit widget tests: passed, 3 tests.
- T50 focused mobile and desktop production table/session widget suites: passed,
  8 tests each.
- T50 Android `flutter build apk --debug --no-pub`: passed.
- T50 Windows `flutter build windows --debug --no-pub`: passed.
- T50 Dart format and `rtk git diff --check`: passed.
- T51 focused UI-kit widget tests: passed, 4 tests.
- T52 focused UI-kit widget tests: passed, 4 tests.
- T53 focused mobile and desktop production-table route tests: passed, 8 tests
  each, including canonical non-zero local-seat event attribution.
- T54 focused core invariant/model tests: passed, 13 tests.
- T55 focused variant state persistence tests: passed, 3 tests.
- T56 focused event-cursor persistence tests: passed, 3 tests.
- T57 focused persisted-source tests: passed, 4 tests each in mobile and
  desktop.
- T58 focused variant recovery-replay tests: passed, 2 tests.
- T58 focused persisted-source tests: passed, 5 tests each in mobile and
  desktop.
- T59 focused local-identity tests: passed, 5 tests each in mobile and
  desktop.
- T60 focused persisted-source composition tests: passed, 6 tests each in
  mobile and desktop.
- T61 focused local-identity tests: passed, 6 tests each in mobile and
  desktop, including overlapping provisioning calls.
- T62 focused local-identity tests: passed, 7 tests each in mobile and
  desktop, including post-save contention detection.
- T63 focused mobile and desktop join/session tests passed, including
  selected-peer propagation, typed context route handoff, context-aware
  bootstrap loading, and persisted peer/seat input construction.
- T64 focused mobile and desktop join-flow suites passed, including
  governance-bound rejoin peer propagation and fail-closed missing-peer
  handoff.
- T65 focused mobile and desktop persisted-session suites passed, including
  configuration construction from persisted state and native local identity;
  both app analyzers passed.

## Recent T66 Changes

- Mirrored `AppHoldemProductionSessionConfiguration` factories now reject a
  non-positive source-load timeout before route assembly or persisted local
  identity provisioning.
- Focused mobile and desktop persisted-session suites passed with 9 tests each,
  including the no-secure-key-mutation regression; the full repository gates
  remain required before commit.

## Recent T67 Changes

- Mirrored persisted Hold'em route policies now fail before native identity
  provisioning when path, navigation label, remote peer identity, or local seat
  policy is invalid.
- Focused mobile and desktop persisted-session suites passed with 10 tests each,
  including the invalid-route-policy no-secure-key-mutation regression.

## Recent T68 Changes

- Production persisted-session configuration now uses a lazy identity
  provisioner source path. Invite-scoped snapshot validation and recovery replay
  complete before native local identity can be created or saved.
- Missing or rejected persisted state therefore fails without secure-key
  mutation; focused mobile and desktop persisted-session suites passed with
  12 tests each.

## Recent T69 Changes

- Persisted invite and session-context source loads now honor the route
  cancellation signal before recovery access and around lazy identity
  provisioning.
- Cancelled loads fail closed with a stable `StateError`; focused mobile and
  desktop persisted-session suites passed with 13 tests each, including the
  no-side-effect pre-cancel regression.

## Recent T70 Changes

- Generic capture capability and blocking method-channel calls now fail closed
  after the bounded five-second default deadline instead of remaining pending
  indefinitely on a torn-down or unresponsive plugin.
- Focused capture bridge tests passed, including timeout and non-positive
  timeout validation coverage.

## Recent T71 Changes

- Generic secure-key method-channel load/save/delete calls now accept an
  additive per-call cancellation capability and return stable fail-closed
  cancellation results before the five-second deadline.
- Mirrored app local-identity loaders, writers, provisioners, and persisted
  Hold'em sources propagate the route cancellation signal through that
  capability while preserving legacy bridge implementations.
- Focused secure-storage bridge tests passed with cancellation coverage; the
  Dart wait is cancellable, but an already-dispatched native mutation cannot be
  retroactively withdrawn and remains an idempotent host responsibility.

## Recent T72 Changes

- Mirrored receipt key-ring loaders now expose an additive cancellable load
  capability and forward route cancellation to secure-key bridges that support
  it; legacy secure-key bridges retain the existing load path.
- Receipt artifact verifiers and presenters propagate that capability, and
  mounted receipt routes cancel pending native-backed verification on route
  replacement or disposal.
- Focused mirrored receipt loader, verifier, presenter, and route suites passed.

Remaining:
- Native host persistence behavior, already-dispatched operation semantics,
  device/profile validation, release signing, and product database/state wiring
  remain external or integration-owned.

## Recent T73 Changes

- Mirrored app transport provisioners now race injected session loading against
  route cancellation and fail closed with a stable unavailable result.
- Mirrored transport session factories carry the route cancellation signal into
  provisioned sources. Sources also cancel pending polls on route disposal,
  while retaining the underlying in-flight drain registration until it settles;
  this prevents cancellation from starting overlapping native drains.
- Focused mobile and desktop transport source/provisioner suites passed with
  cancellation and no-overlap coverage.

Remaining:
- Native calls already dispatched remain host-owned; native transport
  reachability, device/profile validation, release signing, other-platform
  hosts, and product database/state wiring remain external or integration-owned.

## Recent T74 Changes

- Android native transport frame decoding now uses a reporting UTF-8 decoder
  and rejects malformed or C1-control-bearing session and peer identities.
- Windows native transport now validates UTF-8 through the Win32 decoder and
  applies matching whitespace/control checks before accepting frame fields.
- Android APK and Windows debug builds passed after the mirrored host change.

Remaining:
- Device/network reachability, firewall and multicast behavior, runtime
  capture/key validation, release signing, other-platform hosts, and product
  database/state wiring remain external or integration-owned.

## Recent T75 Changes

- Android and Windows now register the locked
  `peerdeal/native_bridges/local_network` channel.
- Both hosts report bounded active-interface capability facts and generic
  interface hints without exposing adapter paths or peer data.
- Peer discovery remains explicitly unsupported and returns an empty endpoint
  list because no discovery advertisement protocol or endpoint provisioning
  contract exists in this repository.
- Android APK and Windows debug builds passed after the mirrored host change.

Remaining:
- A protocol-owned peer discovery advertisement and product endpoint
  provisioning are still required before `foundEndpoints` can be populated.
  Device/network reachability, runtime capture/key validation, release signing,
  other-platform hosts, and product database/state wiring remain external or
  integration-owned.

## Recent T76 Changes

- Added additive cancellable capture capability and action bridge interfaces;
  existing non-cancellable bridge implementations remain compatible.
- Generic capture method-channel capability and blocking calls now race the
  existing five-second deadline against caller cancellation and fail closed
  with stable results.
- Mirrored capture coordinators and receipt presenters forward route
  cancellation into native capture calls, while release remains uncancelled
  so route teardown can still disable native blocking.

Focused verification passed:
- Native capture bridge: 11 tests.
- Mirrored mobile and desktop capture coordinators: 8 tests each.
- Mirrored mobile and desktop receipt presenters: 4 tests each.

Remaining:
- Already-dispatched native calls remain host-owned. Android/Windows runtime
  capture validation, release signing, other-platform hosts, and product
  database/state wiring remain external or integration-owned.

## Recent T77 Changes

- Added an additive cancellable app-support directory bridge capability while
  preserving the existing base interface.
- Generic app-support directory method-channel lookup now uses a bounded
  five-second deadline and stable fail-closed timeout/cancellation results.
- Mirrored recovery persistence factories forward optional cancellation when
  the injected directory bridge supports it; unavailable or cancelled lookup
  still returns no persistence factory.

Focused verification passed:
- Native app-storage bridge: 7 tests.
- Mirrored mobile and desktop recovery-factory suites: 13 tests each.

Remaining:
- Native directory calls already dispatched remain host-owned. Runtime
  persistence validation, product database/state provisioning, other-platform
  storage, and release/operator validation remain external or integration-owned.

## Recent T78 Changes

- Added additive cancellable local-network and native-transport capability
  interfaces without changing the existing base bridge contracts.
- Mirrored app-native readiness loaders now forward optional cancellation to
  compatible capture, local-network, transport, and secure-key bridges.
- App shells cancel stale readiness aggregation when the injected loader changes
  and when the app state disposes, preventing old route work from surviving its
  owner lifecycle.

Focused verification passed:
- Native local-network bridge: 11 tests.
- Native transport bridge: 13 tests.
- Mirrored mobile and desktop readiness-loader suites: 7 tests each.
- Full repository test gate passed.

Remaining:
- Already-dispatched native calls remain host-owned. Android/Windows runtime
  readiness, device/network reachability, release signing, other-platform
  implementations, and product database/state wiring remain external or
  integration-owned.

## Recent T79 Changes

- Added a CI job that compiles the Android debug APK on Ubuntu.
- Added a separate CI job that compiles the Windows debug host on Windows.
- Kept release signing and runtime/device checks separate from compile-only
  automation because they require operator credentials or physical runtime
  validation.

Local host verification passed:
- `flutter build apk --debug --no-pub`
- `flutter build windows --no-pub`

Remaining:
- CI compile success does not prove Android/Windows secure-key persistence,
  capture enforcement, firewall or cross-device reachability, release signing,
  other-platform hosts, or product database/state provisioning.

## Recent T80 Changes

- Added an expected-failure Android CI step that runs a release build without
  signing credentials and requires the Gradle fail-closed guard to reject it.
- The check prevents accidental unsigned release paths while preserving
  operator-owned signing credentials outside CI.

Local verification passed: credential-free `assembleRelease` stopped at the
signing guard with the required `PEERDEAL_ANDROID_*` message.

Remaining:
- A successful signed release still requires operator-owned credentials and
  release/profile/device validation; this change proves only the negative guard.

## Recent T81 Changes

- Tightened the Android release-signing CI assertion to blank all four signing
  variables explicitly.
- The expected-failure step now requires the exact Gradle signing diagnostic,
  so unrelated build failures cannot falsely pass the guard.

Remaining:
- Signed release output, operator credential validation, and runtime/device
  release validation remain external.

## Recent T82 Changes

- Mounted mobile and desktop join routes now cancel the active outcome when a
  mode/dependency replacement or route disposal supersedes it.
- Join orchestration checks cancellation between pre-commit stages and refuses
  to advance into governance after a cancelled bootstrap.
- Native join bootstrap forwards the app-owned signal to cancellable local-network
  bridges while retaining the legacy bridge contract.

Focused mobile and desktop join-flow tests passed, including route disposal,
bootstrap forwarding, and no-governance-after-cancellation coverage.

Remaining:
- Already-dispatched adapter or governance calls remain owner-hosted; signed
  release output, credentials, and runtime/device validation remain external.

## Recent T83 Changes

- Mirrored receipt key-ring provisioners now single-flight concurrent
  `ensureActiveKeys()` calls.
- Concurrent receipt exports share one load/provision operation, so native key
  storage cannot be raced by duplicate active-key creation within one app
  process.
- The in-flight guard clears after success or failure, preserving retry
  behavior after a transient native-storage error.

Focused mobile and desktop provisioner tests passed, including concurrent-call
coverage.

Remaining:
- Cross-process/native storage atomicity, runtime persistence validation,
  signed release output, credentials, and product database/state wiring remain
  external or integration-owned.

## Recent T84 Changes

- Mirrored receipt key-ring provisioners now reload native storage after any
  successful key creation.
- Provisioning returns a stable failure and an empty key ring unless the
  persisted active signing and encryption key IDs and secrets match the keys
  that were provisioned.
- Existing active rings avoid an unnecessary write or verification reload;
  transient verification failures remain retryable because the single-flight
  guard still clears on every outcome.

Focused mobile and desktop provisioner tests passed, including read-back
mismatch fail-closed coverage.

Remaining:
- Cross-process/native storage atomicity, runtime persistence validation,
  signed release output, credentials, and product database/state wiring remain
  external or integration-owned.

## Recent T85 Changes

- Mirrored app shells now carry an additive cancellable receipt export callback
  from runtime configuration into the mounted receipt route.
- Route replacement or disposal forwards its signal through export key
  provisioning, secure key writes, and the existing cancellable native bridge.
- The legacy one-argument export callback remains supported; conflicting export
  sources fail closed.

Focused mobile and desktop export-factory and route tests passed, including
pending native export cancellation on route disposal.

Remaining:
- Already-dispatched native mutations remain host-owned. Cross-process/native
  storage atomicity, runtime/device validation, signed release output,
  credentials, and product database/state wiring remain external or
  integration-owned.

## Recent T86 Changes

- The Windows secure-key host now serializes each namespace with a Local named
  mutex across PeerDeal app processes for load/save/delete operations.
- Mutex acquisition is bounded at five seconds and fails closed, matching the
  generic native secure-storage deadline instead of allowing an unbounded host
  wait.

Windows host compilation passed. Android multi-process storage semantics,
compare-and-swap behavior, runtime/device validation, signing, and product
state wiring remain external or integration-owned.

## Recent T87 Changes

- The Android secure-key host now serializes each namespace with a private
  hash-named file lock across PeerDeal app processes for load/save/delete.
- Encrypted envelopes now live in private `noBackupFilesDir` files, written via
  a flushed and synced temporary file replacement; legacy preference records
  migrate under the same namespace lock.
- Lock acquisition uses bounded five-second `tryLock` retries and fails closed
  instead of allowing an unbounded storage wait.

Android debug APK compilation passed. Compare-and-swap semantics, runtime/device
validation, signing, and product state wiring remain external or
integration-owned.

## Recent T88 Changes

- Generic secure-key snapshots now carry a nonnegative namespace revision, and
  the method-channel seam exposes additive conditional save/delete operations
  that return explicit stale-writer conflicts while preserving legacy methods.
- Mirrored receipt key-ring and local peer-identity writers pass the loaded
  revision into conditional mutations when supported, refresh on conflicts, and
  fail closed when no competing valid record can be recovered.
- Android encrypted private-file envelopes and Windows Credential Manager v2
  envelopes persist revisions, preserve tombstone revisions for empty namespaces,
  and accept legacy storage formats with revision zero.
- Focused bridge and app identity tests passed, and Android debug APK plus
  Windows debug host builds passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed. Dependency audit
  reports zero actionable upgrades and 11 newer versions below the current
  toolchain ceiling.

Runtime/device persistence and capture validation, other-platform native
implementations, operator-owned release signing, and concrete product database
or session-state wiring remain external or integration-owned.

## Recent T89 Changes

- Added `tool/windows_native_host_smoke.dart`, a dependency-free desktop smoke
  target that uses the existing public native bridge contracts rather than test
  doubles.
- The built Windows host executed app-support lookup, capture capability plus
  enable/release, local-network capability/discovery, transport capability and
  receive, and secure-key save/read-back, stale-writer conflict, conditional
  replacement/delete, and tombstone read-back checks successfully.
- The host's UDP multicast send returned its stable `Native transport send
  failed` result in this environment. The smoke target records that warning
  without hiding it; firewall, interface, and cross-device reachability remain
  external validation.

The direct smoke executable exited cleanly. No Android device or emulator was
available for the corresponding Android runtime pass.

Full analyze, boundary-check, source-text, serialized test, dependency-audit,
and `git diff --check` gates passed. Dependency audit reports zero actionable
upgrades and 11 newer versions below the current toolchain ceiling.

## Recent T90 Changes

- Fixed the native transport contract mismatch in both locked platform hosts:
  Dart sends `sendFrame` arguments as a nested `frame` map, and Android and
  Windows now unwrap that map before validation and encoding.
- Windows native transport now selects an operational IPv4 multicast interface
  by adapter metric and applies it to multicast membership and outbound sends.
- Direct Windows host smoke passed app storage, capture, local-network,
  transport capability/send/receive, and secure-key CAS/tombstone checks with
  exit code 0. Android debug APK compilation passed.

Runtime/device validation, cross-device multicast reachability, operator-owned
release signing, other-platform native implementations, and concrete product
database or session-state wiring remain external or integration-owned.

## Recent T91 Changes

- Android native multicast transport now selects an operational non-loopback
  IPv4 interface, prefers Wi-Fi/Ethernet deterministically, and assigns that
  interface to both outbound multicast sockets and the receiver.
- Android transport fails closed when no usable multicast interface exists,
  instead of reporting a socket path that cannot select a local network.
- Android debug APK compilation passed. No Android device or emulator is
  attached, so runtime persistence/capture and cross-device reachability remain
  external validation.

## Recent T92 Changes

- Added `apps/peerdeal_desktop/tool/run_windows_native_host_smoke.ps1`, a
  bounded PowerShell runner for the existing public-contract Windows native
  smoke target.
- The runner captures stdout/stderr, requires the stable
  `PEERDEAL_NATIVE_HOST_SMOKE_PASS` marker, rejects nonzero exits, and
  terminates timed-out hosts.
- CI now builds and executes the smoke target. Local execution passed app
  storage, capture, local-network, transport, and secure-key checkpoints.

The smoke gate does not claim firewall, Android device, release-signing, or
cross-device reachability validation; those remain external.

## Recent T93 Changes

- Added mirrored `AppHoldemProductionSessionConfigurationFactory` app
  boundaries that compose the existing recovery-store factory with native local
  identity provisioning and the persisted Hold'em configuration.
- The factory returns an explicit available/unavailable result, preserves
  recovery-root warnings, validates caller-owned route policy before identity
  work, and forwards deterministic event/replay/session configuration.
- Focused mobile and desktop factory suites passed. Full analyzer, boundary,
  source-text, serialized test, dependency-audit, and diff gates passed.

Remaining:
- A real product session owner must supply the route policy, authoritative
  snapshot writer/source, and invoke this factory from product startup. Native
  reachability, Android device validation, release signing, and other-platform
  implementations remain external or operator-owned.

## Recent T94 Changes

- Added mirrored `AppHoldemProductionSessionSnapshotWriter` app boundaries.
  The writer validates snapshot identity, table scope, cursor sequence, and
  last-event hash consistency before creating a typed `HoldemStateSnapshot`.
- It computes the locked canonical payload hash and delegates the envelope to
  the existing `RecoveryPersistenceStore`, returning stable fail-closed
  results on invalid input or persistence errors.
- T93 configuration-factory results now expose this writer over the same
  validated recovery store.

Remaining:
- Product code must supply authoritative table/hand state and event cursor,
  choose snapshot IDs, define event-log policy, and invoke the writer. The
  writer does not own product state selection, a database, retention, startup,
  native reachability, device validation, or release signing.

## Recent T95 Changes

- Hardened `JsonFileRecoveryPersistenceStore` with a stable per-scope OS file
  lock around hydrate-modify-write transactions, reads, and wipes.
- Lock handles are closed in all paths so the operating system releases the
  advisory lock after process failure; lock acquisition failures return a
  stable fatal persistence result.
- Updated file-store coverage for durable lock records without changing the
  public recovery-store contract or package boundaries.

Remaining:
- This strengthens the JSON recovery fallback but does not replace it with a
  production database or prove platform filesystem, device, or cross-device
  runtime behavior.

## Recent T96 Changes

- Added mirrored `AppHoldemProductionSessionPersistenceWriter` app boundaries.
  They validate a caller-supplied event suffix, append it to the recovery log,
  and then persist the resulting typed snapshot through the T94 writer.
- Retention events are rejected before storage so close/wipe policy remains in
  the existing retention adapter. Append failures prevent checkpoint writes;
  checkpoint failures report the durable event-log warning for suffix replay.
- T93 configuration-factory results now expose this writer alongside the typed
  snapshot writer over the same recovery store.

Remaining:
- Product startup must supply authoritative state, event IDs/hashes, snapshot
  IDs, and invoke the writer. It does not own product state selection, route
  policy, retention, database replacement, startup, or native/device validation.

## Recent T97 Changes

- Mirrored `AppPersistedHoldemProductionSessionRoutePolicy.buildInput(...)`
  now revalidates context-supplied remote peer IDs and local seats before
  constructing production session input.
- This closes the direct-source bypass around the bootstrap's first-join/rejoin
  metadata gates without changing route policy ownership or session state truth.

Remaining:
- Product startup, authoritative state, event identity, snapshot IDs, database
  persistence, native/device validation, and release signing remain separate.

## Recent T98 Changes

- Mirrored app persistence writers now preflight snapshot identity, metadata,
  scope/cursor/hash consistency, and typed Hold'em state before appending an
  event suffix.
- Invalid checkpoint input therefore cannot leave a durable event suffix behind;
  genuine checkpoint storage failures still report the durable suffix for
  replay.
- Focused mobile and desktop persistence suites plus all repository gates passed.

Remaining:
- Product startup, authoritative state, event identity, snapshot IDs, database
  persistence, native/device validation, and release signing remain separate.

## Recent T99 Changes

- Mirrored local-peer identity provisioners now track only non-cancellable
  operations and clear the in-flight slot only when the completed Future is
  still the tracked operation.
- A completed cancellable call can no longer clear a newer shared operation;
  per-call cancellation still reaches the native identity bridge.
- Focused mobile and desktop identity suites passed.

Remaining:
- Cross-process/native/device persistence validation, product startup,
  database persistence, and release signing remain separate.

## Recent T100 Changes

- `peerdeal_receipts` now exposes one shared `ReceiptExportLimits` contract for
  opaque export encoding/inspection and HMAC receipt encryption/decryption.
- Encoded bodies, decoded bodies, plaintext payloads, ciphertext strings, and
  nonces are bounded before base64, JSON, or keystream work; oversized values
  fail closed through the existing unavailable/rejected/format-error paths.
- Existing receipt format, signing, key-ring ownership, and package boundaries
  remain unchanged.

Remaining:
- Native key storage, Android/device and cross-device validation, product
  startup/database integration, and release signing remain separate.

## Recent T101 Changes

- `JsonFileRecoveryPersistenceStore` now enforces a positive configurable
  `maxFileBytes` limit, defaulting to 4 MiB.
- Oversized persisted files are rejected before JSON decoding, and oversized
  canonical recovery windows are rejected before temporary-file replacement.
- Both paths return the stable fatal
  `ERR_RECOVERY_PERSISTENCE_FILE_TOO_LARGE` conflict without hydrating or
  writing the oversized state.

Remaining:
- This bounds the JSON fallback only; production database replacement,
  platform filesystem/runtime validation, product startup, and release signing
  remain separate.

## Recent T102 Changes

- `peerdeal_native_bridges` now exposes one shared payload-limit contract for
  generic method-channel decoding.
- Transport frame batches, discovery collections, and secure-key record lists
  are bounded before iteration; frame payloads, identities, discovery values,
  key fields, and diagnostic strings are bounded before model construction.
- Oversized collections and malformed or oversized fields fail closed through
  the existing unavailable/empty result paths. Receipt semantics remain in the
  app and receipt packages.

Remaining:
- This hardens the generic Dart bridge boundary only; native host behavior,
  device persistence, cross-device network reachability, product startup,
  database persistence, and release signing remain separate.

## Recent T103 Changes

- Generic app-storage channel decoding now bounds platform directory paths to
  4096 UTF-8 bytes before exposing them as persistence roots.
- Generic capture capability/action decoding now bounds notes and warnings to
  512 UTF-8 bytes before exposing them to app orchestration.
- Oversized values fail closed through the existing unavailable or empty
  diagnostic paths, with focused regression coverage.

Remaining:
- Native host behavior, device persistence/capture enforcement, cross-device
  network reachability, product startup/database integration, and release
  signing remain separate.

## Recent T104 Changes

- Android local-network discovery now caps `NetworkInterface` enumeration at
  64 entries before filtering active interfaces.
- Windows local-network discovery now rejects adapter buffers above 1 MiB,
  caps adapter traversal at 64 entries, and caps each unicast-address scan at
  256 entries.
- Android and Windows debug host builds passed; the direct Windows native-host
  smoke passed all registered channel checks.

Remaining:
- Real-device behavior, cross-device network reachability, other-platform
  hosts, product startup/database integration, and release signing remain
  separate.

## Recent T105 Changes

- Android transport interface selection now caps `NetworkInterface` enumeration
  at 64 entries and each interface-address scan at 256 entries.
- Windows transport interface selection now rejects adapter buffers above 1 MiB
  and caps adapter traversal at 64 entries and unicast-address scans at 256.
- Android and Windows debug builds passed; the direct Windows native-host smoke
  passed transport send/receive and all other registered channel checks.

Remaining:
- Real-device behavior, cross-device network reachability, other-platform
  hosts, product startup/database integration, and release signing remain
  separate.

## Recent T106 Changes

- `peerdeal_sync` recovery stores now enforce configurable event-count and
  per-event byte limits, defaulting to 4,096 events and the protocol codec's
  64 KiB event bound.
- Oversized in-memory batches, hydrated JSON windows, and individual events
  fail closed before recovery state mutation with stable fatal conflicts.

Remaining:
- Production database replacement, platform/runtime persistence validation,
  other-platform hosts, product startup integration, and release signing
  remain separate.

## Recent T107 Changes

- `DefaultDiagnosticsScrubber` now bounds recursive maps and lists at 64
  entries, nested depth at 8, text at 512 UTF-8 bytes, and protocol
  diagnostics at 64 items.
- Overflow emits stable `<truncated>` markers or
  `ERR_DIAGNOSTICS_TRUNCATED` while existing redaction behavior is preserved.

Remaining:
- App rendering, production database replacement, platform/runtime validation,
  other-platform hosts, product startup integration, and release signing
  remain separate.

## Recent T108 Changes

- Added public `DealProofLimits` defaults for provider identity/reference text,
  maps, lists, nesting, node count, and canonical UTF-8 proof bytes.
- `DefaultProviderProofNormalizer` now accepts only bounded JSON-safe proofs,
  rejects unsupported/non-finite values and overflow before bundle creation,
  and shares one immutable bounded payload between normalized and raw views.

Remaining:
- Provider-specific proof semantics, product verification wiring, platform/
  device validation, production persistence, and release signing remain
  separate.

## Recent T109 Changes

- Added bounded deterministic canonical JSON writing in `peerdeal_protocol`
  with map/list, nesting, UTF-8 text, node, and encoded-byte limits.
- Event wire encode and decode validation now share the configured wire-byte
  cap and fail closed on unsupported values or non-string object keys before
  event processing.

Remaining:
- Protocol schema semantics, platform/runtime validation, product persistence,
  other-platform hosts, and release signing remain separate.

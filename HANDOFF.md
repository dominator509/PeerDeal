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
handoff, and T43 join-to-production session handoff
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
  native work, production database persistence, the concrete product source and
  local identity wiring, and final product navigation/UX validation. The
  generic app-shell route-argument handoff is implemented; it does not create
  a product source or durable session state. The join-ready callback now closes
  the app-flow handoff into that generic route seam.

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

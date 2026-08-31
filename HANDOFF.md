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
and T75 Android/Windows local-network host registration, T147 production
table lifecycle invalidation, T148 inbound checkpoint lifecycle invalidation,
and T149 cancelled native receive suppression, T150 source-owned drain
disposal cancellation, T168 exact inbound-event checkpoint identity, T169
immutable app-session diagnostics, T170 immutable startup diagnostics, T171
immutable local-identity diagnostics, T172 immutable readiness/transport
diagnostics, T173 immutable app-boundary collections, T174 immutable
native-bridge collections, T175 immutable network collections, T176
immutable sync/recovery collections, and T177 immutable replay collections,
and T318 shared production table failure-surface hardening, T319 production
table operational UI hierarchy hardening, and T320 transport replay-scope
admission serialization, T321 cross-platform transport sequence bounds,
T322 cross-platform transport payload bounds, T323 native transport contract
bound parity, T324 rejected protocol fixture enforcement, T325 wired
Hold'em opening-hand fixture persistence coverage, and T326 Hold'em fixture
breadth enforcement, T327 mode fixture breadth enforcement, and T328 replay
fixture breadth enforcement, and T329 sync recovery fixture breadth
enforcement, and T330 wizard fixture boundary enforcement, and T331 crypto
verification fixture boundary enforcement, and T332 receipt fixture
authorization boundary enforcement, and T333 privacy fixture policy boundary
enforcement, and T334 core pot fixture settlement boundary enforcement, and
T335 core event-sequence fixture hash-chain enforcement, T336 operational
network peer-identity boundary normalization, T337 network/native transport
sequence-bound parity, T338 app/native transport default-bound alignment,
T339 app/native transport default-bound checker enforcement, and T340 direct
native transport adapter payload enforcement, and T341 app/native operational
peer-scope normalization, and T342 mirrored app production-session
peer-identity normalization, T343 accepted session-context identity binding,
and T344 invite variant identity preservation and Holdem variant admission,
and T345 persisted-source and configuration-factory variant admission, and
T346 cancellation-before-native-dispatch hardening, and T347 cancellation-safe
app recovery factory loading, T348 cancellation-safe local identity
provisioning, T349 cancellation-safe receipt key provisioning, and T350
native-readiness payload contract alignment, T351 app-native transport
cancellation forwarding, T352 capture cancellation hardening, T353 bounded
network receive admission, T354 compatible dependency refresh, T355 bounded
Android/Windows local network discovery, T356 release-entrypoint demo
suppression, T357 signed Android release assembly, T358 Windows release host
smoke, and T359 Android release-signature verification are
implemented on branch
`retrofit/baseline-v1` from backup tag
`pre-retrofit-20260613T075234Z`.

## Current Production Hardening

The protocol now exposes a bounded, versioned HMAC-SHA256 session-message
contract. Mirrored production Hold'em routes authenticate canonical event bytes
with transport session, sender, recipient, and sequence scope and fail closed
when the app does not provide an authenticator or verification fails. Native
transport remains generic; the network validating receiver now rejects bounded
duplicate and stale frame sequences before handler dispatch. Key provisioning,
session authorization, rotation, real-device/network validation, product
session/database wiring, and final UX remain outside this software slice.

The T318 route hardening now keeps a supplied production table surface failure
inside the shared app-shell scaffold. Builder exceptions are not rendered or
returned to the user, and mirrored mobile and desktop route tests cover the
bounded unavailable state. Final visual, device, and non-demo product-flow
validation remain separate gates.

The T319 table-surface hardening now groups bounded runtime data into Session,
Table state, Seats, Connection, and Controls sections. Repeated seat rows
retain existing safe values and semantics while distinguishing the configured
local and current acting seats. State truth, transport, persistence, and
package ownership remain unchanged; final visual, device, and non-demo
product-flow validation remain separate gates.

The T320 network hardening now serializes admission of unrecorded replay scopes
and serializes receive lifecycles within established scopes. A concurrent new
scope cannot reach the session handler before the replay guard can admit and
record that scope, preventing post-handler scope-limit failure and preserving
retry behavior when handler work fails. Protocol, handler, and replay-guard
contracts remain unchanged; device reachability and product transport wiring
remain separate gates.

The T321 native transport hardening now enforces a shared signed 32-bit maximum
sequence in the generic bridge model and channel decoder. Windows host argument
and wire decoding now apply the same ceiling already required by Android and
the host-private wire envelope, so a frame cannot be accepted by one native
host and rejected by another. Package analysis and source checks pass; Flutter
and Windows native runtime/build validation remain separate gates.

The T322 native transport hardening aligns the shared Dart payload ceiling with
the 60 KiB limit implemented by both Android and Windows hosts. Channel model
validation and encoding now fail closed before a payload can be accepted by
Dart and rejected by either native host. Device and native runtime validation
remain separate gates.

The T323 hardening adds a repository gate for the duplicated native transport
limits. It compares the canonical Dart payload, identity, batch, and signed
sequence bounds with the Android and Windows host declarations, and runs both
the checker and its negative-path tests through Melos and CI. This prevents
future cross-platform contract drift without changing runtime behavior or
package ownership.

The T324 protocol hardening adds a generic rejected-fixture assertion. Every
`invalid_` and `unsupported_` JSON fixture now runs through its existing
catalog/schema family and must fail closed, so adding a rejected fixture without
matching rejection behavior cannot pass the protocol suite.

The T325 variant hardening updates the existing Hold'em opening-hand fixture to
the current strict persisted-state shape and loads it through
`HoldemHandState.fromJson` in package tests. This closes the unwired fixture
path without moving rules or persistence policy across package boundaries.

The T326 variant hardening adds an all-in/five-card edge fixture plus invalid
duplicate-seat and negative-stack fixtures. The persistence suite loads the
edge state and requires every `invalid_` Hold'em fixture to fail through the
existing typed parser.

The T327 mode hardening adds a duplicate-participant governance fixture and a
directory-driven gate over every mode JSON fixture. Valid fixtures must remain
usable by the policy engine, while `invalid_` fixtures must return the existing
`ERR_GOVERNANCE_CONTEXT_INVALID` result without changing mode semantics.

The T328 replay hardening adds hand-scoped, snapshot-plus-suffix,
anchor-mismatch, and protocol-mismatch fixtures. The replay test suite now
loads every JSON fixture through a typed `ReplayRequest` decoder and asserts
the expected success or fail-closed boundary without changing replay behavior.

The T329 sync hardening wires the existing snapshot recovery fixture through a
typed test-only `RecoveryRequest` decoder, adds a valid snapshot-plus-suffix
fixture assertion and an unsupported-protocol safe-close fixture assertion,
and requires every sync recovery JSON fixture to load through the decoder.
Sync recovery behavior and package ownership remain unchanged.

The T330 wizard hardening wires the existing simple, advanced, conversational,
and preset-stack JSON fixtures through typed test-only decoders. Resolver tests
now require every setup-intent fixture to produce a build-ready validated plan,
preserve deterministic preset priority, and keep helper suggestions advisory.
Wizard behavior and package ownership remain unchanged.

The T331 crypto hardening wires the existing verified-hand, partial-session,
and wiped-request JSON fixtures through a typed test-only `VerificationRequest`
decoder. The verification suite now requires every request fixture to load and
asserts the existing verified, partial, and wiped engine outcomes without
changing cryptographic policy or package ownership.

The T332 receipt hardening wires the existing live, wiped, and wrong-user
authorization fixtures through typed test-only receipt and authorization
decoders. The fixture suite now asserts matching access, wrong-user rejection,
and wiped-receipt rejection through the existing authorizer boundary without
changing receipt semantics or package ownership.

The T333 privacy hardening wires the existing strict-ephemeral and timed-sandbox
policy fixtures through a typed test-only `RetentionPolicy` decoder. The fixture
suite now asserts restore eligibility, derived export/wipe behavior, and the
exact timed wipe boundary without changing retention policy or package
ownership.

The T334 core hardening wires the existing side-pot scenarios through a typed
test-only pot fixture decoder. The fixture suite now asserts deterministic
side-pot slices and balanced uncontested settlement through `SidePotBuilder`
and `PotEngine` without changing core settlement behavior or package ownership.

The T335 core hardening repairs the existing root event-sequence fixture with
canonical content hashes and a contiguous hash chain. A typed test-only loader
now validates the sequence and replays it through the default `CoreReducer`
without changing reducer behavior or package ownership.

The T336 network hardening centralizes the existing operational peer-identity
rule and applies it consistently to bootstrap, path selection, election,
endpoint parsing, transport validation, replay protection, and direct
confidence classification. Generic session/table scope IDs retain the broader
safe-text rule; no routing policy or package boundary changed.

The T337 network hardening applies the existing signed 32-bit transport
sequence ceiling to network frame validation and replay protection, and extends
the native contract checker to compare the network declaration with the native
bridge contract. Payload, authentication, and package ownership remain
unchanged.

The T338 app-shell hardening aligns the default mobile and desktop native
transport session payload limit with the existing native 60 KiB contract. The
previous 64 KiB default was rejected by the factory's own fail-closed
configuration gate, making default transport provisioning unavailable.

The T339 contract hardening extends the existing native transport bound checker
to require both app-shell factory defaults to reference the canonical native
payload limit. Its negative-path test prevents a future literal or stale
default from bypassing the cross-layer drift gate.

The T340 app-shell hardening applies the existing native 60 KiB payload limit
to direct transport sinks and receive drains as well as factory-created
sessions. Oversized frames from a custom native bridge are rejected before
handler dispatch, preserving the generic network receiver contract.

The T341 app-shell hardening applies the existing
`NetworkInputLimits.isOperationalPeerIdentity` predicate to peer scopes at the
direct native receive drain and app table session source/provisioner boundaries.
Reserved `none`, `unresolved`, and `peer::reserved` scopes now fail closed
before bridge receive lookup or session provisioning; generic session IDs
retain the existing native safe-text contract.

The T342 app-shell hardening extends the same operational peer-identity rule to
production-session bootstrap and factory inputs, persisted route policy,
projection transport publication, and local peer identity load/save. Reserved
peer values now fail closed before context handoff, route composition,
projection send, or native identity persistence while generic session and
table scopes retain their existing safe-text contract.

## Recent T336 Changes

- Network operational peer identities now share one reserved-aware predicate;
  `none`, `unresolved`, and `::`-containing values cannot become actionable
  peers or transport scope members.
- Complete `peerdeal_network` tests pass, including bootstrap, routing,
  election, endpoint, transport, replay, and confidence coverage.
- No network routing policy, native bridge, protocol, app, or package boundary
  changed.

## Recent T337 Changes

- Network frame validation and replay protection now reject sequence values
  above `0x7fffffff`, matching the native bridge and Android/Windows hosts.
- The native contract-bound checker now detects drift between the network and
  native sequence declarations, with negative-path unit coverage.
- Complete `peerdeal_network` tests, direct package analysis, checker tests,
  and the native contract-bound check pass.

## Recent T338 Changes

- Mirrored mobile and desktop `NativeTransportSessionFactory` defaults now use
  `NativeBridgePayloadLimits.maxTransportPayloadBytes`.
- Default sender, drain, and session-provisioner construction now remains
  within the existing native transport contract instead of failing its own
  payload-limit gate.
- Mirrored app package analysis passes; the focused Flutter runner remained
  silent and was stopped after a bounded attempt.

## Recent T339 Changes

- The native transport bound checker now loads both mirrored app factory files
  and requires their `maxPayloadBytes` defaults to reference
  `NativeBridgePayloadLimits.maxTransportPayloadBytes`.
- Added negative-path coverage for app-default drift; the live checker and its
  7-test unit suite pass.
- No runtime contract or package boundary changed.

## Recent T340 Changes

- Mirrored direct `NativeTransportFrameSink` defaults now use the native 60 KiB
  payload ceiling.
- Mirrored `NativeTransportFrameDrain` instances reject oversized native
  payloads before converting or dispatching them to a session handler.
- Both app packages analyze cleanly; the focused Flutter runner remained
  silent and was stopped after a bounded attempt.

## Recent T341 Changes

- Mirrored direct receive drains now require an operational peer identity before
  invoking a native bridge receive lookup.
- Mirrored app table session sources and provisioners apply the same existing
  operational-peer predicate while retaining safe-text validation for session
  IDs.
- Added invalid-scope regressions for `none`, `unresolved`, and
  `peer::reserved`; both app packages analyze cleanly and repository static
  gates pass. The focused Flutter runner remained silent during a bounded
  attempt.

## Recent T342 Changes

- Mirrored app production-session bootstrap/factory, persisted route policy,
  projection publisher, and local identity loader/writer now use the existing
  operational peer-identity predicate.
- Added regressions for reserved `none`, `unresolved`, and `peer::reserved`
  values across context, route, runtime, factory, and local identity paths.
- Both app packages analyze cleanly; repository boundary, source-text,
  native-contract, unit, formatting, and diff checks pass. The focused Flutter
  runner remained silent during a bounded attempt.

## Recent T343 Changes

- Mirrored context-aware production-session bootstrap now requires the hydrated
  remote peer and local seat to match the accepted `JoinFlowSessionContext`
  before route composition.
- Added regressions for remote-peer and local-seat drift while preserving the
  invite-only bootstrap path.
- Both app packages analyze cleanly; repository boundary, source-text,
  native-contract, checker-unit, formatting, and diff checks pass. The focused
  Flutter runner remained silent during a bounded attempt.

## Recent T344 Changes

- Mirrored `ResolvedInvite` contracts now preserve the required protocol
  `variant_id` through accepted join outcomes and session contexts.
- Generic join safety now rejects malformed or mismatched variant identity;
  Holdem production bootstrap fails closed unless the invite variant is the
  existing `holdem_nlhe` variant.
- Updated every in-repo invite construction and added mirrored rejection
  coverage. Direct app analysis, repository boundary/source/native-contract
  checks, checker unit tests, and `git diff --check` pass; the focused Flutter
  runner remained silent during a bounded attempt.

## Recent T345 Changes

- Mirrored persisted Holdem sources now reject unsupported invite variants
  before reading recovery state.
- Mirrored configuration factories reject unsupported context variants before
  recovery-root creation, avoiding unnecessary persistence or identity work.
- Added side-effect-ordering regressions. Direct app analysis, repository
  boundary/source/native-contract checks, checker unit tests, and
  `git diff --check` pass; the focused Flutter runner remains limited by its
  silent startup behavior.

## Recent T346 Changes

- Mirrored generic method-channel bridges now register cancellation before
  lazily dispatching native secure-key, transport, local-network,
  capture-protection, and app-storage calls.
- Added dispatch-level regressions proving pre-cancelled calls do not reach the
  native handler. Direct package analysis and repository static gates pass;
  focused Flutter execution remains limited by its silent startup behavior.

## Recent T347 Changes

- Mirrored app recovery persistence factories now check cancellation before
  invoking legacy or non-cancellable native app-support bridges and after the
  lookup completes, preventing stale recovery factory creation.
- Added pre-cancelled no-invocation and cancellation-wins regressions. The
  repository boundary, source-text, native-contract, checker-unit, and diff
  gates pass; Flutter analysis and focused Flutter execution remain
  unverified because both runners were silent during bounded attempts.

## Recent T348 Changes

- Mirrored local identity loaders and writers now check cancellation before
  invoking legacy secure-key bridges and after results return.
- Local identity provisioning now fails closed before generation, after each
  storage boundary, and before returning a newly persisted identity. Mirrored
  regressions cover pre-cancelled loads/saves, late legacy results, and
  generation cancellation. Repository deterministic gates pass; Flutter
  analysis and focused Flutter execution remain unverified because both
  runners were silent during bounded attempts.

## Recent T349 Changes

- Mirrored receipt key loaders and writers now check cancellation before
  invoking legacy secure-key bridges and after results return, covering load,
  save, and delete operations.
- Receipt key provisioning now fails closed before key generation, after each
  mutation or conflict reload, after verification, and before returning key
  material. Mirrored regressions cover pre-cancelled storage, late load/save/
  delete results, and generation cancellation. Repository deterministic gates
  pass; Flutter analysis and focused Flutter execution remain unverified
  because both runners were silent during bounded attempts.

## Recent T350 Changes

- Mirrored `AppNativeReadinessLoader` defaults now reference the locked native
  transport payload ceiling instead of the self-rejecting 64 KiB value.
- The native contract checker now enforces the readiness defaults, and mirrored
  readiness coverage exercises the full native payload ceiling. Repository
  deterministic gates pass; focused Flutter execution remains unverified
  because both runners were silent during bounded attempts.

## Recent T353 Changes

- The network-owned validating transport receiver now bounds active plus
  queued unique frames at 128 by default, with caller limits validated up to
  the existing 4,096-frame replay-window ceiling.
- In-flight duplicate rejection retains precedence, and completed or failed
  admitted receive operations release their admission slots. The focused network
  receiver suite passes 8 tests and direct package analysis reports no issues.

## Recent T354 Changes

- The dedicated dependency refresh advances the root Melos dev dependency from
  8.5.0 to 8.6.0 and refreshes exactly eight compatible transitive packages:
  `glob`, `io`, `mime`, `pool`, `process`, `pub_semver`, `pubspec_parse`, and
  `yaml`.
- No application behavior, package boundary, analyzer rule, or lint rule
  changed. Full analyzer, boundary/source/native-contract, serialized
  Dart/Flutter test, diff, and post-refresh dependency-audit gates pass.
- The audit now reports 0 actionable upgrades; 14 newer versions remain below
  latest because current constraints or the Flutter/Dart toolchain block them.

## Recent T356 Changes

- Both production app entrypoints now pass the existing app-shell release policy
  with demo mode disabled when `kReleaseMode` is true. The shell mounts only its
  home fallback plus injected production routes, so a release build cannot
  expose fixture-backed demo navigation or scenarios by default.
- The runtime-level `allowDemo` override is now clamped off in release builds,
  so injected app construction cannot re-enable fixture-backed routes.
- When no product routes are supplied, the default home reports unavailable
  production routes instead of presenting demo state. Debug/test callers retain
  the existing demo default and production route injection remains app-owned.
- Mirrored app-shell tests cover the disabled-demo fallback and all focused
  app-shell tests pass.

Remaining:
- Concrete product state/source and durable database wiring, real-device and
  cross-device validation, other-platform hosts, operator release signing, and
  final product UI validation remain external or integration-owned.

## Recent T357 Changes

- Android CI now generates a short-lived runner-local PKCS12 key and builds a
  signed release APK after verifying that missing signing values fail closed.
- The ephemeral CI key does not replace operator-owned release signing; real
  device installation, key custody, and release distribution evidence remain
  open.
- No application, native bridge, or package boundary changed.

## Recent T358 Changes

- Windows CI now builds and executes the native host smoke target in both Debug
  and Release configurations, using the existing explicit executable-path
  parameter for the Release binary.
- The Release smoke covers the existing native registration surface after
  release compilation; operator profile/device and distribution validation stay
  open.
- No application, native bridge, or package boundary changed.

## Recent T359 Changes

- Android CI now invokes the installed SDK `apksigner` against the generated
  release APK after the ephemeral signing build.
- The verification gate requires a valid v2 or v3 signature and exactly one
  signer, and fails closed when the APK or verifier is unavailable.
- Operator-owned signing identity, device installation, and distribution
  validation remain open; no application or package boundary changed.

## Recent T360 Changes

- Added a Flutter-targeted Android native-host smoke target that exercises the
  existing app-storage, capture, secure-key, local-network, and transport
  method channels.
- CI builds the target and runs it on an API 35 emulator, requiring secure-key,
  capture, storage, and invalid transport paths to pass while accepting only
  the native network capability's explicit unavailable state when multicast is
  not usable in the emulator.
- Real-device persistence/capture behavior, multicast reachability, firewall
  behavior, cross-device validation, and operator release evidence remain
  separate gates; package boundaries are unchanged.

## Recent T361 Changes

- Replaced bare nested `melos` script calls with `dart run melos` so the CI
  runner resolves the workspace-pinned Melos executable without relying on a
  global PATH entry.
- The GitHub failure was isolated to the bootstrap job's analyzer step;
  Android and Windows build/smoke jobs were already passing on that run.

## Recent T362 Changes

- Corrected the Android emulator CI step to locate the installed SDK
  `sdkmanager` and export its command-line tools, emulator, and platform-tools
  directories before image installation and smoke execution.
- This addresses the hosted run's concrete `sdkmanager: command not found`
  failure; no application or package boundary changed.

## Recent T363 Changes

- Preserved the Android SDK locator while allowing the standard `yes |
  sdkmanager --licenses` pipeline to complete without treating its expected
  producer shutdown as a CI failure.
- Direct SDK installation and all later emulator commands remain fail-closed.

## Recent T364 Changes

- Explicitly disabled shell `pipefail` only while `yes` supplies Android SDK
  license input, then restored it before package installation.
- This addresses the runner's inherited `yes: standard output: Broken pipe`
  failure without weakening the remaining emulator gate.

## Recent T365 Changes

- Pinned Android AVD creation and emulator execution to the same runner-temp
  `ANDROID_AVD_HOME`, with a fail-closed check that the named AVD was created.
- This addresses the hosted emulator's concrete unknown-AVD failure.

## Recent T366 Changes

- Added an ephemeral GitHub runner KVM permission check and enablement step
  before launching the x86_64 Android emulator.
- This addresses the hosted runner's concrete `/dev/kvm` permission failure;
  unavailable acceleration now fails with an explicit diagnostic.

## Recent T355 Changes

- Added the bounded versioned `PDD1` local discovery protocol to
  `peerdeal_network`, with strict UTF-8, identity, port, packet, and kind
  validation.
- Added the additive generic `announcePeer` local-network bridge operation.
  Android and Windows now run bounded multicast responders and scanners and
  return only validated `peer@host:port` endpoint values.
- Mirrored app-owned local identity provisioners announce only after secure-key
  read-back verification. Announcement failure is optional and does not make a
  verified local identity unusable.
- Focused protocol, bridge, and mirrored identity suites pass; Android debug
  APK and Windows debug host builds pass. The native contract checker now also
  enforces discovery address, port, header, identity, version, and packet-kind
  parity across Dart, Android, and Windows.

Remaining:
- Cross-device multicast/firewall reachability, runtime device/profile
  validation, operator-owned release signing, other-platform native hosts,
  production database/state wiring, and final product UI validation remain
  external or integration-owned.

## Recent T352 Changes

- Mirrored app capture surface coordinators now check route cancellation after
  legacy capability lookup and before queued native blocking dispatch. Cancelled
  sensitive surfaces fail closed to visual obscuring without starting stale host
  blocking.
- Existing release behavior remains uncancelled so cancellation cannot strand
  host capture blocking. Mirrored regressions cover a late legacy capability
  result and a queued action cancelled before dispatch.
- Focused mobile and desktop capture suites pass 11 tests each. Full repository
  analysis, boundary/source/native-contract checks, Dart tests, Flutter tests,
  and diff checks pass. The live dependency audit reports 9 resolvable upgrades
  under the separate dependency policy.

## Recent T351 Changes

- Mirrored app native transport session factories and frame adapters now forward
  the existing cancellation future to compatible native bridges for capability,
  send, and receive operations, and fail closed before pre-cancelled dispatch.
- Legacy bridge calls retain the existing Dart wait-boundary suppression for
  late results. Mirrored focused mobile and desktop transport suites pass 45
  tests each.
- The mirrored receipt provisioning fast path no longer yields before an
  uncancelled native load, and Hold'em controls now appear before detail
  sections so active actions remain reachable in narrow viewports.
- Full repository analysis, boundary/source/native-contract checks, Dart tests,
  Flutter tests, direct dependency resolution, and diff checks pass. The live
  dependency audit reports 9 resolvable upgrades and is tracked separately
  under the dependency policy; no dependency change is included here.

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

## Recent T110 Changes

- `OpaqueExportDecoder` now validates artifact-body and plaintext-payload JSON
  through bounded canonical protocol serialization before receipt shape
  inspection, using receipt-owned decoded-body and payload byte limits.
- Structurally oversized maps, deep values, unsupported values, and invalid
  object keys fail closed without changing receipt signature, cipher, opacity,
  or authorization semantics.

Remaining:
- Platform key storage, runtime/device validation, product persistence,
  other-platform hosts, and release signing remain separate.

## Recent T111 Changes

- `TableState`, `HoldemSeatState`, `HoldemHandState`, `HoldemEventCursor`, and
  `HoldemStateSnapshot` now validate materialized JSON through bounded canonical
  protocol serialization before typed field or collection materialization.
- Oversized maps/lists and unsupported nested values fail closed while core
  truth and variant rules remain in their existing package boundaries.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T126 Changes

- `DefaultPresetResolver` now bounds preset layers, per-layer values, merged
  fields, conflicts, helper suggestions, partial settings, and ambiguities;
  nested values are checked through bounded protocol canonical JSON.
- Direct drafts and `DefaultGameFileCompiler` plans also reject oversized or
  unsupported resolved fields, policy profiles, and validation message lists
  with stable `ERR_WIZARD_*` codes before Game File construction.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T137 Production Handoff Staleness Hardening

- Mirrored mobile and desktop shells now assign a private generation token to
  each asynchronous loaded production-session handoff.
- A late success or failure from an older join/load is ignored after a newer
  handoff, and disposal or a higher-precedence route configuration invalidates
  the pending token before navigation can occur.

Tests and gates:
- Focused mobile and desktop app-shell suites pass, including delayed stale
  loader completion after a newer join.
- Full repository gates remain required before commit and push.

Remaining:
- Product-owned concrete session source/state invocation, real device and
  cross-device validation, other-platform hosts, database persistence, and
  release signing remain separate.

## Recent T138 Production Configuration Lifecycle Hardening

- Mirrored mobile and desktop shells now invalidate the active loaded-session
  generation when the optional configuration factory is removed or replaced.
- A delayed result from the previous runtime/widget configuration cannot push a
  stale production route after the app shell rebuilds.

Tests and gates:
- Focused mobile and desktop app-shell suites pass, including delayed stale
  completion after factory removal.
- Full repository gates remain required before commit and push.

Remaining:
- Product-owned concrete session source/state invocation, real device and
  cross-device validation, other-platform hosts, database persistence, and
  release signing remain separate.

## Recent T139 Android Secure-Key UTF-8 Boundary Hardening

- Android secure-key host validation now applies UTF-8 byte limits to
  namespaces and record fields, matching the Dart contract and Windows host.
- The shared native-bridge contract suite covers oversized multibyte key
  material.

Tests and gates:
- Focused secure-key channel-contract Flutter test passes.
- Android `:app:assembleDebug` passes after the Kotlin host change.
- Full repository analyze, boundary, source-text, test, dependency-audit, and
  diff-check gates pass before commit and push.

Remaining:
- Android device/runtime validation, cross-device networking, other-platform
  hosts, database persistence, and release signing remain separate.

## Recent T140 Dart Secure-Key Namespace Boundary Hardening

- The shared native-bridge contract now defines a 128-byte UTF-8 secure-key
  namespace limit.
- Dart method-channel load/save/delete requests reject oversized multibyte
  namespaces before platform dispatch, matching Android and Windows hosts.

Tests and gates:
- Focused secure-key method-channel Flutter tests pass, including oversized
  multibyte namespace rejection with no platform call.
- Full repository analyze, boundary, source-text, test, dependency-audit, and
  diff-check gates pass before commit and push.

Remaining:
- Android device/runtime validation, cross-device networking, other-platform
  hosts, database persistence, and release signing remain separate.

## Recent T141 Dart Secure-Key Text Validation Hardening

- Shared native-bridge validation now rejects oversized or control-bearing
  secure-key namespaces, key IDs, purposes, algorithms, and secrets.
- Delete key-ID requests use the same UTF-8 byte and control-character rules as
  save records and Android/Windows host validation.

Tests and gates:
- Focused secure-key method-channel and channel-contract Flutter tests pass,
  including oversized multibyte IDs and control-bearing save/delete requests.
- Full repository analyze, boundary, source-text, test, dependency-audit, and
  diff-check gates pass before commit and push.

Remaining:
- Android device/runtime validation, cross-device networking, other-platform
  hosts, database persistence, and release signing remain separate.

## Recent T142 Generic Native Bridge Text Boundary Hardening

- Shared Dart bridge validation now rejects padded or C0/C1-control-bearing
  transport identities and receive scopes, local-network values, capture
  diagnostics, and app-storage paths/warnings.
- The boundary now matches the existing Android and Windows host text rules
  without adding platform policy to `peerdeal_native_bridges`.

Tests and gates:
- Focused native bridge contract and transport preflight tests pass.
- Full native bridge Flutter package tests pass.
- Full repository analyze, boundary, source-text, test, dependency-audit, and
  diff-check gates pass before commit and push.

Remaining:
- Other-platform hosts, Android/Windows device and network validation, database
  persistence, and release signing remain separate.

## Recent T143 Native App-Storage Path Boundary Hardening

- Android no-backup storage and Windows `LocalAppData` host results now reject
  invalid or padded UTF-8 paths, C0/C1 controls, and paths above 4096 UTF-8
  bytes before returning an available directory.
- The Windows native-host smoke target now asserts the returned path against the
  same safe-text and byte-limit contract.

Tests and host verification:
- Android debug APK compilation passed.
- Windows debug host compilation passed.
- The Windows native-host smoke passed app storage, capture, local-network,
  transport, and secure-key checkpoints.

Remaining:
- Production database persistence, Android device/runtime behavior,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T144 Production Join-Context Propagation

- Mirrored configuration factories now accept an optional accepted
  `JoinFlowSessionContext` and context-aware route-policy factory.
- The generated configuration loader forwards the exact accepted context before
  route/source composition; existing no-context callers retain their fallback
  route-policy behavior.

Tests:
- Focused mobile and desktop configuration Flutter suites pass, including the
  loader-to-policy context handoff.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T145 Production Configuration Warning Preservation

- Mirrored production-session configuration factories now retain any recovery
  store warnings when route-policy or persisted-source composition fails after
  a store was created.
- The stable unavailable warning remains present, and exception detail is still
  suppressed at the app boundary.

Tests:
- Focused mobile and desktop configuration Flutter suites cover route-policy
  composition failure and fail-closed results.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T146 CI Branch Gate Coverage

- The repository workflow now runs on direct pushes to `retrofit/**` and
  `hardening/**`, in addition to `main` and `master`.
- Manual `workflow_dispatch` execution is available for operator-controlled
  reruns; the existing gate jobs and their fail-closed signing/native checks
  are unchanged.

Tests:
- Repository source-text, analysis, boundary, test, dependency, and build
  gates remain required after this workflow-only change.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, release signing credentials,
  and GitHub-hosted workflow execution remain separate.

## Recent T147 Production Table Lifecycle Invalidation

- Mirrored production Hold'em table surfaces now invalidate pending projection
  retries when their runtime, snapshot coordinator, peer, or local seat is
  replaced.
- Generation guards prevent late persistence or transport completions from
  repopulating busy, status, or retry state after replacement or disposal.
- Focused mobile and desktop route suites cover a delayed native send completing
  after runtime replacement.
- Full analyze, boundary-check, source-text, test, dependency-audit, Android
  debug build, Windows debug build, Windows native-host smoke, and diff-check
  gates pass.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T148 Inbound Checkpoint Lifecycle Invalidation

- Mirrored table routes now capture the accepted inbound event, owning runtime,
  snapshot coordinator, and lifecycle generation at transport callback time.
- Late callbacks from a replaced or disposed route cannot checkpoint a
  replacement session or refresh its UI state.
- Focused mobile and desktop route suites cover a delayed inbound frame after
  runtime replacement.
- Full analyze, boundary-check, source-text, test, dependency-audit, Android
  debug build, Windows debug build, Windows native-host smoke, and diff-check
  gates pass.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T149 Cancelled Native Receive Suppression

- Mirrored native frame drains now race receive and frame-handler work against
  the route cancellation signal and fail closed before delivering a late frame.
- Native transport sessions forward their source cancellation into the drain,
  preventing replaced/disposed routes from mutating the old runtime after an
  in-flight receive completes.
- Focused mobile and desktop transport/route suites cover late receive
  suppression.
- Full analyze, boundary-check, source-text, test, dependency-audit, Android
  debug build, Windows debug build, Windows native-host smoke, and diff-check
  gates pass.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T154 Snapshot Coordinator Recovery Bound

- Mirrored snapshot coordinators now enforce the configured recovery-event
  limit before copying event suffixes or entering checkpoint persistence.
- Configuration factories pass their validated recovery limit into the
  coordinator, preventing coordinator/persistence default drift.
- Focused mobile and desktop coordinator and configuration suites cover the
  bound and invalid-limit failure.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all app-storage, capture, local-network,
  transport, and secure-key checks.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T155 Snapshot Checkpoint Queue Bound

- Mirrored snapshot coordinators now cap retained failed checkpoints at 64 by
  default, with a positive caller-owned limit for tighter deployments.
- When the cap is full, newer failed checkpoints are rejected with a stable
  queue-full warning instead of growing the in-memory retry queue.
- Configuration factories pass the pending-checkpoint limit into the
  coordinator, preventing production composition from restoring an unbounded
  failure queue.
- Focused mobile and desktop coordinator and configuration suites cover queue
  capacity and invalid-limit failure.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds
  passed; the smoke run passed all app-storage, capture, local-network,
  transport, and secure-key checks.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T174 Immutable Native-Bridge Collections

- Generic native bridge models now defensively copy and freeze local-network
  discovery lists, secure-key record lists, native receive frame lists, and
  transport frame payload bytes.
- Native bridge contract tests and affected mobile and desktop suites cover
  source-list isolation and immutable package-boundary results.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T175 Immutable Network Collections

- Generic network models now defensively copy and freeze bootstrap peer/candidate
  lists, LAN discovery lists, transport payload bytes, warning diagnostics, and
  peer-election rankings.
- Focused network and mirrored mobile/desktop transport suites cover source-list
  isolation and immutable network results.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T176 Immutable Sync/Recovery Collections

- Sync and recovery models now defensively copy and freeze recovery event
  requests/windows, conflict results, warning diagnostics, snapshot results,
  persistence results, and reconciliation notes.
- Focused sync ownership, conflict, snapshot, and coordinator suites cover
  source-list isolation and immutable recovery results.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T177 Immutable Replay Collections

- Replay requests, snapshot suffix plans, and replay results now defensively
  copy and freeze event windows, warning diagnostics, and replay mismatches.
- Focused replay ownership, engine, mismatch, suffix, and anchor suites cover
  source-list isolation and immutable replay results.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T173 Immutable App-Boundary Collections

- Mirrored native bootstrap candidate, native transport session/drain, and
  receipt key-ring result constructors now defensively copy and freeze exposed
  collection diagnostics.
- Focused mobile and desktop transport, bootstrap, and receipt suites cover
  source-list isolation and immutable result collections.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T172 Immutable Readiness/Transport Diagnostics

- Mirrored `AppNativeReadinessSnapshot`,
  `AppTableSessionTransportPollResult`, and
  `AppTableSessionTransportSourceStartResult` now defensively copy and freeze
  warning lists.
- Focused mobile and desktop readiness and transport-source suites cover
  source-list isolation and immutable result diagnostics.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T171 Immutable Local-Identity Diagnostics

- Mirrored local-identity loader and provisioner results now defensively copy
  and freeze warning lists.
- Secure-key and production-session callers can no longer mutate projected
  local-identity diagnostics after result construction.
- Focused mobile and desktop local-identity suites cover source-list isolation
  and immutable result diagnostics.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T170 Immutable Startup Diagnostics

- Mirrored recovery-store and production-session configuration load results now
  defensively copy and freeze warning lists.
- Caller-owned startup diagnostics can no longer mutate the result consumed by
  app route/session orchestration.
- Focused mobile and desktop configuration, recovery, and app-shell suites
  cover source-list isolation and immutable result diagnostics.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T169 Immutable App-Session Diagnostics

- Mirrored `AppTableSessionEventResult` and `AppHoldemInboundEventResult`
  constructors now defensively copy and freeze warning lists.
- Caller-owned warning sources can no longer mutate projected diagnostics, and
  result warning collections reject mutation.
- Focused mobile and desktop runtime suites cover source-list isolation and
  immutable result diagnostics.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T168 Inbound Event Checkpoint Identity

- Mirrored `AppTableSessionEventResult` values now carry the exact accepted
  `EventEnvelope` for every accepted single event.
- Production Hold'em routes use that callback-owned event for checkpointing
  instead of rereading mutable `lastAcceptedEvent` runtime state.
- Focused mobile and desktop runtime and transport-handler suites verify the
  accepted event sequence and identity fields across the decoded frame path.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T167 Shared Sync Snapshot Hash Verification

- `BasicConflictDetector` and `BasicSnapshotApplier` now verify canonical
  snapshot payload hashes before recovery planning or projector access.
- Mismatches return the fatal `ERR_SNAPSHOT_PAYLOAD_HASH_MISMATCH` conflict;
  valid canonical snapshots continue through the existing sync path.
- The full `peerdeal_sync` suite covers detector/applier tamper rejection and
  canonical recovery fixtures.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T166 Persisted Snapshot Hash Verification

- Mirrored persisted Hold'em sources now recompute and verify the canonical
  snapshot payload hash before typed state hydration.
- Tampered or malformed envelope payloads fail closed before local identity
  provisioning or route input construction.
- Focused mobile and desktop suites cover tampered-hash rejection and valid
  canonical snapshot loading.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T165 Orphaned Recovery Event Guard

- Mirrored persisted Hold'em sources now reject a recovery event suffix when
  no typed snapshot anchor exists; new initial state cannot mask durable
  orphaned events.
- The guard runs before the product initial-state loader, local identity
  provisioning, or snapshot checkpoint coordinator.
- Focused mobile and desktop suites prove the suffix remains unchanged and no
  provisioning path is called.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T164 First-Join Typed State Checkpoint

- Mirrored persisted Hold'em sources and configuration factories now accept an
  optional product-owned initial typed-state loader when recovery is empty.
- The source validates invite scope, sequence zero, cursor sequence one, and
  the protocol genesis hash, then ensures local identity and checkpoints the
  initial state through the existing snapshot coordinator before returning app
  input.
- Focused mobile and desktop source/configuration suites cover first-join
  persistence, invalid scope, missing coordinator, and checkpoint failure.
- Full repository gates, Android/Windows artifact builds, and Windows native
  host smoke validation pass.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  separate.

## Recent T163 Receipt Key-Ring Native Text Bound

- Mirrored receipt key-ring loaders and writers now reuse the locked native
  secure-key UTF-8/C1 and byte limits for namespaces, key IDs, and secrets.
- C1-bearing or byte-oversized namespaces fail closed before native load,
  save, or delete; invalid key metadata cannot become a receipt key-ring entry.
- Focused mobile and desktop receipt loader/writer suites and package analysis
  pass.

Remaining:
- Full repository gates, Android/Windows runtime key-store validation,
  cross-device networking, other-platform hosts, product state/database
  provisioning, and release signing remain separate.

## Recent T162 Production Session Peer Identity Bound

- Mirrored local identity loaders and writers now reuse the shared native
  transport safe UTF-8/control-free validator with the 256-byte identity limit.
- Persisted Hold'em route policies and production-session factories apply the
  same boundary before dynamic peer overrides, route construction, or native
  transport composition.
- C1-bearing and UTF-8-byte oversized identities fail closed before native save
  or route construction; focused mobile and desktop suites cover the paths.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates remain required; Android/Windows runtime and cross-device network
  validation, other-platform hosts, product state/database provisioning, and
  release signing remain separate.

## Recent T161 Hold'em Projection Publisher Peer Bound

- Mirrored app Hold'em projection publishers now validate local and remote peer
  IDs with the shared native transport safe UTF-8/control-free contract before
  handing canonical projection frames to the sender.
- C1-bearing and oversized peer IDs fail closed without sender frames.
- Focused mobile and desktop Hold'em runtime suites cover rejection before
  sender calls.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed; diff validation is clean.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## Recent T160 Native Readiness Secure-Key Namespace Bound

- Mirrored app-native readiness loaders now validate secure-key namespaces
  with the shared 128-byte UTF-8/control-free bridge contract before storage
  lookup.
- C1-bearing and oversized namespaces can no longer reach an injected secure
  key bridge during readiness aggregation.
- Focused mobile and desktop readiness suites cover rejection before native
  storage invocation.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed; diff validation is clean.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## Recent T159 Native Transport Source Scope Bound

- Mirrored transport sources and provisioners now reuse the shared native
  bridge safe UTF-8/control-free identity validator before source start,
  polling, or capability lookup.
- Invalid C0/C1-bearing and over-256-byte session/peer scopes can no longer
  appear as a started source or reach native capability provisioning.
- Focused mobile and desktop source/provisioner suites cover rejection before
  source drain and capability lookup.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed; diff validation is clean.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## Recent T158 Native Transport Send Model Bound

- Mirrored app-native transport sinks now validate the converted
  `NativeTransportFrame` before calling an injected native bridge.
- Network-layer trim validation can no longer bypass native UTF-8/control,
  identity, sequence, or payload invariants at the outbound bridge seam.
- Focused mobile and desktop transport-adapter suites cover C0, C1, and
  oversized identity rejection without a bridge send.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed; diff validation is clean.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## Recent T157 Native Transport Receive Scope Bound

- Mirrored app-native transport drains now reuse the shared native bridge
  validator for receive session and peer scopes.
- Direct drain callers can no longer pass C0/C1-control-bearing, padded,
  empty, or over-256-byte UTF-8 scope identities to an injected native bridge.
- Focused mobile and desktop transport-adapter suites cover control and
  oversized scope rejection before native receive.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed; diff validation is clean.

Remaining:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  separate.

## Recent T156 Native Bootstrap Provider Output Bound

- Mirrored native join bootstrap coordinators now apply the configured peer
  candidate cap to reachable candidates returned by the injected provider,
  not only to native discovery input.
- Provider peer IDs are normalized and deduplicated before the bounded plan is
  returned, preventing malformed or oversized provider output from reaching
  governance handoff.
- Focused mobile and desktop native-bootstrap suites cover provider output
  capacity and normalization.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds
  passed; the smoke run passed all app-storage, capture, local-network,
  transport, and secure-key checks.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T153 Snapshot Serialization Preflight Hardening

- Mirrored snapshot writers now canonical-encode typed snapshots during
  validation before any event suffix append.
- Serialization and hashing failures return stable persistence results instead
  of escaping, so malformed state cannot leave a durable event suffix without
  its snapshot checkpoint.
- Focused mobile and desktop persistence-writer and snapshot-writer suites
  cover unsupported snapshot metadata.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all app-storage, capture, local-network,
  transport, and secure-key checks.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T152 Snapshot ID Factory Failure Hardening

- Mirrored production snapshot coordinators now generate snapshot IDs inside
  the serialized checkpoint queue.
- Caller snapshot-ID factory exceptions fail closed with a stable persistence
  warning, update `lastResult`, and cannot create pending or durable state.
- Focused mobile and desktop snapshot coordinator suites cover the failure.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all app-storage, capture, local-network,
  transport, and secure-key checks.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T151 Transport Provisioning Cancellation Recheck

- Mirrored transport provisioners now recheck their route cancellation signal
  after native session creation and before returning an available session/source.
- Cancellation that arrives during native session creation now fails closed and
  cannot expose a source to a replaced production route.
- Focused mobile and desktop provisioner, source, drain, and session-factory
  suites cover the race.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all app-storage, capture, local-network,
  transport, and secure-key checks.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T150 Source-Owned Drain Disposal Cancellation

- Mirrored transport sources now expose an additive cancellable drain seam and
  complete that signal on source disposal or external route cancellation.
- Native transport session factories use the seam so standalone source mounts
  cannot leave an in-flight native receive active after disposal.
- Focused mobile and desktop source, drain, and session-factory suites cover
  source-owned cancellation.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all app-storage, capture, local-network,
  transport, and secure-key checks.

Remaining:
- Product state/database provisioning, Android device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  separate.

## Recent T136 Production Snapshot Retry Ordering Hardening

- Mirrored mobile and desktop snapshot coordinators now retain newer checkpoints
  behind a failing older retry in a FIFO queue instead of dropping newer
  accepted state.
- Retry requests are serialized against the live pending queue, so concurrent
  retry calls cannot replay an already-completed older checkpoint after a newer
  checkpoint has succeeded. Durable event suffixes remain marked and are not
  re-appended during snapshot retry.

Tests and gates:
- Focused mobile and desktop coordinator suites pass, including repeated
  failure, newer-checkpoint retention, and concurrent retry coverage.
- Full repository gates remain required before commit and push.

Remaining:
- Product-owned concrete session source/state invocation, real device and
  cross-device validation, other-platform hosts, database persistence, and
  release signing remain separate.

## Recent T135 Production Snapshot Checkpoint Wiring

- Mirrored mobile and desktop production session factories now create one
  shared typed snapshot writer, event-plus-snapshot persistence writer, and
  serialized snapshot coordinator for the mounted route.
- The coordinator receives accepted local projection event suffixes and
  accepted remote events, appends non-retention events before the typed
  snapshot, retains failed checkpoints for ordered retry, and discards pending
  state behind accepted close or wipe retention events.
- The production surface exposes a bounded persistence-pending state and retry
  action; sync retry remains gated until a pending durable checkpoint succeeds.

Tests and gates:
- Focused mobile and desktop coordinator, persistence-writer, route, factory,
  bootstrap, and app-shell Flutter suites pass.
- Full repository gates remain required before commit and push.

Remaining:
- Product-owned concrete session source/state invocation, real device and
  cross-device validation, other-platform hosts, database persistence, and
  release signing remain separate.

## Recent T134 Production Session Factory Loader Wiring

- Mirrored mobile and desktop app shells now accept an optional configured
  `AppHoldemProductionSessionConfigurationFactory` directly.
- Each shell creates one stable app-owned adapter that invokes the factory for
  the typed `JoinFlowSessionContext` handoff. Explicit typed loaders, explicit
  join handlers, and prebuilt production routes retain precedence.
- The accepted session context remains route-owned input to the existing
  bootstrap; the factory still receives product-owned route policy, state, and
  persistence dependencies.

Tests and gates:
- Focused mobile and desktop app-shell Flutter suites pass, including the
  factory-to-loader handoff path.

Remaining:
- Product state/source provisioning, database selection, device/network
  validation, other-platform hosts, and release signing remain separate.

## Recent T133 Native Host Build and Smoke Validation

- Android debug APK and Windows debug host builds pass.
- The dedicated Windows native-host smoke target and default RTK PowerShell
  wrapper pass app-storage, capture capability/enable/release, local-network
  capability/discovery, transport capability/send/receive, and secure-key
  baseline, save/read-back, stale-writer conflict, conditional save/delete,
  and delete read-back checkpoints.
- The wrapper now derives its executable path when `PSScriptRoot` is empty
  under RTK PowerShell invocation.

Tests and gates:
- `flutter build apk --debug --no-pub` passed.
- `flutter build windows --debug --no-pub` passed.
- `flutter build windows --debug --no-pub -t tool/windows_native_host_smoke.dart`
  passed.
- `run_windows_native_host_smoke.ps1` passed with its default executable path.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates pass; actionable dependency
  upgrades: 0.

Remaining:
- Real Android device behavior, cross-device multicast/firewall profiles,
  other-platform hosts, product state/database wiring, and release signing
  remain external or owner-controlled validation.

## Recent T132 Typed Production Session Handoff Loader

- Mirrored mobile and desktop app shells now accept an optional
  `AppHoldemProductionSessionConfigurationLoader` for successful typed
  first-join and rejoin handoffs.
- The loader receives `JoinFlowSessionContext` and returns the existing
  available/unavailable configuration-factory result. Available results must
  include the configuration, persistence writer, and snapshot writer.
- Loaded routes reuse app route validation, the existing bootstrap adapter, and
  native readiness gating. Explicit join handlers and prebuilt production
  routes retain precedence; loader errors or unavailable results fail closed.

Tests and gates:
- Focused mobile and desktop app-shell Flutter tests passed (80 each).
- Focused mobile and desktop Flutter analysis passed.
- Full analyze, boundary-check, source-text, serialized test, dependency-audit,
  and `git diff --check` gates passed; dependency audit reports zero actionable
  upgrades.

Remaining:
- A real product owner must supply the loader, concrete source/state/route
  policy, platform implementations, database persistence, device validation,
  and release signing.

## Recent T131 Production Recovery-Limit Propagation

- Mirrored production bootstrap, route-registration, configuration, and
  session-factory seams now carry one validated `maxRecoveryEvents` value into
  the app session runtime.
- Persisted configuration also passes the same value to the persisted source
  and app persistence writer, preventing default-limit drift across recovery
  paths.
- Focused mobile and desktop production-session tests cover runtime
  propagation, bootstrap early rejection, and configuration fail-closed
  behavior.

Remaining:
- Concrete product session/state wiring, native platform validation,
  other-platform hosts, database replacement, and release signing remain
  separate.

## Recent T130 App Session Event-Batch Bound

- Mirrored `AppTableSessionRuntime` owners now enforce the shared
  `RecoveryEventWindowLimits.defaultMaxEvents` bound, configurable per runtime,
  before copying or reducing caller-supplied non-retention event batches.
- Oversized batches and non-positive limits fail closed without changing app
  state; focused mobile and desktop runtime tests cover both paths.

Remaining:
- Concrete product session/state wiring, native platform key storage,
  runtime/device validation, other-platform hosts, and release signing remain
  separate.

## Recent T129 Persisted Session Writer Event Bound

- Mirrored `AppHoldemProductionSessionPersistenceWriter` instances now enforce
  the shared `RecoveryEventWindowLimits.defaultMaxEvents` bound, configurable
  per writer, before event traversal, snapshot validation, or `appendEvents`.
- Oversized suffixes and non-positive limits fail closed without writing event
  or snapshot data; focused mobile and desktop writer tests cover both paths.

Remaining:
- Concrete product session/state wiring, native platform key storage,
  runtime/device validation, other-platform hosts, and release signing remain
  separate.

## Recent T128 Persisted Session Recovery Window Bound

- Mirrored `AppPersistedHoldemProductionSessionSource` adapters now enforce
  the shared `RecoveryEventWindowLimits.defaultMaxEvents` bound, configurable
  per source, immediately after loading a recovery window and before snapshot
  decoding, suffix materialization, identity provisioning, or replay.
- Oversized windows and non-positive limits fail closed; focused mobile and
  desktop source tests cover both paths.

Remaining:
- Concrete product session/state wiring, native platform key storage,
  runtime/device validation, other-platform hosts, and release signing remain
  separate.

## Recent T127 Receipt Key-Ring Bounds

- `ReceiptKeyRingSnapshot` and `StaticReceiptSigningKeyProvider` now apply
  receipt-owned retained-key limits of 128 verification/decryption entries by
  default before lookup traversal; oversized collections fail closed.
- Active usable keys remain available without traversing retained collections,
  and focused receipt tests cover signing, encryption, and invalid limits.

Remaining:
- Native platform key storage, runtime/device validation, other-platform hosts,
  product persistence/source wiring, and release signing remain separate.

## Recent T125 Changes

- `DefaultGovernanceEngine` now checks configurable bounds before participant,
  seat, or waitlist traversal: 256 participants, 64 seats, and 256 waitlist
  entries by default.
- Oversized context collections fail closed with
  `ERR_GOVERNANCE_PARTICIPANT_COUNT`, `ERR_GOVERNANCE_SEAT_COUNT`, or
  `ERR_GOVERNANCE_WAITLIST_COUNT`; waitlist admission also cannot grow a full
  bounded ordering.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T124 Changes

- `peerdeal_core` now bounds direct pot commitments to 64, winning slice-map
  entries to 64, and winners per slice to 64 before side-pot or award traversal.
- Overflow fails closed with explicit core settlement warnings; the tighter
  nine-entry Hold'em projector bound remains enforced upstream.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T123 Changes

- Direct Hold'em showdown projection now bounds result collections, pot-slice
  maps, and contested seat-ID lists before materialization.
- Overflow returns explicit projection warnings and is propagated through
  settlement as a blocked result; existing malformed-evaluation slice
  reporting remains unchanged.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T122 Changes

- The variant-owned `ShowdownSettlementProjector` now bounds direct commitment
  collections to the shared nine-seat Hold'em launch limit before invoking
  core side-pot construction.
- Both contested and uncontested settlement paths fail closed with
  `ERR_HOLDEM_SETTLEMENT_PROJECT_COMMITMENT_COUNT` when that limit is exceeded.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T121 Changes

- `peerdeal_variants` now bounds direct Hold'em showdown seat collections to
  the locked nine-seat launch invariant before sorting, card expansion, or
  hand evaluation.
- Oversized showdown input fails closed with
  `ERR_HOLDEM_SHOWDOWN_SEAT_COUNT`; the shared Hold'em input limit is reused by
  adapter identity and configuration validation.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T120 Changes

- `peerdeal_network` now bounds direct peer-id, bootstrap-candidate, and
  peer-metric collections before routing or confidence materialization.
- Bootstrap overflow returns no candidates; path selection returns an
  unresolved relay descriptor; confidence classification and primary election
  return unsafe results without traversing beyond the configured bound.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T119 Changes

- Direct `RecoveryRequest` and `SnapshotApplyRequest` processing now validates
  table, session, and protocol scope identities through the shared
  `RecoveryPersistenceScope` rules before event traversal, snapshot projection,
  or projector access.
- Invalid direct scopes fail closed with processor-specific fatal conflicts:
  `ERR_RECOVERY_SCOPE_INVALID` and `ERR_SNAPSHOT_APPLY_SCOPE_INVALID`.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T118 Changes

- `RecoveryPersistenceScope` now rejects storage keys above the shared 180-byte
  UTF-8 limit before in-memory indexing or base64url filename generation.
- In-memory and JSON recovery stores fail closed with the existing
  `ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID` code and do not mutate files or
  stored windows for oversized scopes.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T117 Changes

- Direct sync conflict detection and snapshot application now validate supplied
  `SnapshotEnvelope` values through bounded canonical JSON before protocol,
  scope, or snapshot/suffix projection work.
- The shared default is 4 MiB with the protocol map/list/depth/text/node
  limits; oversized or unencodable snapshots fail closed with
  `ERR_RECOVERY_SNAPSHOT_TOO_LARGE` or `ERR_RECOVERY_SNAPSHOT_INVALID`.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T116 Changes

- Direct sync conflict detection and snapshot application now run each
  caller-provided event through the existing `EventEnvelopeCodec` before
  protocol, scope, sequence, or projector work.
- The shared default is 64 KiB per event with the protocol canonical structure
  limits; oversized or unencodable events fail closed with
  `ERR_RECOVERY_EVENT_TOO_LARGE` or `ERR_RECOVERY_EVENT_INVALID`.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T115 Changes

- Direct sync conflict detection and snapshot application now reject recovery
  event lists above the shared configurable 4,096-event default before
  protocol, scope, sequence, or projector traversal.
- The stable fatal code is `ERR_RECOVERY_EVENT_COUNT_TOO_LARGE`; persistence
  stores continue to own durable-window mutation and their existing
  persistence-specific error codes.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T114 Changes

- Oversized replay requests now return immediately before secondary protocol,
  scope, range, or event traversal.
- `AnchorHashCalculator` and `SnapshotSuffixReplayer` enforce the same default
  4,096-event bound. Anchor hashing uses explicit canonical list/node limits,
  and `BasicReplayEngine` returns stable selection or anchor failure mismatches
  instead of allowing helper exceptions to escape.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T113 Changes

- `EventWindowValidator` now applies a configurable positive event-count limit,
  defaulting to 4,096 events, with the structured
  `ERR_REPLAY_EVENT_WINDOW_TOO_LARGE` failure code.
- `BasicReplayEngine` validates the raw request list before protocol, scope,
  range, selection, or projector traversal while retaining selected-window
  validation after filtering.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

## Recent T112 Changes

- `EventEnvelope.fromJson` and `SnapshotEnvelope.fromJson` now validate their
  complete materialized JSON trees through bounded canonical protocol
  serialization before typed field access.
- File-backed recovery now fails closed on structurally oversized persisted
  snapshot payloads before importing them into the in-memory recovery store.

Remaining:
- Product persistence/source wiring, platform key storage, runtime/device
  validation, other-platform hosts, and release signing remain separate.

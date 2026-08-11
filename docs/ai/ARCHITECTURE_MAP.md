# Architecture Map

Status: Populated from `repomix-summary.xml` on 2026-06-07; reviewed by Codex.

## System Overview

PeerDeal is a peer-to-peer, event-sourced poker engine with Flutter client
shells. There is no central server in the current scaffold. Truth flows from
ordered protocol events through deterministic reducers. Variant and mode
packages add policy without mutating universal core truth.

## Layer Stack

| Layer | Packages / apps | Responsibility |
| --- | --- | --- |
| App orchestration | `apps/peerdeal_mobile`, `apps/peerdeal_desktop` | Routes, setup/join flows, demo slices, app-owned presenters/controllers, protocol SessionClosed-to-retention mapping, recovery retention and exactly-once session-close coordination, app-owned table-session runtime projection, native-to-package mapping, native transport composition, native readiness aggregation |
| Shared UI | `peerdeal_ui_kit` | Safe-surface widgets and render models |
| Native seams | `peerdeal_native_bridges` plus app hosts | Method-channel contracts for platform facts, generic byte transport, and secure key records; secure-key, local-network, and transport calls have bounded default deadlines, with caller cancellation for app-owned lifecycle ownership; mobile Android and Windows desktop supply secure-key, capture, app-storage, local-network interface capability, and bounded multicast transport host implementations |
| Network confidence | `peerdeal_network` | Route class, bootstrap/path/election peer-id gates, confidence, primary peer selection, transport frame send/receive gates |
| Replay/recovery | `peerdeal_replay`, `peerdeal_sync` | Event windows, request ranges, anchors, snapshots, safe-close recovery |
| Privacy/receipt/capture | `peerdeal_privacy`, `peerdeal_receipts`, `peerdeal_capture` | Retention, receipt artifacts, capture policy |
| Mode/variant policy | `peerdeal_modes`, `peerdeal_variants` | Session mode policy and poker variant rules |
| Deterministic truth | `peerdeal_core` | Table state, reducer, invariants, pot/settlement primitives |
| Protocol | `peerdeal_protocol` | Envelopes, catalog, fixtures, diagnostics |

## Package Boundary Rules

- `peerdeal_protocol` has no PeerDeal package dependency.
- `peerdeal_core` depends on protocol, not on variants, modes, network, UI,
  receipts, privacy, capture, or native bridges.
- `peerdeal_variants` and `peerdeal_modes` may depend on protocol/core.
- Apps can depend on package public APIs, not package `src/` internals.
- Boundary enforcement lives in `scripts/check_package_boundaries.py` and runs
  through `melos run boundary-check`.

## Data Flow

User/app intent:

1. App/controller forms a protocol command or invokes a package boundary.
2. Core validation checks the command against current deterministic state.
3. Accepted behavior becomes ordered protocol events.
4. Core reducer projects state from ordered events.
5. Invariant guards check impossible table/hand/session states.
6. UI renders projected state and never becomes authoritative truth.

Transport ingress:

1. `peerdeal_network` validates a generic byte frame before the app handler.
2. `peerdeal_protocol.EventEnvelopeCodec` decodes bounded canonical event bytes.
3. The app handler binds frame/session identity and delegates the event to
   `AppTableSessionRuntime`.
4. The runtime delegates deterministic projection to `peerdeal_core` and only
   commits accepted events, including retention-gated close events.
5. An app-owned source controller can schedule bounded polls of the loaded
   native drain, serialize overlapping polls, and stop with the route lifecycle.
   Route cancellation and source disposal fail the visible poll closed; an
   already-started drain remains tracked until settlement so teardown cannot
   create overlapping native drains.

Local Hold'em producer flow:

1. App/session code supplies validated `HoldemHandState` and `HoldemEventCursor`
   to `AppHoldemTableSessionRuntime`.
2. `HoldemCoreProjectionAdapter` emits catalog-approved events and projects them
   through `peerdeal_core`.
3. The app runtime atomically commits the non-retention batch before advancing
   variant state or the cursor. For Hold'em inbound events, cursor acceptance
   and the variant reducer run before the same app runtime commits the event
   through core; generic core-only ingress remains available for other sessions.
4. `AppHoldemTableSessionRoute` provisions the validated runtime/source seam,
   owns source replacement and disposal, and refreshes its supplied surface
   after an accepted inbound event.
5. The route context can create `AppHoldemProjectionTransportPublisher`, which
   canonical-encodes accepted projection events into validated `TransportFrame`
   payloads and reports partial sends for retry without replaying rules.
6. `AppHoldemProductionRouteRegistration` merges the route into the app shell's
   validated production map and native-readiness gate; the product caller still
   supplies the validated session/state source and final surface builder.
7. `AppHoldemProductionSessionFactory` can compose the existing table runtime,
   Hold'em runtime, close-retention adapter, default surface, and peer identity
   from those injected product inputs. It rejects unsafe app metadata and
   cursor/session mismatches without creating product truth.
8. `AppHoldemProductionSessionSource` loads those inputs for a validated
   `ResolvedInvite`; `AppHoldemProductionSessionBootstrap` checks exact invite
   and hydrated table/cursor scope before invoking the factory. Source loading
   has a positive configurable timeout with a five-second default; the mounted
   route stays in a loading state while pending and fails closed after timeout
   or source failure. The source accepts an optional cancellation signal; route
   replacement and disposal complete it, while bootstrap cleanup cancels the
   deadline timer. Successful join outcomes carry the resolved invite for this
   handoff. Demo snapshots and compiled Game Files are not live session identity
   sources. `AppPersistedHoldemProductionSessionSource` hydrates a typed
   `HoldemStateSnapshot` and replays its suffix through the variant-owned
   atomic recovery transaction. It honors route cancellation before recovery
   access and around lazy identity provisioning. It leaves input mapping,
   identity, close policy, and database choice to the product caller.
   Mirrored app shells also expose local peer identity adapters over generic
   secure-key storage; they persist the local ID but do not choose remote
   peers or create product session state. The adapters detect the additive
   cancellable secure-key capability so route cancellation reaches native
   identity load/save/read-back calls when the host implements it.
   The app-owned `fromProvisionedLocalIdentity(...)` composition factory can
   now provision or reuse that ID and map it into the persisted source while a
   caller supplies route, remote-peer, local-seat, and close-event policy. It
   still leaves database selection, peer discovery, and native runtime checks
   outside the shared source boundary.
   Identity provisioning is single-flight within each app provisioner instance;
   this closes the in-process first-use race without claiming a cross-process
   lock or moving identity semantics into the native bridge.
   Newly generated identities also require an exact native read-back match after
   save before the app source can use them, keeping persistence integrity in the
   app boundary while retaining generic native storage semantics.
9. `AppHoldemProductionSessionBootstrapRouteRegistration` lets either app shell
   merge the existing bootstrap route into its production map and native-
   readiness gate. When no explicit `JoinFlowReadyHandler` is supplied, the
   shell pushes that registered path with the accepted resolved invite; an
   explicit handler wins. This remains route orchestration only and does not
   provision product state, identity, persistence, or the concrete source. The
   `fromSource(...)` constructor keeps source, bootstrap, timeout, and route
   registration assembly at this app boundary. Both configuration entry points
   reject non-positive timeouts and invalid persisted route policy; the production
   persisted configuration validates and replays recovery before lazy native
   identity provisioning. Each runtime can instead accept
   one `AppHoldemProductionSessionConfiguration.fromSource(...)` and derive a
   stable registration once; explicit and configured registrations cannot both
   be supplied.

Android and Windows native transport hosts carry validated generic frames in a
host-private bounded UDP multicast envelope and filter receive queues by session
and recipient peer. Host decoders require strict UTF-8 and reject malformed,
padded, or control-bearing identity fields before queueing or sending. Host lifecycle paths now fail closed and clean up partial
socket/Winsock initialization. The generic method-channel capability, send, and
  receive calls use a bounded five-second default deadline and accept caller
  cancellation for route lifecycle teardown. Local-network capability and
  discovery calls use the same bounded default deadline; app-owned bootstrap
  loaders cancel them on route replacement or disposal. Capture capability and
  blocking calls use the same bounded default deadline, accept additive caller
  cancellation, and fail closed on timeout; receipt-route teardown leaves the
  release action uncancelled so native blocking can be disabled.
Device/network
reachability, real platform discovery, and other-platform transport remain open.

Recovery:

1. Recovery request carries optional `SnapshotEnvelope` plus ordered events.
2. Replay validates request ranges, event windows, gaps, anchors, and unsupported versions.
3. Sync detects conflicts and applies snapshot plus suffix events.
4. Fatal conflicts recommend safe close instead of unsafe resume.

Receipts:

1. Receipt service exports minimized receipt data.
2. App-owned export factories provision native-backed receipt keys, then
   optional signing/encryption produces opaque artifacts.
3. Import/scan verifies signatures, decrypts when configured, and authorizes
   session/user binding.
4. Unavailable export artifacts stop at an app-owned rejection before native
   key verification; wiped or malformed receipts fail closed.
5. Mounted receipt routes propagate an additive cancellation signal through the
   app key-ring loader, artifact verifier, and presenter, completing it when
   the route is replaced or disposed. Native secure-key bridge compatibility
   remains unchanged.

## API Boundaries

There is no REST or GraphQL API in this scaffold. The API surface is the set of
public Dart package barrels, such as `lib/peerdeal_core.dart` and
`lib/peerdeal_protocol.dart`.

| Boundary | Stable entry point |
| --- | --- |
| Protocol envelopes/catalog | `packages/peerdeal_protocol/lib/peerdeal_protocol.dart` |
| Core reducer/state | `packages/peerdeal_core/lib/peerdeal_core.dart` |
| Variants | `packages/peerdeal_variants/lib/peerdeal_variants.dart` |
| Modes/governance | `packages/peerdeal_modes/lib/peerdeal_modes.dart` |
| Replay | `packages/peerdeal_replay/lib/peerdeal_replay.dart` |
| Sync/recovery | `packages/peerdeal_sync/lib/peerdeal_sync.dart` |
| Receipts | `packages/peerdeal_receipts/lib/peerdeal_receipts.dart` |
| Wizard/setup | `packages/peerdeal_wizard/lib/peerdeal_wizard.dart` |
| Native bridges | `packages/peerdeal_native_bridges/lib/peerdeal_native_bridges.dart` |
| App-support directory | `AppStorageDirectoryBridge` through the native-bridges public barrel |

## Persistence

- No production database is present.
- Event streams are the authoritative state source.
- Snapshots are recovery accelerators only.
- Receipts are export/restore artifacts, not general persistence.
- Sync recovery has in-memory and canonical JSON file-backed recovery-window
  stores with exact recovery scope-identity validation plus app-owned durable
  store factories, validated
  exact `PEERDEAL_RECOVERY_ROOT` configuration, and mounted table-route
  loading; app-owned retention and per-session exactly-once close seams now
  connect policy decisions to scoped wipe, and app event adapters validate and
  map supported `SessionClosed` envelopes, and app-owned table-session runtimes
  bind ordered events to core projection and close retention; platform/database
  persistence and platform source provisioning remain production gaps. The app
  shells also expose a persisted-session configuration factory that composes
  this recovery store with native local identity and caller-owned route/event
  policy; it does not provide a product database. The
  app shells now use a generic app-support directory bridge as a fallback root:
  Android supplies private no-backup storage and Windows supplies `LocalAppData`;
  explicit environment configuration still wins. The bounded app scheduler,
  app transport provisioner, and route lifecycle mount now exist around loaded
  native drains.
- Secure key storage has Dart/method-channel read/write seams plus app-owned
  receipt key-ring provisioning, namespace validation, mapping, and
  ambiguous-active-key and delete key-id rejection. Generic method-channel
  requests reject malformed secure-key namespaces and records before platform
  calls and apply a bounded five-second default response deadline. The mobile Android host encrypts generic records with an Android
  Keystore AES-GCM key, and the Windows desktop host persists a bounded
  versioned envelope in Credential Manager. Runtime persistence validation and
  other platform implementations remain production-readiness gaps.

## Auth / Authorization

- No central auth service exists in the current repo.
- Governance/roles live in mode policy.
- Receipt authorization checks pseudonymous user/session binding.
- Provider-proof verification lives in `peerdeal_crypto`.

## Risk Areas

| Risk | Status |
| --- | --- |
| Production transport | Native transport method-channel seam, package-owned exact transport frame identity validation, generic native transport sequence, byte-payload, and exact-key validation, bounded canonical protocol event-byte decoding, app-owned capability-gated transport adapters/factories, payload-limit enforcement across readiness/session/sender/drain entry points, sensitive native-note scrubbing, package-owned bootstrap/path/election/transfer/fallback peer-id gates, sink validation before native sends, receive-scope validation and receive-batch bounding before native drains/session handlers, frame-to-runtime event ingestion, bounded serialized app source scheduling, fail-closed app transport provisioning, route lifecycle source mounting, app-owned Hold'em non-demo route orchestration, canonical projection publishing with resumable partial-send offsets, typed Hold'em route registration with native-readiness gating, the default production surface, bounded Android/Windows multicast host implementations, and Android/Windows local-network interface capability handlers exist; protocol-owned peer discovery, device/network reachability, platform source provisioning, and other-platform transport remain |
| Platform key storage | Method-channel read/write seams plus generic secure-key request validation, app-owned receipt key provisioning with factory failure handling, namespace validation, native-readiness namespace validation, native key-record snapshot bounding, native key-id metadata bounding, receipt key-material bounding, mutation key-id bounding, ambiguous active-key rejection, delete key-id validation, export with provisioning diagnostic scrubbing and exception handling, verifier key-ring load exception handling, verifier key-ring and decoder diagnostic scrubbing and bounding, and verification mapping exist; Android Keystore and Windows Credential Manager hosts compile, while runtime persistence validation and other platforms remain |
| Persistence | Canonical recovery-window file store, exact recovery scope-identity validation, app-owned store factories, exact validated environment-configured recovery roots, Android private no-backup and Windows `LocalAppData` fallback roots, and mounted recovery-window loading exist; production database persistence, other-platform storage, and runtime validation remain |
| App flows | Demo routes plus mounted setup/join orchestration seams, route-level and orchestrator join input validation, route-level and orchestrator setup identity validation, join/setup outcome diagnostic scrubbing, bounded join diagnostic rendering, bounded setup error/warning rendering, mounted join/setup async dependency reload handling, mounted table warning rendering plus route-level load warning scrubbing/bounding, bootstrap candidate caps, recovery-window display count caps, mounted table runtime-scope reload handling, mounted receipt render diagnostic scrubbing and bounding, bounded mounted table/join native bootstrap mapping with exact scope validation, generic local-network discovery list validation, local-network sensitive-note and endpoint scrubbing, mounted receipt export/verify wiring, app-owned native readiness aggregation, ordered app table-session runtime projection with close-retention commit gating, optional injected transport source runtime wiring, fail-closed app transport provisioning, route-owned source start/replacement/disposal, app-owned Hold'em non-demo route orchestration with accepted-event surface refresh, canonical projection publishing with resumable partial-send offsets, typed Hold'em production-route registration with automatic route-map/navigation merge and native-readiness gating, default production Hold'em surface mounting and transport-backed action gating, default-home rendering, production-route gating, production-navigation filtering, default-home production/demo navigation sectioning, production-only default-home demo suppression, production-only native-readiness empty-action handling, production-only empty-action status rendering, custom-home native-readiness production-navigation filtering, and custom-home native-readiness production-navigation restore, app-owned route registries with bounded route metadata, exact and bounded enabled demo-route gates, validated and capped route-map allowed extras, route-map allowed-extra case-collision validation, scrubbed route-map drift diagnostics, sensitive unknown-route diagnostic suppression, validated and capped app-owned production route maps, case-insensitive production and production/demo route/navigation collision rejection, case-insensitive demo namespace reservation for production and extra route paths, validated app-owned initial routes, validated and capped production navigation descriptors, unsafe and oversized production route metadata rejection, home navigation collision validation, app-owned production route builder failure handling, app-owned home surface builders, and unknown-route fallback exist; platform transport provisioning and production navigation polish remain |
| UI polish | Shared app-shell scaffold/action/status/info primitives plus safe-surface render text scrubbing exist; the default production Hold'em surface now consumes bounded runtime projection state and exposes transport-backed local actions; final product visual, accessibility, and navigation validation remain |
| Capture blocking | Generic action/release lifecycle plus app-owned warning scrubbing exists; Android `FLAG_SECURE` and Windows `SetWindowDisplayAffinity` hosts compile, while runtime/device validation and other-platform enforcement remain |

## Do Not Cross

- Do not put variant rules in `peerdeal_core`.
- Do not put mode/session policy in core reducers.
- Do not put receipt semantics in `peerdeal_native_bridges`.
- Do not import package `src/` across package boundaries.
- Do not change protocol catalog identities without fixture/test updates.
## First-join production handoff

`peerdeal_network` discovery produces bounded candidates. The app-owned join
flow selects a reachable candidate for first join, accepted governance returns
the assigned seat, and `JoinFlowSessionContext` crosses the app-shell boundary.
For rejoin, accepted governance supplies the remote peer binding and assigned
seat because there is no bootstrap discovery phase. The context-aware
production bootstrap validates it and the persisted app source maps it into
route input. Missing governance peer data fails closed. Core state truth,
protocol schemas, native bridge semantics, and variant rules remain unchanged.

`AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(...)` is
the mirrored app-owned composition entrypoint for recovery-backed sessions. It
provisions local identity, creates the persisted source, and registers the
existing validated bootstrap route. Product database/state selection, route
policy, native reachability, and device validation remain outside this seam.

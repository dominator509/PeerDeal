# PeerDeal Invite / Join / Rejoin Flow Integration Overlay v1

This overlay adds an app/service-layer integration seam for the private invite, join,
disclosure acknowledgement, role authorization, governance commit, and rejoin flow.

Purpose:
- keep handshake orchestration out of protocol schemas
- keep governance truth out of UI code
- connect invite/join/rejoin lifecycle to the governance engine cleanly
- preserve replay-safe, explicit state transitions
- preserve stable protocol diagnostics on rejected joins for UI/logging

This overlay is meant to sit on top of:
- packages/peerdeal_protocol
- packages/peerdeal_modes
- packages/peerdeal_sync
- earlier governance and wizard overlays

Setup flow:
- `lib/setup_flow/` resolves setup intent through `peerdeal_wizard`, validates
  the draft, and compiles a Game File with the fail-closed `tryCompile`
  boundary before app routes can consume it.
- Setup orchestration returns explicit compiled/rejected outcomes; UI does not
  own Game File truth or catch compiler exceptions directly.
- The mounted setup route receives an app-owned orchestrator factory and fails
  closed when setup orchestration is unavailable.
- `lib/transport/` adapts generic native byte-frame transport to
  `peerdeal_network` validating sender/receiver boundaries. Native transport
  remains platform-owned; app adapters and factories only compose package
  public APIs and fail closed when native transport capability is unavailable.
  `AppTableSessionTransportHandler` decodes canonical protocol event bytes and
  delegates them to the bound table-session runtime after frame validation.
  `NativeTransportSession.createSource` adds app-owned bounded polling with
  serialized polls, and `AppTableSessionTransportSourceMount` owns its
  start/replacement/dispose lifecycle when injected through the app runtime.
  `AppTableSessionTransportProvisioner` composes the runtime handler and
  validated native session into that route-ready source, failing closed on
  malformed peer identity or native capability failure.

## Windows Host

- `windows/` is the generated desktop host for the existing app shell.
- `windows/runner/windows_secure_key_storage.*` registers the generic
  `peerdeal/native_bridges/secure_key_storage` channel with `loadKeyRing`,
  `saveKey`, and `deleteKey`.
- `windows/runner/windows_capture_protection.*` registers the generic
  `peerdeal/native_bridges/capture_protection` channel and applies the
  app-owned blocking decision through `SetWindowDisplayAffinity`.
- `windows/runner/windows_native_transport.*` registers the generic
  `peerdeal/native_bridges/transport` channel and carries validated byte frames
  through the bounded host-private UDP multicast envelope after strict
  UTF-8/control-free identity validation. Device/firewall
  reachability and endpoint provisioning remain outside the host seam.
- Records are validated and stored as a bounded versioned envelope in Windows
  Credential Manager under a namespace-derived target. The host does not
  interpret receipt purposes, algorithms, or rotation policy.
- The host rejects malformed Credential Manager records, including null
  pointers paired with non-empty blobs, and lets the generic decoder reject
  empty or schema-invalid envelopes.
- Capture blocking is advertised and enabled only on Windows 10 build 19041
  or newer; unsupported hosts return the existing fail-closed result so the
  app can apply visual obscuring.
- Build the host with `flutter build windows --no-pub`. Credential Manager
  runtime persistence and capture behavior still require an operator
  profile/device validation.
- The app shell exposes a deterministic retention coordinator that invokes
  recovery persistence wipe after a caller supplies a closed-session time and
  policy. `AppRecoverySessionCloseCoordinator` binds that policy and scope to
  one app session, caches the first outcome, and prevents duplicate close
  signals from repeating policy or wipe work. `AppRecoverySessionCloseEventAdapter`
  provides the app-boundary mapping from a supported, scope-matching protocol
  event to that coordinator and uses the event's `emitted_at` timestamp.
  `AppTableSessionRuntime` binds that adapter to one table/session/protocol
  stream and delegates state projection to `peerdeal_core`; it commits a close
  only after retention succeeds. Native live transport provisioning and
  production session-close scheduling remain app-lifecycle work; an injected
  source is owned by the table route mount.

Accepted joined/rejoined outcomes from the mounted join route preserve an
identity-safe `ResolvedInvite` and may invoke the injected
`JoinFlowReadyHandler` after the frame. When the app runtime is configured with
an `AppHoldemProductionSessionBootstrapRouteRegistration`, the shell mounts
that existing bootstrap route, applies its native-readiness gate, and supplies
a default join-ready handoff to the registered path. An explicitly injected
handler takes precedence. The registration and handler do not create durable
state or local identity; the product source remains responsible for both.
Use `AppHoldemProductionSessionBootstrapRouteRegistration.fromSource(...)` to
assemble the source, bootstrap, timeout, and route registration at this app
boundary without moving persistence or session truth into the shell.
For runtime-owned configuration, pass one
`AppHoldemProductionSessionConfiguration.fromSource(...)` instead; the shell
derives that registration once and reuses it for route merging, readiness, and
the default join handoff. Supplying both configuration forms fails closed.

For local Hold'em lifecycle actions, construct the app-owned
`AppHoldemTableSessionRuntime` with a validated `HoldemHandState` and
`HoldemEventCursor`. It calls the variant projection adapter, commits the
resulting non-retention event batch through `AppTableSessionRuntime`, and only
then advances variant state and the cursor. For inbound Hold'em transport,
pass that runtime as `holdemRuntime` to `AppTableSessionTransportHandler` or
`AppTableSessionTransportProvisioner`; the handler validates the remote cursor
and variant event before committing through the same app session boundary.

`AppHoldemTableSessionRoute` is the app-owned non-demo composition boundary. It
accepts the validated runtime and peer identity, provisions the existing
transport/source seam, refreshes the supplied surface after accepted inbound
events, and exposes `createProjectionPublisher(...)` for canonical outbound
events. Native live transport and the actual product route/state source remain
platform/product integration work.
`AppHoldemProductionRouteRegistration` is the typed app-shell registration for
this route. It auto-merges the route and navigation entry, requires native
readiness, and keeps validated session/state construction with the product
caller. `withDefaultSurface(...)` mounts the app-owned production Hold'em
surface, which renders runtime projection state and only enables local actions
when transport-backed publication is available.

`AppHoldemProductionSessionFactory` is the app-owned composition helper for
callers that have a real product session source. It binds injected canonical
table/hand state, event cursor, close-retention adapter, and peer identity to
the existing runtimes and default surface, while rejecting unsafe metadata and
composition mismatches. It does not create product IDs, persistence, or game
state.

It does NOT introduce a new top-level package.

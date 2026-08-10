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

## Windows Host

- `windows/` is the generated desktop host for the existing app shell.
- `windows/runner/windows_secure_key_storage.*` registers the generic
  `peerdeal/native_bridges/secure_key_storage` channel with `loadKeyRing`,
  `saveKey`, and `deleteKey`.
- `windows/runner/windows_capture_protection.*` registers the generic
  `peerdeal/native_bridges/capture_protection` channel and applies the
  app-owned blocking decision through `SetWindowDisplayAffinity`.
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
  signals from repeating policy or wipe work. The real session owner must
  invoke it when `SessionClosed` is committed. `AppRecoverySessionCloseEventAdapter`
  provides the app-boundary mapping from a supported, scope-matching protocol
  event to that coordinator and uses the event's `emitted_at` timestamp.
  Production session-close scheduling remains app-lifecycle work.

It does NOT introduce a new top-level package.

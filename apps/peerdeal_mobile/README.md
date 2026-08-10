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

## Android Host

- `android/` is the generated mobile host with application namespace
  `com.peerdeal.peerdeal_mobile`.
- `SecureKeyStorageHandler` registers the generic
  `peerdeal/native_bridges/secure_key_storage` channel. It stores validated
  generic key records as namespace-bound AES-GCM ciphertext, with the master
  key held by Android Keystore and durable writes committed through app
  preferences.
- The Android host does not interpret receipt purposes, algorithms, rotation,
  or verification policy. Those remain in the app and receipt packages.
- Release builds never fall back to debug signing. A signed release requires
  `PEERDEAL_ANDROID_KEYSTORE`, `PEERDEAL_ANDROID_KEYSTORE_PASSWORD`,
  `PEERDEAL_ANDROID_KEY_ALIAS`, and `PEERDEAL_ANDROID_KEY_PASSWORD` together.
- Live Android capture protection, local-network discovery, transport, and
  platform recovery persistence remain separate native implementation gaps.

It does NOT introduce a new top-level package.

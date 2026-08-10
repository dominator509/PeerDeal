# peerdeal_native_bridges

Native bridge boundary for PeerDeal app shells.

## Purpose
This package owns platform-specific hooks that Dart packages and app shells need
to observe local device capabilities.

## Owns
- local-network permission and capability bridge seams
- native transport capability and byte-frame bridge seams
- platform channel wrappers
- native hook result models
- package-local bridge tests and fixtures

## Must not own
- poker rules
- protocol schemas
- reducer or table truth
- session routing decisions
- capture policy decisions
- app lifecycle orchestration

## Related ownership
- `peerdeal_capture` owns capture policy.
- `peerdeal_network` owns network confidence and routing.
- app shells own when native hooks are called.

## Hardened scaffold coverage
- Method-channel capture capability lookup and blocking actions return
  unavailable or failure facts when the platform payload is missing or throws.
- Method-channel local-network capability and discovery lookup return
  unavailable capability facts when the platform payload is missing or throws.
- Method-channel secure key storage lookup returns normalized key-ring snapshots
  and unavailable facts when the platform payload is missing or throws.
- Method-channel secure key storage mutations have generic save/delete
  contracts that fail closed on invalid requests, platform failures, or
  malformed mutation results.
- Method-channel native transport capability, send, and receive contracts
  normalize byte-frame payloads and fail closed on invalid requests, platform
  failures, or malformed payloads.
- Native bridge warnings are normalized for app-layer safe-surface and network
  routing policy.
- Channel names, method names, fixture payloads, and decode behavior are locked
  in package tests so future platform implementations can target a stable
  contract.
- Malformed platform payload fields are ignored and normalized to fail-closed
  capability facts instead of throwing through bridge consumers.
- Malformed top-level method-channel payloads are caught at the bridge wrapper
  and returned as unavailable facts with decode warnings.

## Method-channel contracts
- Capture protection channel: `peerdeal/native_bridges/capture_protection`
  with `getCapability` and `setBlocking`.
- Local network channel: `peerdeal/native_bridges/local_network` with
  `getCapability` and `discoverPeers`.
- Secure key storage channel: `peerdeal/native_bridges/secure_key_storage` with
  `loadKeyRing`, `saveKey`, and `deleteKey`.
- Native transport channel: `peerdeal/native_bridges/transport` with
  `getCapability`, `sendFrame`, and `receiveFrames`.
- The Android and Windows hosts now back that channel with a bounded,
  host-private UDP multicast envelope on `239.255.42.99:40442`. The envelope
  is not a protocol artifact: it carries only the already-validated generic
  frame fields and is filtered by session and recipient peer on receive.
- Host socket availability does not prove local-network reachability. Device,
  firewall, multicast, other-platform, and product endpoint validation remain
  app/platform integration work.
- Missing payloads or platform errors must return unavailable facts with a
  warning, not throw through to policy or app code.

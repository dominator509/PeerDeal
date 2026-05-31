# peerdeal_native_bridges

Native bridge boundary for PeerDeal app shells.

## Purpose
This package owns platform-specific hooks that Dart packages and app shells need
to observe local device capabilities.

## Owns
- local-network permission and capability bridge seams
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
- Method-channel capture capability lookup returns unavailable capability facts
  when the platform payload is missing or throws.
- Method-channel local-network capability and discovery lookup return
  unavailable capability facts when the platform payload is missing or throws.
- Native bridge warnings are normalized for app-layer safe-surface and network
  routing policy.

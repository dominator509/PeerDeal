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

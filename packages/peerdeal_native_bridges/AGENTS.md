# AGENTS.md — peerdeal_native_bridges (LAN + Relay Overlay)

## Package purpose
Own platform-specific local-network hooks, permission surfaces, and transport-adjacent bridge shims needed by higher-level packages.

## Must not own
- poker rules
- protocol truth
- session routing decisions
- reducer behavior

## When modifying this package
1. Keep platform details behind explicit bridge contracts.
2. Return capability/permission/discovery facts, not policy decisions.
3. Avoid putting app orchestration in the plugin layer.
4. Keep bridge payloads normalized and minimal.

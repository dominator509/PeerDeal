# peerdeal_modes

Mode adapters and mode-scoped policy contracts for PeerDeal.

## Governance overlay

This overlay adds starter governance structures for:
- participant role state
- seat state
- waitlist state
- governance actions and decisions
- a starter governance engine

The governance lane remains mode-aware and replay-safe, but it does not become:
- a standalone package
- transport logic
- hand/action truth
- receipt or capture implementation

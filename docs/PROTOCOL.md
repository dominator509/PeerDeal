# PeerDeal Protocol

## Protocol purpose
One shared vocabulary for commands, events, snapshots, and version-safe replay across iPhone, iPad, Android, Windows, and Linux.

## Canonical truths
- Commands express intent.
- Events express accepted canonical state transitions.
- Snapshots accelerate recovery but never outrank verified events.

## Required envelope families
- command envelope
- event envelope
- snapshot envelope
- snapshot artifact identity
- result / error code family
- stable public protocol failure code constants
- structured protocol diagnostics
- replay/sync result diagnostic projection
- Game File public schema
- invite payload public schema

## Metadata required on canonical events
- event_id
- event_type
- event_version
- protocol_version
- event_seq
- table_id
- session_id
- hand_id
- emitted_at
- actor_ref
- payload
- prev_event_hash
- event_hash

## Initial scope in this starter pack
This repo starter only locks the spine:
- serialization shape
- validation boundaries
- canonical hash normalization
- fixture examples
- supported artifact catalog for fixture-backed and scaffold replay/recovery event types
- fail-safe rejection for unsupported protocol versions and unknown artifacts
- envelope-level catalog checks before downstream package processing

Later phases expand:
- full command catalog
- full replay windows
- recovery / snapshot semantics
- fairness anchors

## Hold'em lifecycle fixture chain
Hold'em lifecycle fixtures live in `peerdeal_protocol` because event identity is
protocol-owned. The canonical starter stream is:
- `holdem_hand_started_event_v1.json`
- `holdem_showdown_started_event_v1.json`
- `holdem_showdown_revealed_event_v1.json`
- `holdem_settlement_projected_event_v1.json`
- `holdem_hand_settled_event_v1.json`

The fail-closed settlement branch is:
- `holdem_settlement_blocked_event_v1.json`
- `holdem_settlement_blocked_empty_pot_event_v1.json`
- `holdem_settlement_blocked_invalid_showdown_event_v1.json`

`SettlementBlocked` payloads carry explicit `reason_codes` and `warnings` so
app/session/replay paths can distinguish blocked settlement causes without
inspecting variant-internal projection objects.

The uncontested branch is:
- `holdem_uncontested_settlement_projected_event_v1.json`

Downstream packages must consume these fixtures rather than creating ad hoc
Hold'em event shapes:
- `peerdeal_core` verifies reducer projection and invariant boundaries.
- `peerdeal_replay` verifies event-window replay and snapshot suffix selection.
- `peerdeal_sync` verifies recovery can resume from a snapshot plus suffix.

These fixtures do not move Hold'em rules into core, replay, or sync. Variant
ranking, street, and settlement input rules remain in `peerdeal_variants`; the
fixtures only define accepted protocol events those packages can process
deterministically.

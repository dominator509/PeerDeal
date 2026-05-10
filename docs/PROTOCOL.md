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
- result / error code family
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
- supported artifact catalog for currently fixture-backed command/event types
- fail-safe rejection for unsupported protocol versions and unknown artifacts
- envelope-level catalog checks before downstream package processing

Later phases expand:
- full command catalog
- full replay windows
- recovery / snapshot semantics
- fairness anchors

# PeerDeal Invite / Join / Rejoin Flow Integration Overlay v1 - Overview

## Purpose
This overlay gives the repo a concrete app/service-layer seam for:
- invite resolution
- disclosure acknowledgement collection
- role authorization
- bootstrap planning
- governance commit
- rejoin token restore path

It is the clean connection point between:
- Invite Payload + Join Handshake
- Governance Engine overlay
- Sync/recovery lane
- App shell orchestration

## Why this overlay exists
The locked specs already define the normalized join states and governance expectations, but
those rules should not live inside widgets and should not be pushed down into protocol schemas.
This overlay keeps orchestration explicit without inventing a new top-level package.

## Landing paths
- `apps/peerdeal_mobile/lib/join_flow/`
- `apps/peerdeal_mobile/test/join_flow/`
- `apps/peerdeal_desktop/lib/join_flow/`
- `apps/peerdeal_desktop/test/join_flow/`

## Main files
- `join_flow_models.dart`
- `join_flow_adapters.dart`
- `join_flow_orchestrator.dart`
- `fakes.dart`
- `join_flow_orchestrator_test.dart`

## Boundaries preserved
- `peerdeal_protocol` remains the owner of schema/envelope truth
- `peerdeal_modes` / governance overlay remains the owner of role/seat/waitlist policy truth
- `peerdeal_sync` remains the owner of restore/recovery coordination
- the app layer orchestrates the handshake flow and commits into governance

## Not included
- production networking
- real protocol envelope implementation
- production persistence
- actual platform UI
- real secure token storage

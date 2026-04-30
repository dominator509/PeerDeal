# PeerDeal Invite / Join / Rejoin Flow Integration Overlay v1

This overlay adds an app/service-layer integration seam for the private invite, join,
disclosure acknowledgement, role authorization, governance commit, and rejoin flow.

Purpose:
- keep handshake orchestration out of protocol schemas
- keep governance truth out of UI code
- connect invite/join/rejoin lifecycle to the governance engine cleanly
- preserve replay-safe, explicit state transitions

This overlay is meant to sit on top of:
- packages/peerdeal_protocol
- packages/peerdeal_modes
- packages/peerdeal_sync
- earlier governance and wizard overlays

It does NOT introduce a new top-level package.

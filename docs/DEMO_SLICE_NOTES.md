# Demo Slice Notes

## Purpose

The demo slice is the first believable stitched flow across the existing PeerDeal scaffolds.

It exists for:
- internal demos
- product review
- fixture-backed visual QA
- UI convergence before full engine integration
- identifying missing app-layer glue

## Ownership boundaries

- `peerdeal_protocol`: schema truth
- `peerdeal_core`: deterministic truth
- `peerdeal_modes`: mode policy
- `peerdeal_replay` / `peerdeal_sync` / `peerdeal_network`: operational truth
- `peerdeal_receipts`: receipt packaging
- `peerdeal_crypto`: verification engine
- `peerdeal_ui_kit`: shared components
- app layer: demo composition, route mounting, state translation

## Exit strategy

This demo slice should be progressively replaced by real bindings, not expanded into a hidden runtime truth layer.

## Current wiring status

- Receipt and recovery demo surfaces run through fixture -> presenter -> safe
  screen tests in both app shells.
- The reusable safe-surface widget/model contract lives in `peerdeal_ui_kit`.
- Capture-policy coordination and receipt/recovery projection remain app-layer
  orchestration.
- `apps/peerdeal_mobile/lib/main.dart` and
  `apps/peerdeal_desktop/lib/main.dart` mount the demo, receipt, join, and
  recovery-safe-surface routes through app-layer orchestration.

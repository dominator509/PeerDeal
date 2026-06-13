# Repo Inventory

Generated: 2026-06-13
Branch: `retrofit/baseline-v1`
Backup tag: `pre-retrofit-20260613T075234Z`

## Purpose

PeerDeal is a Dart/Flutter monorepo for deterministic peer-deal gameplay, replay, synchronization, receipt handling, privacy/retention policy, shared UI, native bridge contracts, and mobile/desktop demo orchestration.

## Workspace Shape

| Area | Count | Notes |
| --- | ---: | --- |
| `apps/` | 148 tracked files | App orchestration shells only. |
| `packages/` | 462 tracked files | Locked package boundaries for protocol, core, variants, modes, replay, sync, network, receipts, privacy, UI kit, native bridges. |
| `docs/` | 20 tracked files | Architecture, production readiness, dependency policy, AI context. |
| `scripts/` | 6 tracked files | Local audits and repository checks. |
| `.github/` | 1 tracked files | CI and automation. |

## Apps

- `apps/peerdeal_desktop`
- `apps/peerdeal_mobile`

## Packages

- `packages/peerdeal_capture`
- `packages/peerdeal_core`
- `packages/peerdeal_crypto`
- `packages/peerdeal_modes`
- `packages/peerdeal_native_bridges`
- `packages/peerdeal_network`
- `packages/peerdeal_privacy`
- `packages/peerdeal_protocol`
- `packages/peerdeal_receipts`
- `packages/peerdeal_replay`
- `packages/peerdeal_sync`
- `packages/peerdeal_testkit`
- `packages/peerdeal_ui_kit`
- `packages/peerdeal_variants`
- `packages/peerdeal_wizard`

## Root Files

`.gitignore`, `.repomixignore`, `AGENTS.md`, `PeerDeal_Invite_Join_Rejoin_Flow_Integration_Overlay_v1_Overview.md`, `README.md`, `analysis_options.yaml`, `claude.md`, `pubspec.lock`, `pubspec.yaml`

## Do-Not-Cross Boundaries

- Protocol schemas stay in `packages/peerdeal_protocol`.
- Deterministic reducer/state truth stays in `packages/peerdeal_core`.
- Variant-specific poker rules stay in `packages/peerdeal_variants`.
- Mode/session policy stays in `packages/peerdeal_modes`.
- Replay stays in `packages/peerdeal_replay`.
- Sync/recovery stays in `packages/peerdeal_sync`.
- Network confidence/routing stays in `packages/peerdeal_network`.
- Receipts stay in `packages/peerdeal_receipts`.
- Retention/privacy stays in `packages/peerdeal_privacy`.
- Shared UI stays in `packages/peerdeal_ui_kit`.
- Generic native OS hooks stay in `packages/peerdeal_native_bridges`.
- App orchestration stays in `apps/peerdeal_mobile` and `apps/peerdeal_desktop`.

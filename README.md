# PeerDeal Monorepo Bootstrap + Protocol Spine

PeerDeal is a privacy-first, invite-only, free-play decentralized poker engine.
This repository is the migration baseline for the package spine, deterministic
core contracts, protocol envelopes, and app-layer shells.

## What this repo includes

- monorepo workspace layout for apps and packages
- root `pubspec.yaml` as the canonical workspace and Melos script definition
- root repo-governing docs in `docs/`
- package manifests and package-local agent files
- starter `peerdeal_protocol` package with canonical envelopes, schema validators,
  fixtures, and tests
- starter `peerdeal_core` package with deterministic reducer boundaries
- starter variant, mode, replay, sync, network, receipt, privacy, capture, wizard,
  UI kit, native bridge, and testkit packages
- CI starter and repo boundary-check scripts

## What this repo intentionally does not do yet

- full hand lifecycle integration
- production networking, sync, and replay recovery
- production receipt cryptography
- production native capture implementation
- polished Flutter app UI

## Locked package ownership

- protocol schemas belong in `peerdeal_protocol`
- deterministic reducer/state truth belongs in `peerdeal_core`
- variant-specific poker rules belong in `peerdeal_variants`
- mode/session policy belongs in `peerdeal_modes`
- replay belongs in `peerdeal_replay`
- sync/recovery belongs in `peerdeal_sync`
- network confidence and routing belong in `peerdeal_network`
- receipts belong in `peerdeal_receipts`
- retention/privacy belongs in `peerdeal_privacy`
- shared UI belongs in `peerdeal_ui_kit`
- native OS hooks belong in `peerdeal_native_bridges`
- app orchestration belongs in `apps/peerdeal_mobile` and `apps/peerdeal_desktop`

## First stabilization target

Use this repo as the safe baseline for scaffold migration:

1. keep package boundaries explicit
2. keep protocol and reducer contracts deterministic
3. make local package checks runnable
4. land package-local fixes in small PRs
5. avoid hidden runtime truth in UI, transport, or wizard layers

## Production readiness

The current repo is a green migration baseline, not a production release. Use
`docs/PRODUCTION_READINESS.md` for the release gates and hardening order.

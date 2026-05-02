# PeerDeal Migration Baseline

This document records the scaffold baseline after the PR-01 stabilization and
PR-02 duplicate-wrapper cleanup.

## Baseline status
- The root workspace manifest and lockfile are tracked.
- Baseline command logs are tracked in `logs/`.
- Local Dart tool state is ignored.
- Package ownership follows `docs/PACKAGE_MAP.md`.
- No package should import another package's `src/` internals.

## Required local checks
Run these from the repository root before opening scaffold migration PRs:

```powershell
melos run boundary-check
melos run analyze
melos run test
```

## Current green baseline
- `melos run analyze` passes across all 17 packages.
- `melos run test` passes across the Dart and Flutter test lanes.
- Dart lane covers 13 non-Flutter packages.
- Flutter lane covers `peerdeal_mobile`, `peerdeal_desktop`,
  `peerdeal_ui_kit`, and `peerdeal_native_bridges`.

## Migration rule of thumb
For scaffold hardening, prefer the smallest patch that restores package
visibility, package-local tests, and documented ownership. Do not add product
features while stabilizing the baseline.

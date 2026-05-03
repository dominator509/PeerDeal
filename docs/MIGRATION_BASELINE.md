# PeerDeal Migration Baseline

This document records the scaffold baseline after the PR-01 stabilization and
PR-02 duplicate-wrapper cleanup.

## Baseline status
- The root workspace manifest and lockfile are tracked.
- Generated command logs are local diagnostics and are not tracked.
- Generated Python bytecode and cache folders are local diagnostics and are not
  tracked.
- Local Dart tool state is ignored.
- Package ownership follows `docs/PACKAGE_MAP.md`.
- No package should import another package's `src/` internals.

## Required local checks
Run these from the repository root before opening scaffold migration PRs:

```powershell
melos run boundary-check
melos run boundary-check:test
melos run dependency-audit
melos run dependency-audit:test
melos run analyze
melos run test
```

To capture local logs while validating a migration patch:

```powershell
melos run analyze 2>&1 | Tee-Object logs\analyze_after_patch.txt
melos run test 2>&1 | Tee-Object logs\test_after_patch.txt
```

## Current green baseline
- `melos run analyze` passes across all 17 packages.
- `melos run test` passes across script, Dart, and Flutter test lanes.
- Dart lane covers 13 non-Flutter packages.
- Flutter lane covers `peerdeal_mobile`, `peerdeal_desktop`,
  `peerdeal_ui_kit`, and `peerdeal_native_bridges`.
- The Flutter test lane runs serially to avoid Flutter startup lock contention
  on Windows.
- The Flutter test lane assumes the workspace has been bootstrapped and uses
  `--no-pub` to avoid repeated dependency resolution during tests.
- Dependency audit may report newer packages. Treat that as information unless
  `docs/DEPENDENCY_POLICY.md` says an upgrade is required.

## Migration rule of thumb
For scaffold hardening, prefer the smallest patch that restores package
visibility, package-local tests, and documented ownership. Do not add product
features while stabilizing the baseline.

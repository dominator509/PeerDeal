# PeerDeal Dependency Policy

PeerDeal dependency changes should be deliberate, reviewable, and separated
from scaffold or feature work.

## Audit command
Run this from the repository root:

```powershell
melos run dependency-audit
```

This command reports available package versions. It must not modify
`pubspec.yaml` files or `pubspec.lock`.

The command wraps `flutter pub outdated --json` so the repo gets a concise
summary even when the pub client emits advisory metadata warnings.

## Upgrade rule
Do not upgrade dependencies just because newer versions exist. Open a dedicated
dependency PR when one of these is true:

- a security advisory or toolchain warning requires the upgrade
- Flutter or Dart compatibility requires the upgrade
- a package owner needs a newer API for an approved feature
- analyzer or test stability requires a newer compatible version

## Review requirements
A dependency PR must include:

- affected direct dependencies
- whether transitive versions changed
- package lanes tested
- any analyzer or lint rule changes
- rollback notes when the upgrade affects shared tooling

## Current baseline note
As of the 2026-08-29 dedicated dependency refresh, the workspace uses Melos
8.6.0 and the newest resolvable lint/tooling baseline. The root `melos` dev
dependency moved from 8.5.0 to 8.6.0, and the lockfile refreshed exactly eight
compatible transitive packages: `glob`, `io`, `mime`, `pool`, `process`,
`pub_semver`, `pubspec_parse`, and `yaml`.
No analyzer or lint rules changed. The post-refresh audit reports 0 actionable
upgrades and 14 newer package versions below latest because current constraints
or the Flutter/Dart toolchain do not permit them; `meta` and `test` remain
toolchain-blocked.

If the audit command reports advisory metadata warnings from pub.dev while
still exiting successfully, treat the version table as useful and rerun the
audit after the Dart/Flutter toolchain receives an update.

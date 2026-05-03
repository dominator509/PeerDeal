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
As of the migration baseline, `flutter pub outdated` reports newer versions for
some test and lint tooling. These warnings are non-blocking while analyze and
test remain green.

If the audit command reports advisory metadata warnings from pub.dev while
still exiting successfully, treat the version table as useful and rerun the
audit after the Dart/Flutter toolchain receives an update.

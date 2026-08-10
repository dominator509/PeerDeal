# Repo Brief

Status: Populated from `repomix-summary.xml` on 2026-06-07; reviewed by Codex.

## Purpose

PeerDeal is a deterministic, event-sourced, privacy-first poker engine with
Flutter app shells. Commands express intent; accepted events are canonical
truth. Every hand/session must be reconstructable from ordered protocol events.

## Stack

| Area | Current source fact |
| --- | --- |
| Language | Dart SDK `^3.11.5` |
| UI | Flutter mobile and desktop app shells |
| Workspace | Dart pub workspace plus Melos `^8.2.2` |
| Lints | `package:lints/recommended.yaml` and package analysis options |
| Scripts | Python checks for boundaries, source text, and dependencies |
| CI | GitHub Actions on Flutter stable |
| Core deps | `crypto`, `collection`, `meta` |
| Test deps | `test`, `flutter_test`, `lints`, `flutter_lints` |

## Main Apps

| Path | Owns |
| --- | --- |
| `apps/peerdeal_mobile` | Flutter mobile shell, Android host, demo routes, app orchestration |
| `apps/peerdeal_desktop` | Flutter desktop shell, demo routes, app orchestration |

## Main Packages

| Package | Boundary |
| --- | --- |
| `peerdeal_protocol` | Protocol schemas, envelopes, catalog identities, diagnostics |
| `peerdeal_core` | Deterministic table state, reducer, invariants, pot math |
| `peerdeal_variants` | Variant-specific poker rules, currently Hold'em-focused |
| `peerdeal_modes` | Mode/session policy, governance, roles, seats, waitlist |
| `peerdeal_replay` | Replay requests, event-window validation, anchor hashing |
| `peerdeal_sync` | Snapshot apply, conflict detection, recovery coordination |
| `peerdeal_network` | Route classification, confidence, primary-peer election |
| `peerdeal_crypto` | Provider proof normalization and verification |
| `peerdeal_receipts` | Receipt authorization, scan/wipe/export, signing/encryption |
| `peerdeal_privacy` | Retention, minimization, diagnostics scrubbing |
| `peerdeal_capture` | Capture-sensitive surface policy |
| `peerdeal_ui_kit` | Shared UI models/widgets such as safe surfaces |
| `peerdeal_native_bridges` | Method-channel seams for native platform facts |
| `peerdeal_testkit` | Shared test helpers and fixture utilities |
| `peerdeal_wizard` | Setup intent normalization, preset resolution, validated setup plans, Game File compilation, and tooltip/helper metadata |

## Commands

Use `rtk` before shell commands in this environment.

```bash
dart run melos run analyze
dart run melos run boundary-check
dart run melos run source-text
dart run melos run dependency-audit
dart run melos run test
```

Focused package iteration:

```bash
dart test
flutter test --no-pub
dart analyze .
```

## Dependency Law

- Apps consume package public APIs only.
- Do not import another package's `src/`.
- `peerdeal_core` is deterministic reducer/state truth.
- Variant-specific rules stay in `peerdeal_variants`.
- Mode/session policy stays in `peerdeal_modes`.
- Native OS hooks stay in `peerdeal_native_bridges`.
- App shells orchestrate; UI never owns game truth.

## Auth And Identity

- No traditional auth server is present in this scaffold.
- Identity is modeled through protocol/app data such as actor refs,
  pseudonymous receipt users, session ids, and receipt binding modes.
- Receipt restore/scan must fail closed for wrong user, wrong session, wiped
  receipts, malformed artifacts, or unavailable key material.

## Persistence

- Source of truth is ordered protocol events.
- Snapshots accelerate recovery but do not outrank verified events.
- Receipts are opaque export artifacts, not a general database.
- Android mobile now has a Keystore-backed generic secure-key host, and the
  Windows desktop host now uses Credential Manager, both behind the existing
  method-channel contract. Android and Windows capture enforcement is now
  host-backed, with runtime/device validation still open. App shells prefer
  explicit `PEERDEAL_RECOVERY_ROOT` and otherwise use the generic app-support
  directory bridge: Android private no-backup storage or Windows `LocalAppData`.
  Android and Windows now also provide bounded host-backed native peer
  transport through the existing channel, but device/network reachability,
  production database persistence, other-platform storage, and other platform
  implementations remain readiness gaps documented in
  `docs/PRODUCTION_READINESS.md`. App shells now
  expose deterministic retention coordinators that connect close-time policy
  decisions to the scoped recovery-store wipe primitive, plus per-session close
  coordinators that cache the first result and prevent duplicate policy or wipe
  work. App-owned protocol event adapters now map supported `SessionClosed`
  envelopes and their `emitted_at` timestamps into that boundary. Mirrored
  `AppTableSessionRuntime` owners bind ordered protocol events to core state and
  commit close state only after retention succeeds. The protocol exposes a
  bounded canonical `EventEnvelopeCodec`, and mirrored app transport handlers
  decode validated byte frames into that runtime. Loaded native sessions also
  expose bounded app-owned source scheduling with serialized polls and
  lifecycle stop/dispose behavior. Both app shells provide an
  `AppTableSessionTransportProvisioner` that composes the runtime handler with
  a validated native session and route-ready source, then inject the source
  into the table route, whose mount owns replacement and disposal. Native peer
  Platform source provisioning and device/network transport validation remain
  integration gaps; Android/Windows app-private recovery-root selection and
  host-backed transport are now wired.
  Mirrored `AppHoldemTableSessionRuntime` owners now compose local Hold'em
  lifecycle projection through the variant adapter and atomically commit its
  non-retention event batches before advancing variant state/cursors. The
  public variant event reducer and cursor acceptance now reconstruct canonical
  remote Hold'em events before the app commits them through core; generic
  core-only transport remains available for non-variant sessions. Mirrored
  `AppHoldemTableSessionRoute` owners now compose the validated runtime with
  source lifecycle and accepted-event surface refresh; their route context can
  publish canonical projection frames and report partial sends. Native live
  transport and actual product route/state wiring remain open. Mirrored
`AppHoldemProductionRouteRegistration` owners now merge typed Hold'em routes
into the app route map and native-readiness gate. The
`withDefaultSurface(...)` factory mounts the app-owned bounded production
table surface; callers still provide the validated session/state source and
local identity. Mirrored `AppHoldemProductionSessionFactory` owners now bind
those product inputs to the table/Hold'em runtimes and default surface with
fail-closed metadata, seat, polling, and cursor/session checks. Projection
retries resume from the publisher's event offset. Mirrored
`AppHoldemProductionSessionSource` and `AppHoldemProductionSessionBootstrap`
owners now provide the resolved-invite handoff, validate hydrated table/cursor
scope, and invoke the factory without deriving live identity from demo or Game
File data. The concrete source, durable persistence, local identity, and
device/network validation remain integration-owned.

## Do Not Touch Without Approval

- Secrets, `.env` files, credentials, and key material.
- Production infrastructure or deployment credentials.
- Native platform implementations outside the scoped task.
- Unrelated app styling, branding, graphics, or animation work.
- Package boundary architecture or root workspace membership unless requested.

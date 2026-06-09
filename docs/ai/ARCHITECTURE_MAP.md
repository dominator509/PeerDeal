# Architecture Map

Status: Populated from `repomix-summary.xml` on 2026-06-07; reviewed by Codex.

## System Overview

PeerDeal is a peer-to-peer, event-sourced poker engine with Flutter client
shells. There is no central server in the current scaffold. Truth flows from
ordered protocol events through deterministic reducers. Variant and mode
packages add policy without mutating universal core truth.

## Layer Stack

| Layer | Packages / apps | Responsibility |
| --- | --- | --- |
| App orchestration | `apps/peerdeal_mobile`, `apps/peerdeal_desktop` | Routes, setup/join flows, demo slices, app-owned presenters/controllers, native-to-package mapping, native transport composition |
| Shared UI | `peerdeal_ui_kit` | Safe-surface widgets and render models |
| Native seams | `peerdeal_native_bridges` | Method-channel contracts for platform facts and generic byte transport |
| Network confidence | `peerdeal_network` | Route class, confidence, primary peer selection, transport frame send/receive gates |
| Replay/recovery | `peerdeal_replay`, `peerdeal_sync` | Event windows, anchors, snapshots, safe-close recovery |
| Privacy/receipt/capture | `peerdeal_privacy`, `peerdeal_receipts`, `peerdeal_capture` | Retention, receipt artifacts, capture policy |
| Mode/variant policy | `peerdeal_modes`, `peerdeal_variants` | Session mode policy and poker variant rules |
| Deterministic truth | `peerdeal_core` | Table state, reducer, invariants, pot/settlement primitives |
| Protocol | `peerdeal_protocol` | Envelopes, catalog, fixtures, diagnostics |

## Package Boundary Rules

- `peerdeal_protocol` has no PeerDeal package dependency.
- `peerdeal_core` depends on protocol, not on variants, modes, network, UI,
  receipts, privacy, capture, or native bridges.
- `peerdeal_variants` and `peerdeal_modes` may depend on protocol/core.
- Apps can depend on package public APIs, not package `src/` internals.
- Boundary enforcement lives in `scripts/check_package_boundaries.py` and runs
  through `melos run boundary-check`.

## Data Flow

User/app intent:

1. App/controller forms a protocol command or invokes a package boundary.
2. Core validation checks the command against current deterministic state.
3. Accepted behavior becomes ordered protocol events.
4. Core reducer projects state from ordered events.
5. Invariant guards check impossible table/hand/session states.
6. UI renders projected state and never becomes authoritative truth.

Recovery:

1. Recovery request carries optional `SnapshotEnvelope` plus ordered events.
2. Replay validates event windows, gaps, anchors, and unsupported versions.
3. Sync detects conflicts and applies snapshot plus suffix events.
4. Fatal conflicts recommend safe close instead of unsafe resume.

Receipts:

1. Receipt service exports minimized receipt data.
2. App-owned export factories provision native-backed receipt keys, then
   optional signing/encryption produces opaque artifacts.
3. Import/scan verifies signatures, decrypts when configured, and authorizes
   session/user binding.
4. Wiped or malformed receipts fail closed.

## API Boundaries

There is no REST or GraphQL API in this scaffold. The API surface is the set of
public Dart package barrels, such as `lib/peerdeal_core.dart` and
`lib/peerdeal_protocol.dart`.

| Boundary | Stable entry point |
| --- | --- |
| Protocol envelopes/catalog | `packages/peerdeal_protocol/lib/peerdeal_protocol.dart` |
| Core reducer/state | `packages/peerdeal_core/lib/peerdeal_core.dart` |
| Variants | `packages/peerdeal_variants/lib/peerdeal_variants.dart` |
| Modes/governance | `packages/peerdeal_modes/lib/peerdeal_modes.dart` |
| Replay | `packages/peerdeal_replay/lib/peerdeal_replay.dart` |
| Sync/recovery | `packages/peerdeal_sync/lib/peerdeal_sync.dart` |
| Receipts | `packages/peerdeal_receipts/lib/peerdeal_receipts.dart` |
| Wizard/setup | `packages/peerdeal_wizard/lib/peerdeal_wizard.dart` |
| Native bridges | `packages/peerdeal_native_bridges/lib/peerdeal_native_bridges.dart` |

## Persistence

- No production database is present.
- Event streams are the authoritative state source.
- Snapshots are recovery accelerators only.
- Receipts are export/restore artifacts, not general persistence.
- Sync recovery has in-memory and canonical JSON file-backed recovery-window
  stores plus app-owned durable store factories, validated
  exact `PEERDEAL_RECOVERY_ROOT` configuration, and mounted table-route
  loading; platform/database persistence remains a production gap.
- Secure key storage has Dart/method-channel read/write seams plus app-owned
  receipt key-ring provisioning, namespace validation, mapping, and
  ambiguous-active-key and delete key-id rejection. Generic method-channel
  requests reject malformed secure-key namespaces and records before platform
  calls; platform implementations remain a production-readiness gap.

## Auth / Authorization

- No central auth service exists in the current repo.
- Governance/roles live in mode policy.
- Receipt authorization checks pseudonymous user/session binding.
- Provider-proof verification lives in `peerdeal_crypto`.

## Risk Areas

| Risk | Status |
| --- | --- |
| Production transport | Native transport method-channel seam, app-owned capability-gated transport adapters/factories, payload-limit enforcement across session/sender/drain entry points, sink validation before native sends, receive-scope validation before native drains, and network frame gates exist; no live peer transport implementation yet |
| Platform key storage | Method-channel read/write seams plus generic secure-key request validation, app-owned receipt key provisioning, namespace validation, ambiguous active-key rejection, delete key-id validation, export, and verification mapping exist; native implementation pending |
| Persistence | Canonical recovery-window file store, app-owned store factories, exact validated environment-configured recovery roots, and mounted recovery-window loading exist; production database/platform persistence not implemented |
| App flows | Demo routes plus mounted setup/join orchestration seams, route-level and orchestrator join input validation, route-level and orchestrator setup identity validation, bounded mounted table/join native bootstrap mapping with exact scope validation, mounted receipt export/verify wiring, app-owned route registries, exact enabled demo-route gates, validated app-owned production route maps, validated app-owned initial routes, validated production navigation descriptors, app-owned home surface builders, and unknown-route fallback exist; production navigation polish remains |
| UI polish | Shared app-shell scaffold/action/status/info primitives exist and mounted home/table/chat/receipt/join/setup/fallback routes consume them; app shells can replace demo home surfaces through runtime builders; final production UI validation remains |
| Capture blocking | Best-effort policy only; platform limits must be stated honestly |

## Do Not Cross

- Do not put variant rules in `peerdeal_core`.
- Do not put mode/session policy in core reducers.
- Do not put receipt semantics in `peerdeal_native_bridges`.
- Do not import package `src/` across package boundaries.
- Do not change protocol catalog identities without fixture/test updates.

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
| App orchestration | `apps/peerdeal_mobile`, `apps/peerdeal_desktop` | Routes, setup/join flows, demo slices, app-owned presenters/controllers, protocol SessionClosed-to-retention mapping, recovery retention and exactly-once session-close coordination, app-owned table-session runtime projection, native-to-package mapping, native transport composition, native readiness aggregation |
| Shared UI | `peerdeal_ui_kit` | Safe-surface widgets and render models |
| Native seams | `peerdeal_native_bridges` plus app hosts | Method-channel contracts for platform facts, generic byte transport, and secure key records; mobile Android and Windows desktop supply secure-key host implementations |
| Network confidence | `peerdeal_network` | Route class, bootstrap/path/election peer-id gates, confidence, primary peer selection, transport frame send/receive gates |
| Replay/recovery | `peerdeal_replay`, `peerdeal_sync` | Event windows, request ranges, anchors, snapshots, safe-close recovery |
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

Transport ingress:

1. `peerdeal_network` validates a generic byte frame before the app handler.
2. `peerdeal_protocol.EventEnvelopeCodec` decodes bounded canonical event bytes.
3. The app handler binds frame/session identity and delegates the event to
   `AppTableSessionRuntime`.
4. The runtime delegates deterministic projection to `peerdeal_core` and only
   commits accepted events, including retention-gated close events.
5. An app-owned source controller can schedule bounded polls of the loaded
   native drain, serialize overlapping polls, and stop with the route lifecycle.
6. The app runtime can inject that source into the table route, whose mount
   owns source replacement and disposal.

Recovery:

1. Recovery request carries optional `SnapshotEnvelope` plus ordered events.
2. Replay validates request ranges, event windows, gaps, anchors, and unsupported versions.
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
  stores with exact recovery scope-identity validation plus app-owned durable
  store factories, validated
  exact `PEERDEAL_RECOVERY_ROOT` configuration, and mounted table-route
  loading; app-owned retention and per-session exactly-once close seams now
  connect policy decisions to scoped wipe, and app event adapters validate and
  map supported `SessionClosed` envelopes, and app-owned table-session runtimes
  bind ordered events to core projection and close retention; platform/database
  persistence and production source provisioning remain production gaps; the
  bounded app scheduler and route lifecycle mount now exist around loaded
  native drains.
- Secure key storage has Dart/method-channel read/write seams plus app-owned
  receipt key-ring provisioning, namespace validation, mapping, and
  ambiguous-active-key and delete key-id rejection. Generic method-channel
  requests reject malformed secure-key namespaces and records before platform
  calls. The mobile Android host encrypts generic records with an Android
  Keystore AES-GCM key, and the Windows desktop host persists a bounded
  versioned envelope in Credential Manager. Runtime persistence validation and
  other platform implementations remain production-readiness gaps.

## Auth / Authorization

- No central auth service exists in the current repo.
- Governance/roles live in mode policy.
- Receipt authorization checks pseudonymous user/session binding.
- Provider-proof verification lives in `peerdeal_crypto`.

## Risk Areas

| Risk | Status |
| --- | --- |
| Production transport | Native transport method-channel seam, package-owned exact transport frame identity validation, generic native transport sequence, byte-payload, and exact-key validation, bounded canonical protocol event-byte decoding, app-owned capability-gated transport adapters/factories, payload-limit enforcement across readiness/session/sender/drain entry points, sensitive native-note scrubbing, package-owned bootstrap/path/election/transfer/fallback peer-id gates, sink validation before native sends, receive-scope validation and receive-batch bounding before native drains/session handlers, frame-to-runtime event ingestion, bounded serialized app source scheduling, and route lifecycle source mounting exist; native peer transport implementation and production source provisioning remain |
| Platform key storage | Method-channel read/write seams plus generic secure-key request validation, app-owned receipt key provisioning with factory failure handling, namespace validation, native-readiness namespace validation, native key-record snapshot bounding, native key-id metadata bounding, receipt key-material bounding, mutation key-id bounding, ambiguous active-key rejection, delete key-id validation, export with provisioning diagnostic scrubbing and exception handling, verifier key-ring load exception handling, verifier key-ring and decoder diagnostic scrubbing and bounding, and verification mapping exist; Android Keystore and Windows Credential Manager hosts compile, while runtime persistence validation and other platforms remain |
| Persistence | Canonical recovery-window file store, exact recovery scope-identity validation, app-owned store factories, exact validated environment-configured recovery roots, and mounted recovery-window loading exist; production database/platform persistence not implemented |
| App flows | Demo routes plus mounted setup/join orchestration seams, route-level and orchestrator join input validation, route-level and orchestrator setup identity validation, join/setup outcome diagnostic scrubbing, bounded join diagnostic rendering, bounded setup error/warning rendering, mounted join/setup async dependency reload handling, mounted table warning rendering plus route-level load warning scrubbing/bounding, bootstrap candidate caps, recovery-window display count caps, mounted table runtime-scope reload handling, mounted receipt render diagnostic scrubbing and bounding, bounded mounted table/join native bootstrap mapping with exact scope validation, generic local-network discovery list validation, local-network sensitive-note and endpoint scrubbing, mounted receipt export/verify wiring, app-owned native readiness aggregation, ordered app table-session runtime projection with close-retention commit gating, optional injected transport source runtime wiring, route-owned source start/replacement/disposal, default-home rendering, production-route gating, production-navigation filtering, default-home production/demo navigation sectioning, production-only default-home demo suppression, production-only native-readiness empty-action handling, production-only empty-action status rendering, custom-home native-readiness production-navigation filtering, and custom-home native-readiness production-navigation restore, app-owned route registries with bounded route metadata, exact and bounded enabled demo-route gates, validated and capped route-map allowed extras, route-map allowed-extra case-collision validation, scrubbed route-map drift diagnostics, sensitive unknown-route diagnostic suppression, validated and capped app-owned production route maps, case-insensitive production and production/demo route/navigation collision rejection, case-insensitive demo namespace reservation for production and extra route paths, validated app-owned initial routes, validated and capped production navigation descriptors, unsafe and oversized production route metadata rejection, home navigation collision validation, app-owned production route builder failure handling, app-owned home surface builders, and unknown-route fallback exist; native transport provisioning and production navigation polish remain |
| UI polish | Shared app-shell scaffold/action/status/info primitives plus safe-surface render text scrubbing exist and mounted home/table/chat/receipt/join/setup/fallback routes consume them; app shells can replace demo home surfaces through runtime builders; final production UI validation remains |
| Capture blocking | Generic action/release lifecycle plus app-owned warning scrubbing exists; Android `FLAG_SECURE` and Windows `SetWindowDisplayAffinity` hosts compile, while runtime/device validation and other-platform enforcement remain |

## Do Not Cross

- Do not put variant rules in `peerdeal_core`.
- Do not put mode/session policy in core reducers.
- Do not put receipt semantics in `peerdeal_native_bridges`.
- Do not import package `src/` across package boundaries.
- Do not change protocol catalog identities without fixture/test updates.

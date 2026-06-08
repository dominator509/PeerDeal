# API Contracts

Status: Populated from `repomix-summary.xml` on 2026-06-07; reviewed by Codex.

PeerDeal has no REST or GraphQL server in this scaffold. The stable contracts
are Dart package public APIs plus protocol envelope schemas.

## Protocol Envelopes

All wire-ish protocol data lives in `peerdeal_protocol`.

| Envelope | Durable fields |
| --- | --- |
| `CommandEnvelope` | `command_id`, `command_type`, `command_version`, `protocol_version`, `table_id`, `session_id`, `actor_ref`, `payload`, `command_seq` |
| `EventEnvelope` | `event_id`, `event_type`, `event_version`, `protocol_version`, `event_seq`, `table_id`, `session_id`, `hand_id`, `emitted_at`, `actor_ref`, `payload`, `prev_event_hash`, `event_hash` |
| `SnapshotEnvelope` | `snapshot_id`, `snapshot_type`, `snapshot_version`, `protocol_version`, `table_id`, `session_id`, `snapshot_base_event_seq`, `snapshot_hash`, `payload` |
| `ProtocolDiagnostic` | `code`, `message`, optional `expected`, optional `actual` |

Unsupported protocol versions and unknown catalog identities fail closed.

## Protocol Catalog

The default catalog owns supported artifact identities for:

- Commands.
- Events.
- Snapshots.
- Game File payloads.
- Invite payloads.
- Public protocol result codes.

When changing catalog identities, update protocol fixtures and catalog-lock
tests in the same change.

## Public Package APIs

Agents should import each package through its barrel file:

| Package | Public API |
| --- | --- |
| `peerdeal_protocol` | `package:peerdeal_protocol/peerdeal_protocol.dart` |
| `peerdeal_core` | `package:peerdeal_core/peerdeal_core.dart` |
| `peerdeal_variants` | `package:peerdeal_variants/peerdeal_variants.dart` |
| `peerdeal_modes` | `package:peerdeal_modes/peerdeal_modes.dart` |
| `peerdeal_replay` | `package:peerdeal_replay/peerdeal_replay.dart` |
| `peerdeal_sync` | `package:peerdeal_sync/peerdeal_sync.dart` |
| `peerdeal_network` | `package:peerdeal_network/peerdeal_network.dart` |
| `peerdeal_crypto` | `package:peerdeal_crypto/peerdeal_crypto.dart` |
| `peerdeal_receipts` | `package:peerdeal_receipts/peerdeal_receipts.dart` |
| `peerdeal_privacy` | `package:peerdeal_privacy/peerdeal_privacy.dart` |
| `peerdeal_capture` | `package:peerdeal_capture/peerdeal_capture.dart` |
| `peerdeal_wizard` | `package:peerdeal_wizard/peerdeal_wizard.dart` |
| `peerdeal_ui_kit` | `package:peerdeal_ui_kit/peerdeal_ui_kit.dart` |
| `peerdeal_native_bridges` | `package:peerdeal_native_bridges/peerdeal_native_bridges.dart` |

Do not import another package's `src/`.

## App Route Surface

Current app shells mount demo-oriented routes rather than production app flows.
Verified mounted route categories include:

- Demo home / scenario selection.
- Table surface.
- Chat surface.
- Receipt/recovery surface.
- Join flow.
- Setup flow.
- Unknown route fallback.

Concrete mounted demo route paths are app-shell details owned by each app's
`DemoSliceRoutes` registry. App `MaterialApp` route maps validate against that
registry at construction time, with `/` allowed only as an explicit framework
default-route alias. App runtime objects may also provide validated non-demo
production route maps; `/demo/*` stays reserved for the demo registry.
Production navigation remains app-shell work and should replace or extend app
routes without moving route policy into shared packages.

## Network Transport Boundary

`peerdeal_network` exposes transport frame validation plus validating send and
receive contracts. Platform transport adapters should receive outbound frames
only through the validating sender boundary, and inbound frames should reach
session handlers only through the validating receiver boundary. Malformed frames
are rejected before adapter/handler code runs, and adapter/handler failures
become explicit failed transport results.

Mobile and desktop `NativeTransportSessionFactory` instances own the app
payload limit used by the default `BasicTransportFrameValidator`. Session
loading fails closed when native capability reports a non-positive
`maxPayloadBytes` or a value above the app validator limit.

## Recovery Persistence Boundary

`peerdeal_sync` owns recovery-window validation and JSON file store contracts.
App shells own durable root selection. `AppRecoveryPersistenceStoreFactory`
accepts an injected root directory factory, and the mobile/desktop shells may
default it from `PEERDEAL_RECOVERY_ROOT`. Blank, missing, or throwing roots fail
closed before mounted table routes load recovery windows.

## Local Network Bootstrap Boundary

`peerdeal_native_bridges` exposes generic local-network capability and discovery
facts only. Mobile and desktop app loaders/coordinators trim, deduplicate, and
cap discovered peer endpoints before passing them to `peerdeal_network`
bootstrap candidate resolution. Invalid caps fail closed for table loading and
fall back to relay-only join bootstrap plans.

## Error Shape

- Protocol failures use `ProtocolDiagnostic`.
- Sync/replay failures expose structured mismatch/conflict codes.
- Receipt import/export/verification failures must fail closed.
- App orchestration should surface scrubbed diagnostics, not raw secrets,
  credentials, or platform exception payloads.

## Auth Requirements

- No central auth token/session contract exists in the scaffold.
- Receipt authorization is based on session/user binding.
- Provider-proof verification belongs to `peerdeal_crypto`.
- Mode governance owns role and seat authority.

## Frontend Expectations

- Use package APIs and app-level presenters/controllers.
- Render through shared safe-surface UI where sensitive.
- Never mutate core state directly from UI.
- Never parse or reinterpret receipt key material in UI.
- Never construct platform method channels inside receipt screens; use app
  boundary factories/loaders.

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
| `peerdeal_ui_kit` | `package:peerdeal_ui_kit/peerdeal_ui_kit.dart` |
| `peerdeal_native_bridges` | `package:peerdeal_native_bridges/peerdeal_native_bridges.dart` |

Do not import another package's `src/`.

## App Route Surface

Current app shells mount demo-oriented routes rather than production app flows.
Known route categories include:

- Demo home / scenario selection.
- Table surface.
- Chat surface.
- Receipt/recovery surface.
- Join flow.

TODO: Treat concrete route paths and production navigation as app-shell details
unless verified from the app route source in the current branch.

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

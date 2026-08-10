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

Replay requests with `fromEventSeq` or `toEventSeq` must use positive event
sequence bounds, and `fromEventSeq` must not exceed `toEventSeq`. Invalid
replay ranges fail before event filtering, anchor calculation, or projector
execution.

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
Enabled demo route allowlists must use exact, nonblank route paths; padded
allowlist entries fail closed before route matching.
Enabled demo route allowlists must also use bounded canonical `/demo` route
paths with no query, fragment, duplicate slash, backslash, or control
characters. Unknown enabled demo paths fail without echoing the supplied path.
Mounted demo route-map drift validation must fail with stable generic
diagnostics rather than echoing supplied unexpected route keys.
Mounted demo route registry labels and surface names must be exact, bounded,
non-empty strings without control characters before app route maps or
navigation consume them.
Mounted demo route-map allowed extras must be `/` or bounded non-demo
production-style absolute paths without query, fragment, duplicate slash,
backslash, trailing slash, whitespace, or control characters.
Mounted demo route-map allowed extras must also reject case-insensitive
duplicate extension paths.
Enabled demo route allowlists and mounted demo route-map allowed-extra path
sets must be capped before path validation.
Runtime objects may set the initial route only to `/`, an enabled demo route,
or a validated production route. Runtime objects may also expose validated
production navigation descriptors whose paths must reference mounted production
routes. Runtime objects may provide an app-owned home surface builder, which
receives validated home navigation entries and may replace the default demo
home surface; builder failures render the existing route-unavailable fallback.
Mounted production route builder failures also render the existing
route-unavailable fallback instead of escaping app-shell routing.
Unknown route fallback surfaces must suppress sensitive route names instead of
echoing token, secret, password, or platform path-like route diagnostics.
Production route paths and startup routes must not contain control characters
or whitespace, and production navigation labels must not contain control
characters. Production route paths and startup routes must also be bounded and
must not contain backslash separators. Production route paths and demo
route-map allowed extra paths must reserve the `/demo` namespace
case-insensitively. Production navigation labels must be
bounded before app home composition. Production route maps and production
navigation descriptor lists must also be capped before app route maps or home
navigation are built. Production navigation labels and paths
must not collide with enabled demo home navigation entries when the app
composes the home surface.
Production route paths and production navigation labels must not collide
case-insensitively within app-owned production extension metadata.
Production navigation labels and paths must also not collide
case-insensitively with enabled demo home navigation entries.
Production navigation and home composition remain app-shell work and should
replace or extend app routes without moving route policy into shared packages.
Mounted receipt surfaces scrub receipt/recovery status, messages, shareable
fields, recommended actions, and diagnostics before rendering. Rendered receipt
shareable fields and recovery diagnostics must be bounded with stable
truncation lines.
Capture surface coordinators must scrub native warning detail and replace
sensitive native notes with stable unavailable text before UI projection.
The capture protection bridge exposes `getCapability` and `setBlocking` on
`peerdeal/native_bridges/capture_protection`. App coordinators serialize
blocking and release actions, and a failed or unconfirmed blocking action
downgrades the sensitive surface to visual obscuring with a scrubbed warning.
The action result reports both `success` and `blockingEnabled`; native hosts
must not expose receipt or capture policy semantics beyond this generic seam.
Mobile and desktop app-native readiness loaders compose generic capture,
local-network, transport, and secure-key storage bridge capability facts into
stable readiness snapshots. Loader warnings must be app-owned stable strings;
native warning detail and exceptions must not be exposed.
Native-readiness secure-key namespaces must be exact nonblank strings without
padding, control characters, or the `::` storage delimiter before app loaders
call platform secure storage.
Native-readiness transport capability checks must enforce the app-owned payload
limit before reporting native transport ready; invalid app limits fail before
native transport capability lookup.
Runtime objects may inject those loaders into the default app home surface,
which renders stable native ready/unavailable status. Custom home builders stay
app-owned and are not forced into an async readiness contract.
Runtime objects may also mark mounted production route paths as
native-readiness-required. Those route paths must be exact validated production
paths, and protected builders must not run until readiness reports all native
capabilities ready.
Default home surfaces must also hide production navigation actions whose paths
require native readiness until the same readiness snapshot passes. Custom home
builders remain app-owned and receive validated navigation entries after the
same native-readiness production-navigation filtering; protected entries must
be present for custom homes once readiness passes.
Default home surfaces must render production navigation separately from enabled
demo navigation; custom home builders continue to receive the combined
validated navigation entries directly.
When the default home has production navigation but no enabled demo navigation
actions, it must suppress demo fixture scenario controls and use
production-oriented title/subtitle text. Native-readiness filtering must not
make a production-only default home fall back to demo fixture presentation when
all protected production actions are temporarily hidden. If production
navigation exists but no production action is currently launchable, the default
home must render a stable production unavailable state.
Shared safe-surface render models must scrub and bound injected capture warning
and native-note text before exposing render state to app UI.
Mounted table routes must scrub and bound injected bootstrap/recovery warning
lists before passing load results into table surfaces.
Mounted table routes must cap injected bootstrap candidate lists before passing
load results into table surfaces.
Mounted table routes must cap displayed recovery persistence event counts for
injected recovery windows before passing load results into table surfaces.
Mounted table routes must reload bootstrap and recovery persistence lookups when
the app-owned runtime scope factory changes.
Join routes and join flow orchestration reject blank or padded app-owned invite
codes and rejoin tokens before join dependencies, invite resolution, or
governance commit adapters run. Join routes scrub app-owned join outcome result
codes and diagnostics before rendering, and they must bound rendered
diagnostic count with a stable truncation diagnostic.
Join routes must reload their async outcome when app-owned orchestrator,
invite-context, initial-mode, or enabled-mode dependencies change.
Setup routes and setup flow orchestration reject blank or padded app-owned
setup intent and host identities before wizard/setup dependencies run. Setup
routes also scrub app-owned setup outcome result codes, errors, warnings, and
displayed Game File versions before rendering. Rendered setup errors and
warnings must be bounded with stable truncation markers.
Setup routes must reload their async outcome when app-owned orchestrator,
setup-intent, initial-mode, or enabled-mode dependencies change.

## Network Transport Boundary

`peerdeal_network` exposes transport frame validation plus validating send and
receive contracts. Platform transport adapters should receive outbound frames
only through the validating sender boundary, and inbound frames should reach
session handlers only through the validating receiver boundary. Malformed frames
are rejected before adapter/handler code runs, and adapter/handler failures
become explicit failed transport results.
Transport frame session and peer identities must be exact nonblank strings;
blank or padded identities fail validation before sender/receiver boundaries
call platform sinks or session handlers.

Mobile and desktop `NativeTransportSessionFactory` instances own the app
payload limit used by the default `BasicTransportFrameValidator`. Session
loading fails closed when native capability reports a non-positive
`maxPayloadBytes` or a value above the app validator limit. Direct sender and
drain creation also fail closed before native send/receive calls when the
app-owned payload limit is invalid. Native transport sinks validate outbound
frames before platform send calls, and native transport drains reject invalid
app-owned receive session/peer scope before calling platform receive methods.
The generic native transport method-channel bridge also rejects padded send
frame and receive scope identities before platform calls. Native transport
frames must carry positive sequence numbers; zero or negative sequence values
fail before platform sends and are dropped during receive-snapshot decoding.
Native transport payload lists must contain only byte values from 0 through 255;
invalid outbound payloads fail before platform sends.
Native transport receive frame maps must carry exact field keys; platform maps
whose keys merely stringify to expected field names are dropped.
App-owned native transport drains must cap receive-frame batches before session
handlers see platform frames, and invalid app batch limits must fail closed
before native receive calls.
App-owned native transport session factories must scrub native notes that look
like secrets, tokens, passwords, or platform paths before exposing load results.

## Recovery Persistence Boundary

`peerdeal_sync` owns recovery-window validation and JSON file store contracts.
Recovery persistence scopes must use exact, non-empty protocol, table, and
session identities without padding, control characters, or the internal `::`
storage-key delimiter.
App shells own durable root selection. `AppRecoveryPersistenceStoreFactory`
accepts an injected root directory factory, and the mobile/desktop shells may
default it from `PEERDEAL_RECOVERY_ROOT`. Blank, missing, or throwing roots fail
closed before mounted table routes load recovery windows. App-provided roots
and environment-provided roots must also be unpadded and free of control
characters before a durable JSON store is constructed. Mounted table surfaces
scrub bootstrap and recovery persistence warning text before rendering. The
`RecoveryPersistenceStore.wipe` operation is scope-validated and idempotent;
the JSON implementation removes the target window and matching interrupted
write files while preserving other scopes. Retention policy remains outside
the sync package and decides when to invoke the wipe. Mobile and desktop app
shells expose `AppRecoveryRetentionCoordinator.enforceAfterSessionClose`,
which validates scope, evaluates the injected retention policy engine with
explicit timestamps, and invokes the store wipe only when due. Policy or wipe
exceptions become fatal scrub-safe persistence results. The app-owned
`AppRecoverySessionCloseCoordinator` binds scope and policy to one session,
delegates the first close signal, and returns the cached result for every later
signal, including failures. `AppRecoverySessionCloseEventAdapter` is the app-owned
protocol mapping seam: it ignores non-`SessionClosed` events, requires the
locked catalog version and exact recovery scope, parses `emitted_at`, and only
then delegates to the close coordinator. Invalid event versions, scopes, or
timestamps are rejected before retention or storage work.
`AppTableSessionRuntime` is the app-owned session owner seam: it binds the
initial table/session/protocol identity, delegates ordered `EventEnvelope`
projection to `peerdeal_core.CoreReducer`, and leaves state unchanged when
projection or close retention fails. A `SessionClosed` event is committed only
after the close adapter reports success; live transport/event-source mounting
is still outside this contract.

## Local Network Bootstrap Boundary

`peerdeal_native_bridges` exposes generic local-network capability and discovery
facts only. Mobile and desktop app loaders/coordinators trim, deduplicate, and
cap discovered peer endpoints before passing them to `peerdeal_network`
bootstrap candidate resolution. The package bootstrap candidate provider drops
blank, padded, control-character-bearing, or duplicate peer ids before
assigning route class and priority. Session path selection must ignore
malformed candidate peer ids and malformed elected-primary overrides before
returning path descriptors. Primary-peer election must drop malformed peer
metric identities and ignore malformed current-primary overrides before
scoring, confidence classification, transfer decisions, or fail-closed
fallback decisions. Primary-peer transfer and relay fallback planning must fail
closed on malformed or reserved path peer identities before emitting
actionable plans. Invalid caps fail closed for table loading and
fall back to relay-only join bootstrap plans. Invalid app-owned session/table
bootstrap scope, including padded values, must fail closed or fall back before
native capability lookup.
Discovery `foundEndpoints` and `interfaceHints` lists must contain real
non-empty strings; malformed platform list entries are dropped rather than
coerced into route inputs. Sensitive native peer endpoints must be dropped
before candidate resolution, and sensitive table-bootstrap native notes must be
replaced with stable unavailable text rather than exposed to app surfaces.

## Error Shape

- Protocol failures use `ProtocolDiagnostic`.
- Sync/replay failures expose structured mismatch/conflict codes.
- Receipt import/export/verification failures must fail closed.
- App receipt export factories must not copy provisioning warning detail into
  unavailable artifact reasons.
- App receipt export factories must convert provisioning dependency exceptions
  into stable unavailable artifacts.
- App receipt artifact verifiers must convert key-ring loader dependency
  exceptions into scrubbed rejected inspection results.
- App receipt artifact verifiers must scrub and bound key-ring loader warning
  diagnostics before returning rejected inspection results.
- App receipt artifact verifiers must scrub and bound decoder rejection
  diagnostics before returning inspection results to presenter paths.
- App receipt key-ring loaders must fail closed when native storage exposes
  ambiguous active signing or encryption keys.
- App receipt key-ring loaders must cap native secure-key snapshot records
  before mapping generic records into receipt signing/encryption providers.
- App receipt key-ring loaders must reject oversized or control-character
  native receipt key ids before mapping records into signing/encryption
  providers.
- App receipt key-ring loaders and writers must reject oversized or
  control-character receipt key material before mapping records into
  signing/encryption providers or native save methods.
- App receipt key-ring provisioners must fail closed when app-owned key-id or
  key-material factories throw before native save calls.
- App receipt key-ring loaders and writers must reject malformed app-owned
  receipt key namespaces before calling native storage.
- App receipt key-ring writers must reject oversized or control-character
  receipt key ids before native save/delete methods.
- App receipt key-ring writers must reject blank, padded, or delimiter-bearing
  receipt key ids before calling native delete methods.
- Generic native secure key storage method-channel requests must reject blank
  or padded namespaces, key ids, and key record fields before platform calls.
- The mobile Android host registers
  `peerdeal/native_bridges/secure_key_storage` with `loadKeyRing`, `saveKey`,
  and `deleteKey`. It returns only the generic snapshot/mutation maps defined
  by `SecureKeyStorageChannelContract`; receipt purpose and rotation policy
  stay in app/receipt code.
- Android host records are encrypted with AES-GCM using a namespace-bound
  Android Keystore master key and durably committed before a mutation reports
  success. Corrupt, oversized, unavailable, or malformed records fail closed.
- Android release signing is operator-owned and requires all four
  `PEERDEAL_ANDROID_*` keystore variables; the host never uses debug signing
  for release output.
- The Windows desktop host registers the same generic secure-key channel and
  stores a bounded versioned record envelope in Windows Credential Manager.
  Credential Manager target names are derived from the validated namespace;
  the host returns only the generic snapshot/mutation maps and keeps receipt
  policy in app/receipt code.
- The Android capture host applies `setBlocking` through `FLAG_SECURE`, and the
  Windows capture host applies it through `SetWindowDisplayAffinity` only when
  Windows capture exclusion support is available (Windows 10 build 19041 or
  newer). App capture policy remains in `peerdeal_capture`; host enforcement is
  additive, fail-closed, and still requires runtime/device validation.
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

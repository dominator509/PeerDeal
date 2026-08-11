# PeerDeal Production Readiness

This document defines the release bar for moving PeerDeal from scaffold
baseline toward production-ready engine and app builds.

## Current state
The repository is a green migration baseline. It has package boundaries, local
checks, CI wiring, and starter implementations. It is not production-ready until
the gates below are satisfied.

## Release gates

### Protocol
- Full command, event, snapshot, result-code, Game File, and invite payload
  catalog is versioned in `peerdeal_protocol`.
- Unsupported protocol versions fail safe.
- Canonical serialization and event hashing have fixture coverage.
- Protocol fixtures exist for accepted and rejected payloads.

### Core
- Reducers are deterministic for all accepted command/event paths.
- State projection can be reconstructed from ordered events.
- Invariant guards cover impossible table, participant, hand, and wiped states.
- Core does not contain mode, variant, network, receipt, capture, or UI policy.

### Variants
- Hold'em rules cover legal action validation, street transitions, showdown
  ranking, and settlement inputs.
- Variant-specific behavior stays in `peerdeal_variants`.
- Variant fixtures cover valid play, invalid play, and edge cases.

### Modes
- Open-table and tournament policy are explicit and deterministic.
- Seat, role, waitlist, reload, and ledger-visibility behavior has tests.
- Mode policy does not mutate core truth directly.

### Replay And Sync
- Replay can validate event windows, detect gaps, and fail safely.
- Snapshot recovery never outranks verified events.
- Sync conflict handling has deterministic safe-close and recovery paths.

### Network And Native Bridges
- Network path selection, relay fallback, and primary-peer election are
  deterministic from the same inputs.
- Platform hooks are isolated in `peerdeal_native_bridges`.
- Network packages consume normalized capability facts, not raw platform APIs.

### Privacy, Receipts, Capture
- Retention/minimization policy is explicit and test-covered.
- Receipts can be authorized, scanned, wiped, and rejected safely.
- Capture policy states platform limits honestly and never promises universal
  prevention.

### Apps
- App shells orchestrate flows through package public APIs only.
- UI never owns game truth.
- Join, rejoin, disclosure acknowledgement, and failure paths are covered.

### Operations
- `melos run boundary-check` passes.
- `melos run dependency-audit` passes and dependency changes are reviewed under
  `docs/DEPENDENCY_POLICY.md`.
- `melos run source-text` passes for checked-in source, docs, and fixtures.
- `melos run analyze` passes.
- `melos run test` passes.
- CI runs the same baseline commands as local development.

## Current highest-risk blockers
- Native live transport now has bounded Android and Windows host
  implementations behind the generic byte-frame channel, while capture
  enforcement on other platforms and remaining native hooks remain open.
  Protocol event-byte decoding and app frame-to-runtime ingestion now exist,
  and app-owned bounded source scheduling now exists. Mobile Android and
  Windows desktop now have generic secure-key, capture, app-private
  recovery-storage, and multicast transport hosts. Socket availability does
  not prove device/network reachability, firewall behavior, or production
  endpoint provisioning. The app
  shells prefer explicit `PEERDEAL_RECOVERY_ROOT` and otherwise use native
  app-support storage, but runtime persistence/capture validation, Android
  release signing, real-device/profile validation, production database
  persistence, and other-platform storage remain open.
- App shells now mount demo, receipt, safe-surface, and join-flow routes and
  expose app-owned table-session runtimes over the core event projector. The
  app-owned `AppHoldemTableSessionRoute` now composes a validated Hold'em
  runtime with transport provisioning, source lifecycle, and accepted-event
  surface refresh; its route context also exposes canonical projection
  publishing. Typed `AppHoldemProductionRouteRegistration` now merges that
  route into the validated app route map and native-readiness gate. Platform
  source provisioning, actual product session/state wiring, and device/network
  transport validation remain open. The default app-owned production Hold'em surface now
  renders bounded runtime state, gates local actions on transport readiness, and
  publishes canonical projections; final product UX validation remains open.
- App UI is not production-polished.

## Covered hardening slices
- The workspace and CI now use Melos 8.2.2, and dependency audit reports zero actionable upgrades; newer `meta` and `test` versions remain toolchain-blocked.
- The v1 scaffold protocol catalog is locked across command, event, snapshot,
  Game File, invite payload, and public result-code identities, with accepted
  fixture parity and fail-closed unsupported-version checks.
- Core invariant hardening now covers table identity, non-negative counters,
  participant count coherence, hand-scoped event ordering, active-hand identity,
  close-before-closed ordering, and terminal closed/wiped state projection.
- Core projection coverage now locks every accepted protocol event fixture to a
  replay-safe reducer path, so fixture additions cannot bypass core tests.
- Core command validation now rejects whitespace-only command identity,
  protocol/version, issue timestamp, actor, and Open Table table identity
  fields before accepted command paths can reach reducer orchestration.
- Core command validation now consults the protocol catalog and rejects
  unsupported command artifacts or protocol versions, plus padded or
  control-character command and scope identities.
- The core public API no longer exposes the unused starter local command/event
  models or duplicate reducer and validator seams; protocol-native envelopes
  are now the sole command/event boundary in `peerdeal_core`.
- Core reducer ingress now rejects whitespace-only event envelope identity,
  scope, timestamp, actor, and hash-chain fields before protocol-compatible
  events can mutate deterministic state.
- Replay full-window validation now uses the protocol-owned genesis hash marker
  and rejects windows that do not start at `event_seq` 1 or whose first event
  does not chain from genesis.
- Replay request validation now fails closed on non-positive or inverted event
  range bounds before filtering events or invoking reconstruction projectors.
- Sync recovery conflict detection, snapshot apply, and recovery persistence
  now enforce the protocol-owned genesis hash for no-snapshot event windows and
  first persisted events.
- Canonical Hold'em settlement breadcrumb coverage now spans protocol fixtures,
  core metadata projection, replay through the core projector, and sync
  snapshot + suffix recovery.
- Hold'em variant coverage now spans betting-round completion through checked
  streets, showdown reveal, settlement preparation/projection, uncontested
  settlement, hand completion, and settlement event emission.
- The variant-owned `HoldemCoreProjectionAdapter` now connects accepted
  Hold'em action, showdown, and settlement coordinator output to
  catalog-approved protocol events and transactional `peerdeal_core` reducer
  projection; core remains variant-agnostic and failed batches roll back.
- Mirrored app-owned `AppHoldemTableSessionRuntime` owners now invoke that
  adapter from app/session code and commit local non-retention event batches
  atomically through `AppTableSessionRuntime` before advancing Hold'em state or
  its event cursor. `HoldemEventCursor.accept` and the variant-owned
  `HoldemEventReducer` now validate and reconstruct canonical remote action,
  street, public showdown, and settlement events. Both app runtimes can apply
  those events atomically, and transport handlers/provisioners can opt into the
  variant path. Private showdown cards are intentionally not reconstructed from
  public events.
- Mirrored `AppHoldemTableSessionRoute` owners now provision the validated
  transport/source seam, refresh the supplied surface after accepted inbound
  events, and expose `AppHoldemProjectionTransportPublisher` for canonical
  outbound event frames. Publisher partial sends are reported for retry without
  rerunning variant rules.
- Mirrored `AppHoldemProductionRouteRegistration` owners now provide the typed
  app-shell registration boundary. The shells auto-merge its route and
  navigation metadata, require native readiness, and render the existing
  scrubbed route-unavailable surface when readiness is absent.
- Mirrored `AppHoldemProductionTableSurface` owners now render bounded runtime
  state and expose only local-seat betting controls backed by a live canonical
  publisher. Partial projection sends retain an event offset and resume from
  the first unsent event without replaying variant rules or delivered frames.
- Hold'em action application now carries production raise sizing semantics:
  full opening bets and full raises update the next minimum raise amount, while
  short all-ins can increase the amount to call without claiming full-raise
  reopen or last-aggressor semantics.
- Hold'em showdown evaluation now fails closed when fewer than two active
  non-folded seats are present, keeping single-winner hands on the uncontested
  settlement path instead of allowing accidental showdown settlement.
- Hold'em blind posting now has a variant-local deterministic coordinator that
  validates blind phase, amounts, seat eligibility, and duplicate commitments
  before posting blinds, including short all-in blinds, and then advances to
  hole-card dealing without leaking session policy into variants.
- Wizard setup validation now rejects unsupported variant ids before Game File
  compilation, so launch setup cannot produce build-ready files for variants
  outside the currently implemented Hold'em boundary.
- Wizard setup resolution now trims setup intent ids and rejects blank setup
  intent or host identities before Game File compilation, so direct wizard
  callers cannot emit build-ready plans with malformed setup identity.
- Wizard Game File compilation now rechecks build-ready mode, variant ids, and
  non-empty plan identity, so manually constructed setup plans cannot bypass
  resolver validation and emit unsupported or malformed production Game Files.
- Mode governance now locks deterministic waitlist promotion ordering and
  rejects promotion when mode policy, manager permission, or waitlist head
  state does not allow it.
- Mode governance now returns explicit co-host role transitions and rejects
  unauthorized grants or invalid revocations.
- Mode governance now hardens seat assignment and offer expiry with explicit
  manager authority checks and deterministic next seat/participant states.
- Mode adapters now lock reload and ledger visibility policy for Open Table and
  Tournament modes, rejecting unsupported reload policy strings.
- Network/sync/receipt/capture/native hardening now covers deterministic route
  class semantics, event-lag confidence gating, fail-closed primary election,
  fail-closed empty or suffix-only recovery windows, optional signed/encrypted
  opaque receipt exports, minimized receipt export metadata, capture-warning
  propagation, native bridge failure normalization, and locked method-channel
  contracts for future platform implementations.
- The mobile Android host now registers the locked generic secure-key channel,
  encrypts namespace-bound records with an Android Keystore AES-GCM key, and
  durably commits validated mutations without adding receipt semantics to the
  native bridge package.
- Android secure-key persistence now bounds the actual UTF-8 encoded envelope
  bytes on both reads and writes; the write path no longer mistakes the JSON
  field count for the persisted envelope size.
- The release Android manifest now declares the minimum `INTERNET` permission
  for the existing native-network boundary. This does not claim local-network
  discovery or live peer transport implementation.
- The mobile Android release build now fails closed before artifact assembly
  unless all four operator-owned `PEERDEAL_ANDROID_*` signing values are
  supplied together. It rejects padded/control-bearing values and invalid
  keystore paths, never falls back to debug signing, and does not silently
  produce an unsigned release artifact.
- The Windows desktop host now registers the generic secure-key channel and
  persists bounded versioned records through Windows Credential Manager without
  adding receipt semantics to the native bridge.
- A generic app-support directory channel now lets app shells select durable
  recovery storage without moving recovery policy into native bridges. Android
  returns private no-backup app storage and Windows returns `LocalAppData`;
  explicit `PEERDEAL_RECOVERY_ROOT` configuration remains the higher-priority
  override and all unavailable or malformed results fail closed.
- Android and Windows hosts now implement the generic capture action contract;
  Android toggles `FLAG_SECURE`, Windows uses `SetWindowDisplayAffinity` on
  Windows 10 build 19041 or newer, and receipt route disposal releases
  blocking. Unsupported, failed, or unconfirmed native actions downgrade to
  app-owned visual obscuring with a scrubbed warning.
- The Windows secure-key host now rejects malformed Credential Manager pointer
  and blob combinations and avoids constructing ranges from null zero-length
  blobs before the bounded envelope decoder applies schema validation.
- App-owned capture surface coordinators now scrub sensitive native capture
  notes before UI projection, replacing token, secret, password, or platform
  path-like notes with stable unavailable text.
- Shared safe-surface render models now scrub and bound injected capture
  warning and native-note text before app UI can inspect render state.
- Network transport contracts now include a package-owned frame validation gate
  that fails closed on malformed session/peer identities, self-send frames,
  invalid sequence numbers, empty payloads, and oversized payloads before
  platform transport adapters send data.
- Network transport frame validation now rejects padded session and peer
  identities before validating sender/receiver boundaries can pass frames to
  platform sinks or session handlers.
- Network bootstrap candidate resolution now drops blank, padded,
  control-character-bearing, or duplicate peer ids before assigning candidate
  route class and priority, keeping malformed discovery identities out of path
  selection.
- Network session path selection now ignores malformed reachable candidate
  peer ids and malformed elected-primary overrides before returning path
  descriptors, falling back to valid candidates or unresolved state.
- Network primary-peer election now drops malformed peer metric identities and
  ignores malformed current-primary overrides before scoring, confidence
  classification, transfer decisions, or fail-closed fallback decisions.
- Network primary-peer transfer and relay fallback planning now fail closed on
  malformed or reserved path peer identities before emitting actionable
  transfer or transition plans.
- Network transport send contracts now include a validating sender boundary
  that rejects invalid frames before platform sinks see them and converts sink
  failures into explicit failed send results.
- Network transport receive contracts now include a validating receiver
  boundary that rejects invalid frames before session handlers see them and
  converts handler failures into explicit failed receive results.
- Native bridge contracts now include a generic transport method-channel seam
  for capability lookup, byte-frame sends, and inbound frame snapshots, failing
  closed on invalid requests, platform failures, or malformed payloads without
  putting routing policy in the native bridge package.
- Native transport method-channel wrappers now reject padded frame and receive
  scope identities before platform send/receive calls, keeping ambiguous
  generic transport requests out of native code.
- Native transport method-channel wrappers now also reject zero or negative
  frame sequence numbers on platform-bound sends and decoded receive snapshots,
  aligning the generic native byte-frame seam with the public network transport
  sequence contract.
- Native transport method-channel wrappers now reject platform-bound frames
  whose payload list contains values outside the byte range, matching the
  receive decoder's fail-closed byte payload gate.
- Native transport receive decoding now requires exact frame map field keys and
  drops frames whose platform keys only stringify to expected field names.
- Android native transport method calls now resolve with bounded fail-closed
  payloads when teardown closes or rejects the executor, and accepted work is
  allowed to drain during handler shutdown.
- Android native transport receiver setup now publishes socket and multicast
  resources atomically with teardown, releases partial setup resources on
  failure, and clears queued frames during close so teardown cannot leak a
  newly-created receiver or retain transport payloads.
- Generic native transport method-channel capability, send, and receive calls
  now use a bounded five-second default deadline and return stable fail-closed
  timeout results instead of leaving app transport operations indefinitely
  pending.
- App-owned production table routes now cancel in-flight default native
  transport calls during route replacement or disposal, preventing lifecycle
  teardown from retaining transport deadline timers.
- Windows native transport initialization now cleans up socket, multicast
  membership, TTL, and Winsock state on every partial setup failure before the
  host can report transport availability.
- Windows native transport now serializes socket-handle access across Flutter
  method calls, the receive thread, and teardown; shutdown invalidates the
  handle before closing and joining, then clears queued frames.
- App shells now include app-owned native transport adapters that compose the
  generic native byte-frame bridge with `peerdeal_network` validating
  sender/receiver boundaries, so app transport sends and inbound drains cannot
  bypass network frame validation.
- App shells now include native transport session factories that default to
  `MethodChannelNativeTransportBridge` and only expose validated
  `peerdeal_network` sender/drain construction to app orchestration.
- App native transport session/drain adapters now scrub native capability and
  receive warnings plus bound native notes before exposing app transport load
  results, preserving validated send/receive behavior without leaking platform
  diagnostic detail.
- App native transport session factories now also scrub sensitive native notes
  before exposing app transport load results, replacing token, secret,
  password, or platform path-like notes with stable unavailable text.
- Native transport session factories now fail closed during session loading
  unless native capability reports send and receive support, so app
  orchestration can reject unavailable platform transport before exposing
  validated send/drain handles.
- Native transport session factories now enforce app-owned payload limits
  against native capability claims, rejecting invalid or oversized native
  payload limits before exposing validated send/drain handles.
- Native transport session factories now fail closed before native capability
  lookup when the app-owned payload limit is invalid, keeping bad app
  configuration from reaching platform transport.
- Native transport session factories now also fail closed before native send or
  receive calls when direct sender/drain creation uses an invalid app-owned
  payload limit, keeping all app transport entry points aligned.
- App-owned native transport sinks now validate outbound frames before native
  send calls even when constructed directly, keeping malformed app frames from
  reaching platform transport outside the factory sender path.
- App-owned native transport drains now reject blank or padded receive
  session/peer scope before native receive calls, keeping malformed app route
  scope from reaching platform transport.
- App-owned native transport drains now enforce a receive-frame batch limit
  before session handlers see platform frames, and invalid app batch limits
  fail closed before native receive calls.
- `peerdeal_protocol` now exposes a bounded canonical `EventEnvelopeCodec` for
  transport payload bytes. Mirrored app `AppTableSessionTransportHandler`s use
  that codec behind network receiver validation, require frame/event session
  identity agreement, and reject events that the app session runtime cannot
  commit.
- Mirrored app-owned `AppTableSessionTransportSource` controllers now compose
  loaded native transport sessions with exact session/peer scope, a bounded
  polling interval, serialized in-flight polls, explicit lifecycle state, and
  scrubbed warning output. Mirrored
  `AppTableSessionTransportProvisioner` factories compose the runtime handler,
  native session factory, and route-ready source behind one fail-closed app
  boundary, including invalid-peer and unavailable-native handling.
- Mirrored app shells now expose optional source injection through the runtime
  and table route, and `AppTableSessionTransportSourceMount` owns start,
  replacement, and disposal. A real platform peer transport and platform source
  provisioning are still required before this boundary can drive production.
- Mounted app table routes now load native local-network bootstrap snapshots
  through an app-owned factory, map normalized discovery facts into
  `peerdeal_network` bootstrap candidate resolution, and fail closed when
  native capability, discovery, factory construction, or candidate resolution
  is unavailable.
- Generic local-network capability and discovery method-channel calls now have
  a bounded five-second default deadline with stable fail-closed timeout and
  cancellation results. Default app bootstrap loaders cancel in-flight native
  calls when table routes are replaced or disposed. Real platform discovery,
  permission behavior, reachability, and other-platform implementations remain
  external validation and implementation work.
- Generic capture capability and blocking method-channel calls now have a
  bounded five-second default deadline with stable fail-closed timeout results;
  non-positive timeout configuration is rejected before platform calls. Runtime
  device behavior, capture enforcement, and other-platform implementations
  remain external validation and implementation work.
- Mounted join-flow factories now use an app-owned native bootstrap coordinator
  instead of hard-coded fake peer candidates, mapping normalized local-network
  discovery into join `BootstrapPlan` inputs while preserving relay fallback
  when local discovery is unavailable.
- App-owned join bootstrap coordinators now fall back before native capability
  lookup when the app-owned peer candidate limit is invalid, keeping bad join
  bootstrap configuration from reaching local-network platform discovery.
- App-owned join bootstrap coordinators now preserve relay fallback when
  app/network candidate resolution fails after native discovery, aligning join
  bootstrap with mounted table bootstrap fail-closed behavior.
- App-owned local-network bootstrap loaders and join coordinators now bound
  normalized native peer discovery before candidate resolution, warning or
  falling back safely when platform discovery is invalid or exceeds the app
  candidate limit.
- App-owned local-network bootstrap loaders and join coordinators now drop
  sensitive native peer endpoints before candidate resolution, and table
  bootstrap loaders replace sensitive local-network notes with stable
  unavailable text.
- App-owned local-network bootstrap loaders now fail closed before native
  capability lookup when the app-owned peer candidate limit is invalid, keeping
  bad app configuration from reaching local-network platform discovery.
- App-owned local-network bootstrap loaders and join coordinators now validate
  app-owned session/table bootstrap scope before native capability lookup,
  keeping malformed route or invite scope from reaching platform discovery.
- App-owned local-network bootstrap loaders and join coordinators now reject
  padded session/table bootstrap scope before native capability lookup, keeping
  ambiguous route or invite scope from reaching platform discovery.
- App-owned local-network bootstrap loaders now scrub native capability and
  discovery warnings, bound native notes/interface hints, and normalize
  native-discovered endpoint ids before mounted table and join bootstrap paths
  pass candidates into `peerdeal_network`.
- Mirrored app-owned local-network bootstrap loaders now preserve the documented
  `peer@host[:port]` discovery shape as validated `BootstrapCandidate` host and
  port metadata, while keeping bare peer IDs compatible and dropping malformed
  or sensitive endpoint locations before network routing.
- Generic local-network discovery payload decoding now drops malformed endpoint
  and interface-hint list entries instead of coercing arbitrary platform values
  into strings.
- App safe-surface capture coordinators now scrub native warning detail and
  bound native notes before projecting capture plans into UI render models,
  preserving fail-closed obscuring without exposing platform exception text.
- Receipt signing now includes an HMAC-SHA256 adapter with explicit active and
  rotated key lookup, deterministic verification, export-service coverage, and
  fail-closed signed artifact inspection.
- Receipt encryption now includes an HMAC-SHA256 authenticated cipher adapter
  with active and retained key lookup, deterministic test seams, and
  fail-closed tamper rejection.
- Receipt key-ring lookup now covers loaded signing and encryption key material
  behind receipt-owned provider contracts, keeping app shells out of key
  rotation interpretation.
- Native bridge contracts now include a secure key storage method-channel seam
  for normalized key-ring snapshots, without putting receipt semantics in the
  native bridge package.
- Native secure key storage contracts now lock generic save/delete mutation
  methods and fail-closed mutation results without adding receipt semantics to
  the native bridge package.
- Native secure key storage method-channel wrappers now reject blank or padded
  namespaces, key ids, and key record fields before platform load/save/delete
  calls, keeping malformed generic secure-storage requests out of native code.
- Generic secure-key method-channel load, save, and delete calls now use a
  bounded five-second default deadline and return stable fail-closed timeout
  results instead of leaving receipt key flows indefinitely pending.
- The Android secure-key host now rejects queued storage work after engine
  teardown begins and suppresses late key-ring results on the main looper,
  preventing closed Flutter engines from receiving native key material.
- Windows secure-key and capture method-channel hosts now unregister their
  handlers during destruction, matching the existing native channel teardown
  contract and preventing shutdown callbacks from targeting released hosts.
- Mirrored receipt routes reject unavailable export artifacts before invoking
  native key verification, preventing failed export factories from opening an
  unnecessary secure-storage call.
- App demo receipt paths now map native secure key storage snapshots into
  receipt-owned key-ring providers before signed artifact verification.
- App demo receipt presenters can consume a verifier boundary that loads native
  key material and fails closed before projecting receipt UI.
- App receipt artifact verifiers now convert key-ring loader dependency
  exceptions into scrubbed rejected inspection results before presenter
  projection.
- App receipt artifact verifiers now scrub and bound key-ring loader warning
  diagnostics before returning rejected inspection results.
- App receipt artifact verifiers now scrub and bound decoder rejection
  diagnostics before returning inspection results to presenter paths.
- The safe-surface widget/model contract is shared through `peerdeal_ui_kit`;
  app packages own only capture coordination, receipt/recovery projection, and
  route orchestration.
- Shared app-shell UI primitives now cover a reusable scaffold, action button,
  status pill, and info row in `peerdeal_ui_kit`, and mounted home, table,
  chat, receipt, join, setup, and unknown-route surfaces in both app shells use
  them instead of raw placeholder columns.
- App shells now expose app-owned route registries with stable mounted route
  descriptors and primary-navigation definitions, and home navigation is driven
  from those descriptors instead of scattered route labels.
- App route registries now validate canonical mounted route metadata before
  route maps are exposed, rejecting non-demo paths, query/fragment-bearing
  paths, empty labels/surfaces, duplicate metadata, or primary navigation that
  references home/unmounted routes.
- App shell mounted route maps now validate against the app-owned route
  registries at construction time, allowing only the explicit framework default
  route alias so mounted navigation cannot silently drift from the registry.
- Demo receipt presenters in both app shells can route signed receipt export
  artifacts through fail-closed verification before projecting safe receipt
  fields.
- Mounted app receipt routes receive artifact verifier factories from the app
  shell boundary, keeping method-channel construction out of receipt screens.
- Mounted app receipt routes now reject conflicting receipt export sources
  before using either a prebuilt artifact or an export factory, preventing
  production injection drift from silently choosing one receipt path.
- App shells now preserve conflicting prebuilt receipt artifacts and export
  factories when constructing mounted receipt routes, so the route-level
  fail-closed source-conflict gate cannot be bypassed by runtime dependency
  merging.
- Mounted app receipt routes now reject direct receipt inputs when no export
  factory is available, and app shells no longer pass default demo receipt
  envelopes unless export or injected receipt orchestration needs them.
- App artifact verifiers now use native-loaded signing and encryption keys for
  signed/encrypted receipt export inspection, failing closed when encryption
  material is unavailable.
- Mounted app receipt routes now pass recovery scenarios through the safe
  recovery projection path, including restore-surface capture coordination.
- Mounted app table routes now classify fixture-derived peer metrics through
  `peerdeal_network` before rendering network confidence.
- Native bridge contract decoders now tolerate malformed platform payload
  fields and normalize them to fail-closed facts before app policy sees them.
- Native bridge method-channel wrappers now fail closed on malformed top-level
  platform payloads instead of letting decode errors escape app policy.
- App join-flow orchestrators now convert invite, negotiation, disclosure,
  role, bootstrap, and governance adapter exceptions into explicit rejected
  outcomes with scrubbed diagnostics.
- Mounted app demo routes now use a non-throwing scenario snapshot lookup seam
  so catalog drift falls back to a known snapshot instead of crashing routes.
- App demo scenario selection now ignores unknown ids without throwing, keeping
  mounted navigation on the current scenario when selection input drifts.
- Mounted app receipt routes now fail closed when artifact verifier
  construction fails, falling back to the rejected verifier-unavailable surface.
- Receipt routes now fail closed to an obscured rejected surface when async
  receipt presentation fails.
- Mounted join routes now fail closed to a rejected outcome when route-level
  orchestrator setup fails before adapter guards can run.
- Join orchestration now treats event-sink failures as non-decision side-effect
  failures, preserving join/rejection outcomes instead of throwing.
- Mounted join routes now receive orchestrator factories from the app shell
  boundary instead of constructing demo adapters inside the route, with
  fail-closed coverage when factory setup is unavailable.
- Mounted join routes now reload their async outcome when app-owned
  orchestrator, invite-context, initial-mode, or enabled-mode dependencies
  change, preventing stale production invite/join decisions after runtime
  updates.
- Mounted join routes now also receive app-owned invite-context factories, so
  production invite sources can feed first-join and rejoin orchestration through
  the app shell boundary instead of leaving hardcoded invite/rejoin tokens
  inside the route; the route fails closed when invite context construction is
  unavailable.
- Mounted join routes now validate app-owned invite contexts before deeper
  orchestration, rejecting blank invite codes and whitespace-only rejoin tokens
  before adapter calls can observe malformed production invite input.
- Mounted join routes now also reject padded invite codes and rejoin tokens
  before constructing join orchestrator dependencies, aligning route-level
  production input gates with direct join-flow validation.
- App join-flow orchestrators now reject blank or padded invite codes and
  rejoin tokens before invite resolution or governance commit adapters run, so
  direct app orchestration cannot bypass route-level invite guards.
- Wizard Game File compilation now exposes a fail-closed `tryCompile` boundary
  so app/session setup flows can reject invalid setup plans without compiler
  exceptions escaping orchestration.
- App setup-flow orchestrators now resolve setup intent through
  `peerdeal_wizard`, validate drafts, and compile Game Files through
  `tryCompile`, returning explicit compiled/rejected outcomes before UI routes
  can consume setup results.
- Mounted app setup routes now receive app-owned setup orchestrator factories,
  expose compiled/rejected setup outcomes through navigation, and fail closed
  when route-level setup orchestration is unavailable.
- Mounted setup routes now reload their async outcome when app-owned
  orchestrator, setup-intent, initial-mode, or enabled-mode dependencies change,
  preventing stale production setup decisions after runtime updates.
- Mounted app setup routes now also receive app-owned setup intent factories,
  so production setup sources can feed `peerdeal_wizard` through the app shell
  boundary instead of leaving hardcoded demo setup intent inside the route; the
  route fails closed when intent construction is unavailable.
- Mounted app setup routes now reject blank or padded injected setup intent
  identities before constructing setup orchestrator dependencies, aligning the
  route boundary with direct setup-flow validation.
- App setup-flow orchestrators now reject blank setup intent and host
  pseudonymous identities before wizard resolution, so malformed production
  setup sources cannot emit blank plan ids or reach compiler dependencies.
- App setup-flow orchestrators now reject padded setup intent and host
  pseudonymous identities before wizard resolution, so ambiguous production
  setup IDs cannot reach compiler dependencies.
- App shell runtime dependency injection now has mounted-route coverage for
  blank setup identities, locking the production runtime object path to the
  same fail-closed setup intent gate as direct route injection.
- App shells now fail closed for unknown route names with an explicit rejected
  route-unavailable surface instead of relying on default framework route
  errors.
- App route-unavailable surfaces now scrub unknown route diagnostics before UI
  rendering, dropping query/fragment detail and bounding displayed paths while
  preserving explicit rejected navigation outcomes.
- App receipt key-ring loaders now fail closed to an empty key ring when native
  secure key storage throws.
- App receipt key-ring loaders, writers, and provisioners now scrub native
  secure-key storage warning detail before returning app receipt key-ring
  warnings, while preserving app-generated invalid-request warnings.
- App receipt key-ring loaders now fail closed when native storage reports
  multiple active signing or encryption keys, preventing ambiguous platform
  key rotation state from selecting an arbitrary active receipt key.
- App receipt key-ring loaders now enforce an app-owned native key-record
  snapshot limit, failing closed before receipt key mapping when platform
  secure storage returns an oversized key set.
- App receipt key-ring loaders now bound native receipt key-id metadata and
  reject control characters before mapping platform records into signing or
  encryption providers.
- App receipt key-ring loaders and writers now bound receipt key material and
  reject control characters before native records enter signer/cipher providers
  or native save calls.
- App receipt key-ring loaders and writers now fail closed before native
  storage calls when the app-owned receipt key namespace is blank or padded,
  preventing malformed key-ring configuration from reaching platform storage.
- App receipt key-ring writers now bound receipt key-id length and reject
  control characters before native save/delete calls, preventing unsafe
  app-owned key mutation identifiers from reaching platform storage.
- App receipt key-ring writers now reject blank, padded, or delimiter-bearing
  receipt key ids before native delete calls, preventing ambiguous app-owned
  key deletion requests from reaching platform storage.
- App receipt key-ring writers now map receipt signing/encryption keys into
  generic native secure-key mutation records, fail closed before invalid
  save/delete requests, and keep receipt semantics out of
  `peerdeal_native_bridges`.
- App receipt key-ring provisioners now load native-backed receipt key rings,
  create missing active signing/encryption keys with secure random material,
  persist them through the app-owned writer boundary, and fail closed when
  native storage is unavailable or mutation fails.
- App receipt key-ring provisioners now fail closed when app-owned receipt
  key-id or key-material factories throw, preventing provisioning dependency
  failures from escaping app export paths.
- App receipt export artifact factories now provision native-backed receipt
  keys before signed/encrypted export, build signer/cipher adapters from the
  provisioned key ring, and fail closed when key provisioning is unavailable.
- App receipt export artifact factories now collapse key-provisioning warning
  detail into a stable unavailable artifact reason, preventing native or
  provisioning diagnostics from entering export metadata.
- App receipt export artifact factories now convert key-provisioning dependency
  exceptions into the same stable unavailable artifact reason, preventing
  provisioning faults from escaping export paths.
- Mounted app receipt routes can now receive app-owned receipt export artifact
  factories, generate signed/encrypted artifacts from deterministic route
  receipt inputs, and verify them through the same native-backed key boundary.
- Mounted app receipt routes now receive app-owned receipt factories before
  export, so production receipt sources can supply `PeerDealReceipt` envelopes
  through the app shell boundary instead of relying on hardcoded demo user
  identity; export fails closed when receipt construction is unavailable.
- Receipt export now fails closed to an unavailable artifact when signing or
  encryption adapters throw.
- Receipt import inspection now rejects signed artifacts when verifier adapters
  throw during signature verification.
- Opaque receipt export encoding now fails closed for direct callers when signer
  or cipher adapters throw.
- Receipt HMAC signature verification now fails closed when verification key
  lookup throws.
- Replay now rejects event and snapshot table/session scope mismatches against
  the replay request before projection, preventing reconstruction from merging
  another table/session stream into verified state.
- Replay now converts projector base-state or event-application failures into
  explicit failed replay results, preserving fail-closed reconstruction
  behavior when a projector dependency faults.
- Sync recovery now converts conflict-detector, snapshot-applier, and
  projector exceptions into fatal safe-close conflicts instead of allowing
  recovery dependency failures to escape.
- Sync recovery persistence now has a package-owned store contract and
  in-memory validation gate that rejects mismatched table/session scope,
  protocol drift, sequence gaps, hash-chain breaks, and snapshots ahead of the
  stored event stream before mutating recovery windows.
- Sync recovery persistence now rejects blank, padded, control-character, or
  delimiter-bearing recovery scope identities before mutating in-memory windows
  or resolving durable JSON file paths.
- Sync recovery persistence now rejects snapshot checkpoint regression and
  same-sequence snapshot hash replacement, preserving newer verified recovery
  anchors from stale or tampered snapshot writes.
- Sync recovery persistence now includes a JSON file-backed store that
  round-trips protocol event/snapshot envelopes through public JSON parsers,
  rehydrates through the same validation gate before writes, and fails closed
  on corrupt persisted files instead of resuming unsafe recovery windows.
- Sync recovery file persistence now writes canonical protocol JSON through a
  temporary file before replacing the durable recovery window, locking stable
  on-disk bytes for diagnostics and reducing direct-write corruption risk.
- Sync recovery file persistence now serializes each scope's hydrate-modify-write
  transaction, read, and wipe through an operating-system file lock. The lock
  handle is closed on every path so process termination releases it, and lock
  failures fail closed without changing the public recovery-store contract.
- Sync recovery persistence now exposes an idempotent, scope-validated wipe
  operation; the JSON store removes the durable recovery window and matching
  interrupted-write temporary files without removing other scopes. Retention
  policy remains app-owned and controls when the operation is invoked.
- Mobile and desktop app shells now expose deterministic retention coordinators
  that validate recovery scope, evaluate policy with explicit close/current
  timestamps, invoke wipe only when due, and normalize policy/storage
  exceptions to fatal persistence outcomes. Per-session app close coordinators
  cache the first success or failure, preventing duplicate close signals from
  repeating policy or storage work. App-owned session-close event adapters now
  reject unsupported versions, mismatched recovery scopes, and invalid
  timestamps before mapping supported `SessionClosed.emitted_at` into that
  coordinator. Mirrored app table-session runtimes now bind the event stream
  to one table/session/protocol scope, delegate projection to `peerdeal_core`,
  and refuse to commit a close when retention fails. Canonical event-byte
  decoding, frame-to-runtime handlers, bounded app source scheduling, and
  route lifecycle source mounting are available, while native transport
  provisioning and durable database persistence remain integration work. The
  Android and Windows app shells now also select app-private recovery roots
  through the generic native app-support directory contract.
- App shells now expose app-owned recovery persistence store factories that
  construct durable JSON recovery stores only when the platform/app layer
  supplies a usable root directory and fail closed when that root is
  unavailable.
- App shells can now build their default recovery persistence store factory
  from the `PEERDEAL_RECOVERY_ROOT` environment variable, preserving explicit
  constructor injection while giving deployed shells a durable root
  configuration path without adding package-level platform policy.
- App recovery persistence store factories now preserve
  `PEERDEAL_RECOVERY_ROOT` exactly and fail closed when environment-provided
  recovery roots are padded, preventing ambiguous durable JSON store roots from
  being accepted through deployment configuration.
- App recovery persistence store factories now fail closed when app-provided or
  environment-provided recovery roots contain control characters, preventing
  malformed root configuration from constructing durable JSON stores.
- App recovery persistence store factories now also fail closed when
  app-provided recovery roots are padded with leading or trailing whitespace,
  preventing ambiguous durable JSON store roots from being constructed.
- Mounted app table routes now consume the app-owned recovery persistence
  factory when one is supplied, load the active scenario recovery window, and
  fail closed with an explicit warning when no platform persistence root is
  available.
- Mounted table surfaces now scrub app-owned bootstrap and recovery
  persistence warning text before rendering, replacing malformed display
  warnings with stable generic warning text.
- Mounted table routes now scrub and bound injected bootstrap and recovery
  persistence warnings before passing load results into table surfaces.
- Mounted table routes now cap injected bootstrap candidate lists before
  passing load results into table surfaces.
- Mounted table routes now cap displayed recovery persistence event counts and
  warn when injected recovery windows exceed the app display boundary.
- Mounted app table routes now receive app-owned runtime scope factories for
  bootstrap and recovery persistence lookup, so production table/session scope
  can enter from the app shell boundary instead of relying on hardcoded demo
  session ids; table routes fail closed when runtime scope construction is
  unavailable.
- Mounted app table routes now reload bootstrap and recovery persistence
  futures when the app-owned runtime scope factory changes, preventing stale
  production table/session scope from surviving runtime dependency updates.
- Mobile and desktop app shells now expose app-owned runtime dependency
  objects that group mounted-route factories for receipts, join/setup
  orchestration, bootstrap loading, and recovery scope/persistence. Existing
  per-factory constructor injection remains available, but production callers
  can now replace route orchestration dependencies as a stable app-shell unit.
- App runtime dependency objects now merge non-null constructor-level
  dependency overrides instead of silently ignoring them, preventing production
  route injection drift when callers compose the stable runtime object with
  focused app-shell overrides.
- Mounted join and setup routes now accept app-owned enabled-mode gates through
  the mobile and desktop runtime objects, so production callers can hide demo
  branches and fail closed when disabled route modes are requested.
- Mounted join routes now scrub app-owned join outcome result codes and
  diagnostics before rendering, replacing malformed diagnostic metadata with
  generic safe text and rejecting unsafe result codes.
- Mounted join routes now bound app-owned join diagnostics before rendering,
  appending a stable truncation diagnostic when injected outcomes exceed the
  app display limit.
- Mounted setup routes now scrub app-owned setup outcome result codes, errors,
  warnings, and displayed Game File versions before rendering, replacing
  malformed metadata with generic safe codes and rejecting unsafe result codes.
- Mounted setup routes now bound app-owned setup errors and warnings before
  rendering, appending stable truncation markers when injected outcomes exceed
  the app display limit.
- Mounted receipt surfaces now scrub receipt/recovery status, message,
  shareable field, recommended-action, and diagnostic text before rendering,
  preserving already-redacted values while replacing malformed display
  metadata with stable generic text.
- Mounted receipt surfaces now bound rendered shareable fields and recovery
  diagnostics before UI projection, appending stable truncation lines when
  injected presenter output exceeds the app display limit.
- Mounted demo routes now accept app-owned enabled-route gates through the
  mobile and desktop runtime objects, so production callers can expose only
  explicitly allowed dev/demo paths while disabled route requests fall through
  the scrubbed route-unavailable surface.
- Mounted demo route allowlists now reject blank or padded enabled-route paths
  before route matching, preventing ambiguous production route gates from
  silently enabling demo surfaces.
- Mounted demo route allowlists now also enforce bounded canonical `/demo`
  paths, reject control, query, fragment, duplicate-slash, and backslash
  metadata, and avoid echoing unknown supplied paths in failure messages.
- Mounted demo route-map drift validation now fails with stable generic
  diagnostics instead of echoing missing or unexpected route keys.
- Mounted demo route registry validation now bounds route labels and surface
  metadata and rejects control characters before route definitions feed
  navigation or mounted route maps.
- Mounted demo route-map validation now also validates caller-provided allowed
  extra route paths, allowing only `/` or bounded non-demo production-style
  paths without unsafe routing metadata.
- Mounted demo route allowlists and route-map allowed-extra path sets now
  enforce collection-size caps before path validation, preventing oversized
  route extension inputs from overwhelming app-shell route validation.
- App shells now accept validated app-owned production route maps through the
  mobile and desktop runtime objects, reserving `/demo/*` for the demo registry
  while allowing non-demo flows to mount without editing shared package or demo
  route policy.
- App shells now reject unsafe control or whitespace characters in production
  route paths, production navigation labels, and startup routes before route
  maps are mounted.
- App shells now reject production navigation entries whose labels or paths
  collide with enabled demo home navigation before the home surface is built,
  keeping composed app home actions unambiguous.
- App shells now accept a validated app-owned initial route through the mobile
  and desktop runtime objects, so production callers can boot directly into a
  mounted non-demo route while disabled or malformed startup routes fail closed
  before app construction reaches `WidgetsApp`.
- App shells now accept validated app-owned production navigation descriptors
  through the mobile and desktop runtime objects, so shell home navigation can
  link to mounted non-demo routes without extending the demo route registry.
- App shells now accept app-owned home surface builders through the mobile and
  desktop runtime objects, so production callers can replace the demo home
  surface while still receiving validated home navigation entries. Builder
  failures fail closed to the scrubbed route-unavailable surface.
- App-owned production route builders now fail closed to the scrubbed
  route-unavailable surface when builder execution throws, preventing mounted
  non-demo route failures from escaping app-shell routing.
- App-owned production route paths, production navigation labels, and startup
  routes now enforce bounded display/routing metadata and reject backslash
  separators, preventing path-like or oversized production navigation
  descriptors from entering mounted app-shell routing.
- App-owned production route paths and demo route-map allowed extra paths now
  reserve the `/demo` namespace case-insensitively, preventing production
  extensions from mounting paths that case-collide with demo routes.
- Demo route-map allowed extra paths now reject case-insensitive duplicate
  production extension paths before mounted route maps are accepted.
- App-owned production route maps and production home navigation descriptors
  now enforce explicit collection-size caps before app route maps or home
  navigation are built, preventing oversized production extension injection
  from overwhelming mounted shell routing.
- Unknown route fallback surfaces now suppress sensitive route diagnostics
  instead of echoing token, secret, password, or platform path-like route names.
- App-owned production route maps and production home navigation descriptors
  now reject case-insensitive route path or label collisions before mounted app
  routing is built, preventing ambiguous production navigation extension input.
- App-owned production home navigation descriptors now also reject
  case-insensitive label or path collisions with enabled demo home navigation,
  keeping production extension actions distinct from mounted demo actions.
- App shells now expose app-owned native readiness loaders that compose the
  generic capture, local-network, transport, and secure-key storage bridge
  capability facts into stable fail-closed readiness snapshots with scrubbed
  warnings before production flows decide whether native-backed features can be
  enabled.
- Mobile and desktop runtime objects now accept app-owned native readiness
  loaders and default home surfaces render stable ready/unavailable native
  status without exposing native warning detail, while custom home builders
  remain app-owned.
- Mobile and desktop production entrypoints now install the existing
  app-owned method-channel readiness loaders, so missing host capabilities are
  surfaced as unavailable instead of silently bypassing the readiness boundary.
- App-owned native readiness loaders now reject padded, control-character, or
  delimiter-bearing secure-key namespaces before native secure storage lookup,
  preventing malformed readiness configuration from reaching platform storage.
- App-owned native readiness loaders now enforce the same default transport
  payload-limit ceiling as native transport session factories, and fail closed
  before native capability lookup when the app-owned readiness limit is invalid.
- App-owned production route maps can now mark specific non-demo routes as
  native-readiness-required; those routes fail closed to the scrubbed
  route-unavailable surface until the app-owned readiness loader reports all
  native capabilities ready.
- Default app home surfaces now hide native-readiness-required production
  navigation actions until the same app-owned readiness snapshot reports all
  native capabilities ready, preventing unavailable native-backed actions from
  being advertised before route guards can pass.
- Default app home surfaces now render app-owned production navigation apart
  from enabled demo navigation, preserving the combined validated navigation
  list for custom home builders while giving production routes a distinct
  default launch surface.
- Production-only default app home surfaces now suppress demo fixture scenario
  controls and use production-oriented title/subtitle text when the runtime
  exposes app-owned production navigation without enabled demo actions.
- Production-only default app home surfaces keep that production presentation
  even when native-readiness filtering temporarily hides every protected
  production navigation action.
- Production-only default app home surfaces now render a stable production
  "routes unavailable" state when app-owned production navigation exists but
  no production action is currently launchable.
- App-owned custom home builders now receive production navigation after the
  same native-readiness filtering as the default home, preventing protected
  native-backed production routes from being advertised while unavailable.
- App-owned custom home builders also receive native-readiness-required
  production navigation once readiness passes, locking the same hidden/visible
  policy as the default home.

## Current environment handoff gaps
- No `.zip` project archive is present in this repository snapshot; all
  checked-in markdown files were reviewed directly from source.
- Native capture blocking on other platforms, Android/Windows runtime and
  device/network reachability validation, real local-network discovery,
  other-platform secure storage, production database persistence, operator
  release signing, and final production app UI validation remain open because
  they require device/OS integration, product design validation, or owner-controlled
  release inputs. Android and Windows bounded native transport implementations
  are now coded and both host builds pass; host socket availability is not
  proof of cross-device reachability or production endpoint provisioning.
  The Dart contracts,
  shared app-shell UI primitives, app-owned receipt key
  provisioning/read/write mapping, file-backed recovery persistence seam,
  replay event-range request validation,
  sync recovery persistence scope-identity validation,
  app-owned recovery store construction, exact environment-configured recovery
  root loading, native app-support recovery-root fallback, app-owned recovery
  root validation, mounted recovery-window loading,
  package-owned bootstrap peer-id validation,
  package-owned session path peer-id validation,
  package-owned primary peer identity validation,
  app-owned route runtime dependency grouping, app-owned table runtime-scope
  injection, canonical app-route
  registry validation, exact app-owned enabled-route allowlists,
  bounded app-owned route registry metadata,
  bounded app-owned enabled-route allowlist metadata,
  app-owned route-map allowed-extra path validation, app-owned demo
  route-extension collection bounding,
  app-owned route-map allowed-extra case-collision validation,
  app-owned route-map drift diagnostic scrubbing,
  app-owned unknown-route sensitive diagnostic suppression,
  app-owned production route-map extension, app-owned
  startup route selection, app-owned production navigation descriptors,
  app-owned production route/navigation case-collision validation,
  app-owned production/demo navigation case-collision validation,
  app-owned join invite-context injection, route-level join input validation,
  mounted join/setup async dependency reload handling,
  app-owned join input validation,
  app-owned receipt envelope injection, app-owned setup intent injection,
  route-level setup identity validation, app-owned setup identity validation,
  app-owned join outcome diagnostic scrubbing and bounding, app-owned setup outcome
  diagnostic scrubbing and bounding, app-owned receipt render diagnostic scrubbing
  and bounding,
  app-owned production route metadata validation, app-owned home navigation
  collision validation, app-owned production route builder failure handling,
  app-owned production route metadata bounding, app-owned production
  route/navigation collection bounding,
  case-insensitive demo namespace reservation for app-owned production routes,
  app-owned native readiness capability aggregation,
  app-owned native readiness runtime/home wiring,
  app-owned native readiness secure-key namespace validation,
  app-owned native readiness transport payload-limit validation,
  app-owned native readiness production-route gating,
  app-owned native readiness production-navigation filtering,
  app-owned default-home production/demo navigation sectioning,
  app-owned production-only default-home demo suppression,
  app-owned production-only native-readiness empty-action handling,
  app-owned production-only empty-action status rendering,
  app-owned custom-home native-readiness production-navigation filtering,
  app-owned custom-home native-readiness production-navigation restore,
  app-owned transport payload-limit
  enforcement, app-owned
  transport sink validation, app-owned transport receive-scope validation,
  app-owned transport receive-batch bounding,
  app-owned transport sensitive-note scrubbing,
  package-owned transport identity validation, generic native transport
  sequence validation, generic native transport byte-payload validation,
  generic native transport exact-key validation,
  app-owned receipt secure-key record bounding,
  app-owned receipt native key-id metadata bounding,
  app-owned receipt key material bounding,
  app-owned receipt provisioning factory failure handling,
  app-owned receipt mutation key-id bounding,
  app-owned receipt delete key-id validation, generic native secure-key
  request validation,
  app-owned receipt export provisioning diagnostic scrubbing,
  app-owned receipt export provisioning exception handling,
  app-owned receipt verifier key-ring load exception handling,
  app-owned receipt verifier diagnostic scrubbing and bounding,
  app-owned receipt verifier decoder diagnostic scrubbing and bounding,
  bounded app-owned table/join bootstrap mapping, app-owned local-network
  bootstrap scope validation, app-owned
  mounted table runtime-scope reload handling,
  local-network discovery list validation,
  app-owned local-network sensitive-note and endpoint scrubbing,
  app-owned capture sensitive-note scrubbing,
  shared safe-surface render text scrubbing,
  app-owned table warning rendering scrubbing,
  app-owned mounted table load warning scrubbing and bounding,
  app-owned mounted table bootstrap candidate bounding,
  app-owned mounted table recovery-window display bounding,
  local-network/transport/capture diagnostic scrubbing, scrubbed route-failure
  diagnostics, scrubbed receipt secure-key diagnostics, and method-channel
  payload gates, plus relay fallback on join candidate resolution failure, are
  locked for those follow-up implementations. The app-owned Hold'em route,
  publisher, typed registration, default production-surface seams, and bounded
  Android/Windows native transport hosts are also implemented; actual product
  session/state provisioning, device/network transport validation, navigation
  polish, and UI validation remain open. Mirrored
  `AppHoldemProductionSessionFactory` seams now compose the existing route
  boundary from injected canonical session/variant state, close-retention
  adapter, and peer identity with fail-closed app metadata and cursor/session
  checks; mirrored `AppHoldemProductionSessionSource` and
  `AppHoldemProductionSessionBootstrap` seams now validate resolved-invite
  correlation before invoking that factory. The real product source still
  owns durable state hydration and local identity. Mirrored
  `AppHoldemProductionSessionBootstrapRoute` adapters now accept a resolved
  invite through route arguments, invoke that bootstrap, enforce exact route
  path correlation, and mount the existing validated route. Missing arguments,
  source failures, and path mismatches fail closed; this adapter does not
  create a product session source or local identity.
  Mirrored app-shell `PeerDealAppNavigationEntry` values may now carry one
  opaque route payload. Default production home navigation forwards that value
  through `RouteSettings.arguments`, so a product caller can launch the
  bootstrap-route adapter with its resolved invite. The shell does not inspect
  or persist the payload; source hydration, local identity, and final product
  navigation remain integration-owned.
  Mounted join routes now preserve only identity-safe invites from accepted
  joined/rejoined outcomes and expose an optional post-frame
  `JoinFlowReadyHandler` through both app runtimes. Product callers can use it
  to push the bootstrap-route adapter; rejected outcomes, stale async outcomes,
  and handler failures do not trigger handoff.
  The mirrored production-session bootstrap now bounds product-owned source
  hydration with a configurable positive timeout and a five-second default;
  mounted routes show a loading surface while pending and use the existing
  route-unavailable fallback after timeout or other failure.
  Its optional cancellation signal is completed by the mounted route on
  replacement or disposal, and the bootstrap cancels its own deadline timer
  on source completion, cancellation, timeout, or failure. The concrete product
  source remains responsible for canceling underlying persistence or network
  work.
  Mirrored app shells now accept an optional
  `AppHoldemProductionSessionBootstrapRouteRegistration`. The registration
  mounts the existing bootstrap adapter, merges it into the production route
  map, and includes its path in the native-readiness gate. Without an explicit
  `JoinFlowReadyHandler`, accepted joined/rejoined outcomes navigate to that
registered path with the identity-safe resolved invite; an explicit handler
overrides the default. This closes app-shell route plumbing only and does
not create the concrete product source, state, local identity, or persistence.
The registration also exposes a mirrored `fromSource(...)` constructor that
keeps source, bootstrap timeout, and route assembly together at the app edge;
the product source remains caller-owned.
The mirrored app runtimes also accept one
`AppHoldemProductionSessionConfiguration.fromSource(...)`, derive the route
registration once, and reuse it for route merging, readiness, and default
join handoff. Supplying both the explicit registration and configuration is
rejected with a state error; this remains app orchestration and does not add
state serialization, persistence, identity provisioning, or a concrete source.

The T50 UI hardening pass now gives shared action controls explicit accessible
labels and tap actions, stacks fact rows below 360px, and projects mirrored
production Hold'em phase, betting-round, current-actor, and seats-header state
with user-facing labels. This closes the codable presentation/accessibility
gap; final visual design review, text-scale/device validation, and end-to-end
product navigation remain external validation work.

The T51 follow-up makes shared action controls keyboard-focusable with explicit
focus semantics, pointer-to-focus behavior, and local Enter/numpad-Enter/Space
activation bound to the same action callback. The focus outline keeps a stable
layout footprint; device keyboard, screen-reader, and text-scale validation
remain external.

The T52 follow-up enforces a 48 logical-pixel minimum interactive height on the
same shared action controls, keeping touch and pointer targets usable without
changing the public control API. Device, text-scale, screen-reader, and final
visual validation remain external.

The T53 follow-up fixes mirrored production Hold'em action routing so Fold,
Call/Check, and All-in events carry the configured local seat rather than
assuming seat zero. Focused route tests now decode the canonical outbound event
and assert non-zero local-seat attribution in both app shells.

The T54 follow-up adds strict `peerdeal_core` `TableState.fromJson(...)`
hydration matching the existing `toJson()` shape. It rejects malformed field
types, unknown phases, and non-string metadata keys before typed state is
rehydrated. This advances persistence safety without inventing the still-open
product source or database wiring.

The T55 follow-up adds strict variant-owned JSON serialization and hydration for
`HoldemHandState` and `HoldemSeatState`, including enum, nested-seat, collection,
nullable, and primitive validation. Product source provisioning, database
wiring, and local identity remain integration-owned.

The T56 follow-up adds strict `HoldemEventCursor` JSON serialization and
hydration for event scope, sequence, hash-chain predecessor, actor, and
last-event state. Hydration requires caller-owned event-id, timestamp, and
optional hash factories, preserving event policy ownership at the product edge.
Product persistence and local identity wiring remain integration-owned.

The T57 follow-up composes those parsers into a typed `HoldemStateSnapshot` and
mirrored mobile/desktop `AppPersistedHoldemProductionSessionSource` adapters
over the existing recovery persistence store. The adapters validate snapshot
type, version, invite scope, base sequence, and cursor continuity, and fail
closed when recovery suffix events would require product-owned replay. The
caller still supplies local identity, route/close policy, event factories, and
the product input mapping; concrete database wiring and suffix replay remain
open integration work.

The T58 follow-up closes the suffix-replay portion of that boundary. The
variant-owned replay transaction validates each persisted event through the
Hold'em cursor, applies universal events through `CoreReducer`, applies
hand-scoped events through `HoldemEventReducer`, and commits only after the
whole suffix succeeds. Invalid or unsupported suffixes fail closed without
partial state. Product database selection, local identity, and native/device
runtime validation remain integration or operator-owned.

The T59 follow-up adds mirrored app-owned local peer identity persistence over
the existing generic secure-key bridge. The app maps one fixed identity record
within the `peerdeal.identity` namespace, reuses exactly one active valid
record, provisions a secure-random peer ID when the record is missing, and
fails closed on unavailable, invalid, inactive, or ambiguous storage. The
concrete production source still needs to compose this identity with real
route policy, remote peer selection, and product state/database wiring.

The T60 follow-up closes the app-owned composition portion of that boundary.
Both app shells can now provision or reuse the local identity and construct the
existing persisted production source with `localPeerId`, caller-supplied route
and navigation policy, remote peer ID, local seat, and close-event adapter.
This is a deterministic composition seam, not a database or peer-discovery
implementation: concrete persistence selection, remote-peer discovery, native
runtime validation, and operator-owned release credentials remain open outside
the app factory.

The T61 follow-up hardens first-use local identity provisioning in both app
shells. Concurrent callers now share one in-flight load/generate/save operation,
so the app cannot race itself into replacing a newly persisted peer ID. The
guard is cleared after either outcome, preserving retry behavior after a
transient native-storage failure. This is an in-process guarantee; multi-process
and real-device persistence validation remain operator/runtime work.

The T62 follow-up adds a read-after-write integrity check to generated local
identity provisioning. After native save succeeds, the app reloads the identity
and returns success only when the exact generated peer ID is present and valid.
Storage contention, replacement, malformed read-back, and unavailable
verification fail closed. This detects, but does not eliminate, cross-process
write races; OS/device persistence validation remains external.

The T63 follow-up closes the codable first-join handoff gap. The app-owned join
flow now exposes a `JoinFlowSessionContext` only when bootstrap has selected a
reachable peer and accepted governance has returned a positive seat. Both app
shells pass that context through a context-aware production bootstrap route;
the persisted Hold'em source applies the verified peer and seat while keeping
snapshot scope validation and recovery replay unchanged. Invite-only callbacks
remain compatible for legacy sources.

The T64 follow-up closes the codable rejoin binding gap. Accepted rejoin
governance results may now return an app-owned `assignedPeerId` alongside the
positive seat, and the orchestrator propagates that binding through the same
validated session context. A missing or invalid governance peer produces no
production session handoff. Concrete product database/source provisioning,
native transport reachability, and device validation remain integration or
operator work.

The T65 follow-up closes the app-owned persisted-source composition gap. Both
app shells now expose an async
`AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(...)`
factory that composes the existing JSON recovery store with the persisted
Hold'em source and registers the validated bootstrap route while retaining
caller-owned route policy and event factories. Its production path provisions
or reuses native local identity only after invite-scoped snapshot validation
and recovery replay. This is a recovery-backed integration seam, not production
database provisioning; product state selection, route policy, native
reachability, and device validation remain separate.

The T66 follow-up closes the fail-early configuration gap. Both app-owned
configuration entry points now reject non-positive source-load timeouts before
route assembly, and the persisted-identity factory validates before invoking
native identity provisioning. Mirrored tests prove invalid configuration does
not mutate secure-key storage. This does not create product database/state
provisioning or change the external runtime/device validation boundary.

The T67 follow-up extends the same fail-early rule to persisted route policy.
Path, navigation label, remote peer identity, and positive local-seat policy
are validated before native identity provisioning. Mirrored tests prove an
invalid route policy cannot mutate secure-key storage; product database/state
provisioning and runtime/device validation remain separate.

The T68 follow-up removes the remaining eager identity side effect from the
production persisted-session configuration path. Its lazy source composition
checks the invite-scoped recovery snapshot and deterministic suffix replay
before invoking native identity provisioning. Missing snapshots, unsupported
versions, scope mismatches, malformed state, or rejected replay therefore do
not mutate secure-key storage; valid loads retain the existing identity
provisioning and route composition behavior.

The T69 follow-up closes the persisted-source cancellation gap. Invite and
session-context loads now observe the app route cancellation signal before
recovery access and immediately before and after lazy identity provisioning.
Cancelled loads fail closed with a stable error and do not mutate secure-key
storage when cancellation is already signaled; underlying native calls remain
bounded by their existing bridge deadlines.

The T70 follow-up closes the remaining unbounded generic capture bridge call
path. Capability and blocking method-channel calls now reject non-positive
timeouts and return stable fail-closed timeout results after the same
five-second default used by secure storage, transport, and local-network
bridges. Runtime Android/Windows capture validation and other-platform capture
implementations remain external.

The T71 follow-up closes the remaining persisted-identity cancellation gap.
Generic secure-key load/save/delete calls expose an additive per-call
cancellation capability, and mirrored app identity loaders, writers,
provisioners, and persisted Hold'em sources propagate route cancellation into
that seam. Cancellation fails closed before the bridge deadline; Dart cannot
retroactively withdraw a host mutation already dispatched, so host persistence
must remain atomic and idempotent. Native device persistence and runtime
validation remain external.

The T72 follow-up closes the mounted receipt verification cancellation gap.
Mirrored app key-ring loaders, artifact verifiers, presenters, and receipt
routes now propagate an additive route cancellation signal into the generic
secure-key load seam and complete it on route replacement or disposal. Legacy
secure-key bridges remain valid through the existing load method. This bounds
the Dart wait and prevents a pending receipt verification from outliving its
route; it does not retroactively cancel a host call already dispatched and does
not replace native persistence, device/profile, or release-signing validation.

The T73 follow-up closes the mirrored app transport lifecycle cancellation gap.
Provisioners now fail closed when route cancellation wins during injected
session loading, and transport sources race pending polls against both route
replacement and source disposal. A cancelled poll returns before the native
drain settles, but remains registered until that drain actually settles so a
second poll cannot overlap it. This hardens the Dart lifecycle boundary without
claiming retroactive cancellation of an already-dispatched host call or proving
native transport reachability.

The T74 follow-up hardens native transport identity decoding on the implemented
Android and Windows hosts. Received UDP frame fields must decode as strict
UTF-8 and pass the existing nonblank, unpadded, control-free identity rules;
invalid bytes are discarded before they enter the bounded receive queue, and
invalid app-supplied fields are rejected before a send. This closes a concrete
host input-normalization gap without claiming device, firewall, multicast, or
cross-platform reachability.

The T75 follow-up registers the locked generic local-network method channel on
the Android and Windows hosts and reports bounded active-interface capability
facts plus generic interface hints. Host discovery remains fail-closed with an
empty `foundEndpoints` list because this repository contains no discovery
advertisement protocol or product endpoint-provisioning contract; fabricating
peer identities or introducing an unowned wire format would cross the protocol
and app boundaries. Android APK and Windows debug builds pass for this host
registration slice.

The T76 follow-up adds additive cancellation capabilities to the generic
capture bridge. Capture capability and blocking calls now race the existing
five-second deadline against mounted-route cancellation, and mirrored receipt
presenters/coordinators forward that signal during route replacement or
disposal. Teardown release remains uncancelled so native blocking can still be
disabled. Focused native bridge, coordinator, and receipt presenter suites
pass; already-dispatched host calls and runtime/device capture validation
remain external.

The T77 follow-up closes the remaining unbounded app-support directory lookup.
The generic app-storage method channel now uses a positive five-second default
deadline and an additive cancellation capability, returning stable unavailable
facts when timeout or cancellation wins. Mirrored recovery persistence
factories forward cancellation when the injected bridge supports it and still
fail closed without constructing a factory when native directory lookup is
unavailable. Runtime persistence validation and product database/state
provisioning remain external.

The T78 follow-up closes the app-shell native-readiness lifecycle gap. Generic
local-network and native-transport capability bridges now expose additive
per-call cancellation, and mirrored readiness loaders forward the route signal
to compatible capture, local-network, transport, and secure-key bridges. Mobile
and desktop app states cancel stale readiness work on loader replacement and
dispose. The readiness result remains stable and fail-closed when cancellation
wins. Already-dispatched host calls, runtime/device validation, network
reachability, other-platform native implementations, and product database/state
provisioning remain external.

The T79 follow-up adds native host compilation to repository CI. Pull requests
and pushes to the configured CI branches now compile an Android debug APK and a
Windows debug host in separate platform jobs, in addition to the existing
workspace analyzer, boundary, dependency, source-text, and test gates. These
jobs prove host build compatibility only; release signing, runtime/device
secure-key and capture behavior, network reachability, and product state
provisioning remain separately owned.

The T80 follow-up exercises the Android release-signing guard in CI as an
expected failure. A credential-free release build must stop at the Gradle guard
before artifact assembly, preventing an accidental unsigned release path. The
check uses no operator secrets and does not prove a successful signed artifact,
release profile, or real-device behavior.

The T81 follow-up makes that negative check deterministic: CI explicitly clears
all four Android signing variables and requires the exact Gradle signing
diagnostic. An unrelated release-build failure cannot satisfy the guard.

The T82 follow-up closes the mounted join-flow lifecycle gap in both app shells.
Route replacement and disposal now cancel the active outcome; orchestration
checks that signal between pre-commit stages and will not advance into
governance after a cancelled bootstrap. Native join bootstrap forwards the same
signal to cancellable local-network bridges, while legacy bridge contracts remain
valid. Calls already dispatched to adapters or governance remain owner-hosted.

The T83 follow-up closes the app-process receipt key provisioning race. Mirrored
receipt key-ring provisioners now single-flight concurrent `ensureActiveKeys()`
calls, so concurrent exports share one native load/provision sequence instead
of generating competing active keys or returning divergent in-memory rings. The
guard clears after success or failure, preserving retry behavior. Cross-process
storage atomicity and native/device persistence validation remain external.

The T84 follow-up closes the receipt key write-integrity gap. After creating any
missing active key, mirrored app provisioners reload native storage and compare
both active key IDs and secrets with the provisioned ring. A missing, malformed,
or mismatched read-back returns an empty key ring and fails closed; existing
complete rings do not incur a write. Cross-process atomicity and runtime/device
validation remain external.

The T85 follow-up closes the mounted receipt export lifecycle gap. Mirrored app
shells now expose an additive cancellation-aware export callback, and receipt
route replacement or disposal forwards the signal through key provisioning,
secure key writes, and the existing cancellable native secure-storage bridge.
The legacy one-argument callback and generic native bridge contracts remain
valid. Already-dispatched native mutations, cross-process atomicity, and
runtime/device validation remain external.

The T86 follow-up hardens the Windows native secure-key host against concurrent
PeerDeal app processes. Load, save, and delete now acquire a per-namespace
`Local` named mutex with a bounded five-second wait, so Windows read-modify-write
operations are serialized across host processes and fail closed on lock
failure. This does not create compare-and-swap/version semantics, change the
generic credential contract, or prove Android multi-process, device, or runtime
behavior.

The T87 follow-up applies the same host-level serialization to Android. The
secure-key handler now stores encrypted envelopes in private files under the
app's `noBackupFilesDir`; load, save, and delete use a hash-named private lock
file with at most five seconds of `tryLock` retries and fail closed if the lock
is unavailable. Writes flush and sync a temporary file before replacing the
namespace file. Existing preference-backed envelopes migrate under the lock.
The AES-GCM payload, Android Keystore master-key contract, and generic channel
shape are unchanged. This closes the PeerDeal Android host process race but
does not add compare-and-swap/version semantics or prove runtime/device
behavior.

The T88 follow-up closes the remaining app/native stale-writer gap for the
implemented Android and Windows hosts. Generic secure-key snapshots now carry a
nonnegative namespace revision, and additive conditional save/delete methods
compare an expected revision under the host's existing namespace lock or mutex,
returning a stable conflict instead of overwriting a newer record. Android
encrypted file envelopes and Windows Credential Manager v2 envelopes persist the
revision, preserve empty-namespace tombstones, and accept legacy storage with
revision zero. Mirrored receipt key-ring and local-identity provisioners pass the
revision and refresh on a conflict while retaining legacy bridge compatibility.
This closes the coded CAS/version gap; runtime/device validation, other-platform
storage, release signing, and product state/database wiring remain separate.

The T89 follow-up adds a dependency-free Windows native-host smoke target under
the desktop app's `tool/` directory. The T90 follow-up fixed the native send
contract mismatch in both Android and Windows: the Dart bridge sends a nested
`frame` map, which both hosts now unwrap before validation and encoding. Windows
also selects an operational IPv4 multicast interface by adapter metric for
membership and sends. The built Windows host was executed directly and passed
app-support lookup, capture capability plus enable/release, local-network
capability/discovery, transport capability/send/receive, and secure-key
save/read-back, stale-writer conflict, conditional replacement/delete, and
tombstone read-back checks. Android debug APK compilation passed. Cross-device
reachability, Android device validation, and release signing remain external.
The T91 follow-up makes Android multicast interface selection explicit for both
send and receive, preferring an operational non-loopback IPv4 Wi-Fi/Ethernet
interface and failing closed when none is available. The APK still requires a
real-device pass for runtime behavior.

The T92 follow-up promotes the existing Windows native host smoke from a
manually executed proof to a repeatable CI gate. A bounded repository-owned
PowerShell runner captures host diagnostics, requires the stable smoke pass
marker, rejects nonzero exits, and terminates timed-out hosts. This strengthens
host regression coverage without claiming firewall, device, release-signing,
or cross-device reachability validation.

The T93 follow-up closes the remaining app-owned composition convenience gap.
Both app shells now expose `AppHoldemProductionSessionConfigurationFactory`,
which composes the existing recovery-root factory, lazy native local-identity
provisioner, persisted Hold'em source, caller-owned route policy, and
deterministic event/replay/session dependencies. It returns a stable
available/unavailable result, preserves persistence warnings, and validates
route policy before any identity work. This does not invent product state,
route policy, or a startup invocation; the concrete product session owner still
must supply authoritative snapshot persistence and call the factory.

The T94 follow-up closes the app-owned typed snapshot persistence seam. Both app
shells now expose `AppHoldemProductionSessionSnapshotWriter` through the T93
configuration result. It validates snapshot identity, recovery scope, event
cursor sequence, and last-event hash consistency, creates a typed
`HoldemStateSnapshot` payload, computes its canonical hash, and delegates the
existing recovery store with fail-closed results. It does not select product
state, append the event log, own a database or retention policy, or invoke
startup; those remain product integration work.

The T96 follow-up closes the app-owned event-log-plus-checkpoint seam. Both app
shells now expose `AppHoldemProductionSessionPersistenceWriter` through the
configuration result. It validates a caller-supplied event suffix for exact
scope and hash/sequence continuity, appends events before the typed snapshot,
rejects retention events before storage, and reports when a checkpoint fails
after the event log is durable for suffix replay. It does not select product
state, event identity, snapshot IDs, route or retention policy, startup, or a
production database.

The T97 follow-up closes the direct-source metadata bypass around the
first-join/rejoin handoff. Mirrored `AppPersistedHoldemProductionSessionRoutePolicy`
instances now revalidate both configured values and context-supplied remote
peer/local-seat overrides before constructing production session input. This
preserves the bootstrap's fail-closed metadata boundary for direct source
consumers without selecting product state, changing route policy ownership, or
replacing durable database/runtime validation.

The T98 follow-up closes an avoidable partial-write path in the app-owned
event-log-plus-checkpoint seam. Mirrored persistence writers now preflight
snapshot identity, snapshot metadata, scope/cursor/hash consistency, and typed
Hold'em state before appending an event suffix. Genuine checkpoint persistence
failures still retain the deliberate durable-suffix-for-replay behavior. This
does not select product state, event or snapshot identity, retention policy, or
replace durable database/runtime validation.

The T99 follow-up closes a mixed-cancellation cleanup race in the mirrored
local-peer identity provisioners. Only non-cancellable operations are shared,
and in-flight cleanup now checks the exact tracked Future before clearing it, so
a completed cancellable call cannot clear a newer shared operation. Cancellable
callers still propagate their own cancellation into native secure-key calls.
This remains an in-process guarantee; native multi-process/device persistence
validation remains external.

The T100 follow-up closes the receipt resource-bounding gap. The shared
`ReceiptExportLimits` contract now bounds encoded artifact bodies, decoded JSON
bodies, plaintext payloads, HMAC ciphertext strings, and encryption nonces
across receipt export encoding, inspection, and cipher operations. Oversized
values fail closed before unbounded base64, JSON, or keystream work. This does
not replace the existing receipt format or signing/key-ring ownership, and it
does not claim native key-storage, device, network, database, or release-signing
validation.

The T101 follow-up closes the JSON recovery file-size gap. The
`JsonFileRecoveryPersistenceStore` now enforces a positive configurable
`maxFileBytes` limit with a 4 MiB default, rejects oversized durable files
before JSON decoding, and rejects oversized canonical windows before temporary
file replacement. Both paths fail closed with
`ERR_RECOVERY_PERSISTENCE_FILE_TOO_LARGE`. This bounds the JSON fallback only;
it does not claim production database replacement or platform filesystem/
runtime validation.

The T102 follow-up closes a generic native bridge materialization gap.
`peerdeal_native_bridges` now bounds transport frame batches, discovery
collections, secure-key record lists, frame payloads, identities, discovery
values, key fields, and diagnostics before iteration or model construction.
Oversized collections and fields fail closed through existing unavailable or
empty results. This does not claim native host, device, cross-device network,
production database, or release-signing validation.

The T103 follow-up closes the remaining unbounded generic app-storage and
capture strings. App-storage directory paths are capped at 4096 UTF-8 bytes,
and capture capability/action notes and warnings are capped at 512 UTF-8 bytes
before generic models reach app orchestration. Oversized values fail closed;
native host behavior, device enforcement, cross-device reachability, database
replacement, and release signing remain separate.

The T104 follow-up bounds native local-network enumeration before channel
serialization. Android caps interface enumeration at 64 entries. Windows
rejects adapter buffers above 1 MiB and caps adapter traversal at 64 entries and
unicast-address scans at 256 entries. Android and Windows host builds and the
direct Windows native-host smoke pass; device behavior and cross-device
reachability remain external.

The T105 follow-up applies the same resource bounds to native transport
interface selection. Android caps interface enumeration at 64 and each
interface-address scan at 256. Windows rejects adapter buffers above 1 MiB and
caps adapter traversal at 64 and unicast-address scans at 256. Android and
Windows host builds and direct Windows smoke pass; device behavior and
cross-device reachability remain external.

The T106 follow-up closes the remaining recovery event-window bound. The
`peerdeal_sync` in-memory and JSON stores now enforce configurable event-count
and per-event byte limits, defaulting to 4,096 events and the protocol codec's
64 KiB event bound. Oversized append batches, hydrated JSON windows, and
individual events fail closed before state mutation with stable fatal conflicts;
non-JSON event payloads are rejected as invalid rather than misclassified as
oversized.
This hardens the JSON fallback and in-memory seam only; it does not replace the
production database or prove platform/runtime persistence behavior.

The T107 follow-up closes the privacy scrubber materialization gap.
`DefaultDiagnosticsScrubber` now bounds recursive maps and lists at 64 entries,
nested depth at 8, text at 512 UTF-8 bytes, and protocol diagnostics at 64
items. Overflow emits stable truncation markers while sensitive-field redaction
remains intact. This hardens the shared privacy boundary; app rendering,
production database replacement, and platform/runtime validation remain
separate.

The T108 follow-up closes the provider-proof normalization materialization gap.
`DefaultProviderProofNormalizer` now applies `DealProofLimits` to provider
identity/reference text, JSON maps/lists, nesting, node count, and canonical
UTF-8 proof bytes. Unsupported values, non-finite numbers, non-string keys, and
overflow fail closed before verification bundle construction; normalized and
raw views share one immutable bounded payload. Provider-specific proof
semantics, product verification wiring, and platform/runtime validation remain
separate.

The T109 follow-up closes the canonical JSON materialization gap.
`peerdeal_protocol` now writes canonical JSON with bounded maps/lists, nesting,
UTF-8 text, node count, and encoded bytes, without first constructing an
unbounded normalized tree. `EventEnvelopeCodec` applies its configured wire
limit during both encode and decode validation and rejects unsupported values
or non-string object keys. Protocol schema semantics, product persistence,
platform/runtime validation, and release signing remain separate.

The T110 follow-up closes the receipt JSON structure gap.
`OpaqueExportDecoder` now validates decoded artifact-body and plaintext-payload
JSON through the bounded canonical protocol writer before receipt shape
inspection, using receipt-owned decoded-body and payload byte limits for text
and encoded output. Structurally oversized maps, deep values, unsupported
values, and invalid object keys fail closed without changing receipt signature,
cipher, opacity, or authorization semantics. Platform key storage and
runtime/device validation remain separate.

The T111 follow-up closes the typed state hydration structure gap.
`TableState`, `HoldemSeatState`, `HoldemHandState`, `HoldemEventCursor`, and
`HoldemStateSnapshot` validate materialized JSON through the existing bounded
canonical protocol writer before typed field reads or collection copies.
Oversized maps/lists and unsupported nested values fail closed while
deterministic truth remains in `peerdeal_core` and Hold'em rules remain in
`peerdeal_variants`. Product persistence/source wiring and platform/runtime
validation remain separate.

The T112 follow-up closes the direct protocol envelope hydration gap.
`EventEnvelope.fromJson` and `SnapshotEnvelope.fromJson` now validate their
complete materialized JSON trees through the bounded canonical protocol writer
before typed field access. The file-backed recovery store therefore fails
closed on structurally oversized persisted snapshot payloads before importing
them into in-memory recovery state. Protocol schema and sync ownership remain
unchanged.

The T113 follow-up closes the replay request traversal gap.
`EventWindowValidator` now enforces a configurable positive event-count limit,
defaulting to 4,096 events, and `BasicReplayEngine` checks the raw request list
before protocol, scope, range, selection, or projector work. Oversized requests
fail with `ERR_REPLAY_EVENT_WINDOW_TOO_LARGE`; selected windows remain validated
after filtering. This is a Dart replay-boundary hardening change and does not
claim product persistence, device/network reachability, other-platform hosts,
or release signing.

The T114 follow-up closes the remaining replay materialization and exception
gaps. Oversized requests now short-circuit before secondary validation; anchor
hashing and snapshot-suffix planning enforce the same default 4,096-event bound;
anchor hashing raises canonical list/node limits explicitly for that bounded
window; and `BasicReplayEngine` returns stable selection and anchor calculation
failure mismatches instead of allowing helper exceptions to escape. Protocol
hashing remains in `peerdeal_protocol`; product persistence, device/network
reachability, other-platform hosts, and release signing remain separate.

The T115 follow-up closes the direct sync traversal gap. `BasicConflictDetector`
and `BasicSnapshotApplier` now reject caller-provided recovery event lists above
the shared configurable 4,096-event default before protocol, scope, sequence,
or projector traversal, returning the fatal
`ERR_RECOVERY_EVENT_COUNT_TOO_LARGE` conflict. Durable persistence remains
behind its existing store-specific validation and codes; product database
persistence and runtime/device validation remain separate.

The T116 follow-up closes the direct sync event-materialization gap.
`BasicConflictDetector` and `BasicSnapshotApplier` now validate each direct
event through the existing `EventEnvelopeCodec` before protocol, scope,
sequence, or projector work. The shared default is 64 KiB per event with the
protocol canonical structure limits; oversized or unencodable events fail
closed with `ERR_RECOVERY_EVENT_TOO_LARGE` or `ERR_RECOVERY_EVENT_INVALID`.
This reuses protocol serialization and does not move sync policy into the
protocol package.

The T117 follow-up closes the direct sync snapshot-materialization gap.
`BasicConflictDetector` and `BasicSnapshotApplier` now validate supplied
`SnapshotEnvelope` values through bounded canonical JSON before protocol,
scope, or snapshot/suffix projection work. The shared default is 4 MiB with
the protocol map/list/depth/text/node limits; oversized or unencodable
snapshots fail closed with `ERR_RECOVERY_SNAPSHOT_TOO_LARGE` or
`ERR_RECOVERY_SNAPSHOT_INVALID`. The file-backed recovery default shares this
same snapshot limit constant.

## Next production hardening order
1. Validate Android secure-key/capture behavior on a real device and validate
   cross-device Android/Windows multicast reachability, including
   operator-owned release signing.
2. Replace the remaining native bridge stubs with platform implementations
   that satisfy the locked method-channel contracts, starting with other
   platform secure receipt key storage and capture enforcement behind the
   existing key-ring, cipher, signer, and app capture contracts.
3. Supply the concrete `AppHoldemProductionSessionSource` and invoke the new
   `AppHoldemProductionSessionConfigurationFactory` from the real product
   session/state source and local identity through the typed first-join and
   rejoin handoff, using `snapshotWriter` for authoritative typed snapshot
   persistence where product inputs are available through
   `persistenceWriter`, supplying event identity and snapshot IDs, and defining
   event-log policy and route policy;
   complete product state/route provisioning and navigation/UI validation while
   keeping native transport/device validation and durable database persistence
   separate.

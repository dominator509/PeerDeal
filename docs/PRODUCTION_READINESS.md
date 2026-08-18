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
- Mirrored local-identity loaders and provisioners now reject
  non-round-tripping UTF-8 warning text before it reaches session diagnostics;
  identity generation, secure-key persistence, and revision behavior remain
  unchanged.
- Mirrored bootstrap candidate result models now filter malformed provider
  output before app surfaces receive it, including unsafe peer identities,
  endpoint hosts/ports, priorities, and diagnostic reasons; valid candidates
  and existing candidate bounds remain unchanged.
- Mirrored app-owned local-network bootstrap projections now reject malformed
  UTF-8 provider peer identities and native diagnostic text before candidates
  or notes reach join/session surfaces; existing valid normalization and relay
  fallback behavior remain unchanged.
- Mirrored mobile and desktop join-flow acceptance now fails closed when an
  accepted invite or supplied session context is unsafe, including malformed
  UTF-16/UTF-8 identities; valid join and rejoin handoff behavior remains
  unchanged.
- Shared app-shell UI primitives now expose scaffold titles as semantic
  headings and operational status pills as live regions, improving screen
  reader navigation and status-change announcements across both app shells;
  layout, runtime state ownership, and action behavior remain unchanged.
- Windows native host smoke storage-path validation now uses the existing
  protocol-owned strict UTF-8 round-trip and byte ceiling before accepting the
  native app-support directory; native channel ownership and smoke checkpoints
  remain unchanged.
- Mirrored app Hold'em production session bootstrap invite identity validation
  now applies the existing canonical UTF-8 byte ceiling and exact round-trip
  check before product source loading; invite/source ownership and route
  composition remain unchanged.
- Opaque receipt export now preflights all required envelope text before JSON
  escaping and applies strict UTF-8 round-trip checks to plaintext and
  ciphertext payload limits during encoding and inspection; malformed receipt
  text fails closed without exposing a verified artifact.
- Privacy diagnostic scrubbing, crypto proof normalization/verification, and
  mirrored app Hold'em snapshot metadata validation now reject text that fails
  exact UTF-8 encode/decode round-trip checks, while preserving existing
  truncation, fail-closed, and persistence behavior.
- Hold'em variant text validation now uses the existing canonical UTF-8
  round-trip limit for hand state, public event payloads, and projection cursor
  identities, preventing malformed Unicode from entering variant state or
  reconstructed public events.
- Protocol canonical JSON text limits now require exact UTF-8 encode/decode
  round-trips. Core command ingress, event reduction, table-state hydration,
  and baseline invariant identity guards use that existing protocol limit, so
  unpaired UTF-16 text cannot become replacement text at deterministic state
  boundaries.
- Native bridge UTF-8 byte-limit checks now require an exact encode/decode
  round-trip, so unpaired UTF-16 text cannot be replaced and accepted as a
  different native identity or diagnostic value; existing channel contracts,
  limits, and package ownership remain unchanged.
- Network peer and transport identities now share a 256-byte, strict UTF-8,
  non-empty, unpadded, C0/C1-free predicate across frame validation, bootstrap
  parsing, path selection, primary election, relay fallback, and transfer
  planning; oversized discovery identities are rejected rather than truncated.
- Replay request scope identities now fail closed for blank, padded, oversized,
  non-round-tripping, and C0/C1-bearing text before projector state creation;
  replay request models and protocol envelope ownership remain unchanged.
- Recovery persistence scope identities now reject C0/C1 controls and
  malformed UTF-8 round-trips before deriving the existing delimiter-based
  storage key; key format and recovery package ownership remain unchanged.
- Hold'em variant state, cursor, and event-payload text validation now applies
  the existing canonical UTF-8 text-byte ceiling and rejects C1 controls;
  cursor construction also validates optional `last_event_type` without
  changing variant ownership or protocol event shape.
- Core typed command, event, and table-state ingress now applies the existing
  canonical JSON text-byte ceiling and rejects unsafe or oversized identities;
  the reducer reports a stable unsafe event-envelope invariant without
  changing protocol models or package ownership.
- Secure-key mutation boundaries now reject negative expected revisions before
  native calls, reject negative revisions returned by custom app bridges, and
  reject successful generic channel payloads with malformed revision fields.
  Nullable revisions remain compatible for non-CAS mutation implementations;
  invalid revision material cannot be propagated as success.
- Secure-key revision fields now also reject values above the signed 64-bit
  native storage range (`9223372036854775807`) at the shared channel decoder,
  method-channel bridge, and mirrored app readiness, local-identity, and
  receipt adapters. This keeps custom app bridges aligned with Android `Long`
  and Windows signed revision persistence without changing the generic channel
  shape or package ownership.
- Android native transport method-call decoding now accepts only integer
  sequence and payload-byte values, matching the Windows host instead of
  silently truncating fractional `Number` values before validation.
- Android secure-key recovery now accepts only integer JSON revisions from its
  authenticated persisted envelope; fractional or string revisions fail closed
  instead of being coerced by `JSONObject.getLong`. Missing revisions retain
  the legacy revision-zero behavior.
- The generic secure-key channel decoder now rejects unusable records before
  materializing an available snapshot. Mirrored app receipt-key and local
  identity loaders also reject decoder-bypass snapshots with negative
  revisions or unusable records, and receipt namespace validation rejects the
  existing reserved `::` separator. Empty but available storage remains
  valid; native persistence and device validation remain separate.
- Mirrored app native-readiness loaders now fail closed when an available
  secure-key bridge snapshot has a negative revision, exceeds the locked
  `NativeBridgePayloadLimits.maxSecureKeyRecords` ceiling, or contains an
  unusable `SecureKeyRecord`. Empty but available key storage remains valid;
  native key provisioning and platform/device validation remain separate.
- Mirrored app-owned Hold'em persistence writers now verify the exact event
  envelopes in the existing recovery store before honoring an
  `eventsAlreadyPersisted` retry flag, preventing a snapshot from advancing
  durable typed state without its event suffix.
- Android and Windows native multicast receive loops now apply a bounded
  backoff after persistent socket errors, preventing a host failure from
  becoming an unbounded CPU retry loop without changing the generic transport
  channel contract. Real-device and cross-device reachability validation remain
  external.
- The workspace and CI now use Melos 8.3.0, and dependency audit reports zero actionable upgrades; newer `meta` and `test` versions remain toolchain-blocked.
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
  unsupported command artifacts or protocol versions, plus padded or C0/C1
  control-bearing command and scope identities.
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
  street, public showdown, and settlement events. The reducer also rejects
  padded, blank, or C0/C1 control-bearing public text before projection while
  preserving its existing specific rejection codes. Both app runtimes can
  apply those events atomically, and transport handlers/provisioners can opt
  into the variant path. Private showdown cards are intentionally not
  reconstructed from public events.
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
  short all-ins can increase the amount to call without reopening raises for
  seats that already acted since the last full raise; full-raise all-ins are
  rejected until action is reopened. Betting-round flow also keeps matched but
  unacted seats eligible, preserving the big blind option and post-short-all-in
  check/call decisions.
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
- Network transport frame validation now rejects payload entries outside the
  0-through-255 byte range before native transport adapters receive them;
  native bridge byte validation remains a second fail-closed boundary. The
  same network gate rejects C0/C1 control-bearing frame identities before
  adapter or session-handler calls.
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
- Mirrored app-owned join bootstrap coordinators now also reject configured
  peer candidate limits above the locked native discovery-entry ceiling before
  native capability lookup or discovery parsing.
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
- Mirrored app-owned local-network bootstrap loaders now also reject configured
  peer candidate limits above the locked native discovery-entry ceiling before
  native capability lookup.
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
- Native secure key storage method-channel wrappers now reject blank, padded, or
  oversized UTF-8 namespaces, key ids, and key record fields before platform
  load/save/delete calls, keeping malformed generic secure-storage requests out
  of native code.
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
- App receipt key-ring loaders now also reject configured record limits above
  the locked native secure-storage ceiling before invoking native storage.
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
- Sync recovery file persistence now removes stale per-scope temporary write
  artifacts before every locked read, write, or wipe operation, and fails
  closed if those artifacts cannot be cleaned up, limiting crash remnants and
  retaining scope isolation.
- Mirrored app `SafeReceiptScanVm` boundaries now bound and scrub receipt status
  and message text before exposing it to UI or other consumers, instead of
  relying only on a later screen-level sanitizer.
- Mirrored app `NativeTransportSessionFactory` boundaries now reject configured
  and reported payload limits above the locked native bridge ceiling before
  native capability lookup, sender creation, or receiver creation.
- Mirrored app native transport sessions now carry the reported native payload
  ceiling into both their outbound and inbound frame validators. A custom app
  bridge can no longer accept a frame larger than the capability negotiated by
  the loaded session; the generic transport and native channel contracts are
  unchanged.
- Mirrored app native-readiness loaders now apply that same ceiling to both
  configured and reported transport payload limits before advertising native
  transport readiness.
- Mirrored app `NativeTransportFrameDrain` boundaries now reject configured
  receive-batch limits above the locked native frame ceiling before invoking
  the native receive bridge.
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
  route-unavailable surface until the app-owned readiness loader reports the
  route-critical native capabilities ready. Peer discovery remains a separate
  requirement for join/bootstrap flows.
- Default app home surfaces now hide native-readiness-required production
  navigation actions until the same app-owned route-critical readiness
  projection passes, preventing unavailable native-backed actions from being
  advertised before route guards can pass.
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
  sync recovery persistence scope-identity and snapshot-integrity validation,
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
  app-owned local peer identity secure-key record bounding,
  app-owned native app-support path byte bounding,
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

The T118 follow-up closes the recovery-scope storage-key materialization gap.
`RecoveryPersistenceScope` now bounds the complete UTF-8 storage key to 180
bytes before in-memory indexing or the existing base64url filename path. Both
in-memory and JSON recovery stores reject oversized scopes with the existing
`ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID` conflict before mutation or file
creation.

The T119 follow-up closes the direct sync request-scope bypass. Both
`BasicConflictDetector` and `BasicSnapshotApplier` now validate direct
table/session/protocol identities through the shared `RecoveryPersistenceScope`
rules before event traversal, snapshot projection, or projector access. Invalid
requests fail closed with `ERR_RECOVERY_SCOPE_INVALID` or
`ERR_SNAPSHOT_APPLY_SCOPE_INVALID`.

The T120 follow-up closes the direct network collection-materialization gap.
`peerdeal_network` now applies shared bounds of 32 peer IDs, 32 bootstrap
candidates, and 64 peer metrics before routing or confidence materialization.
Overflow fails closed as empty bootstrap candidates, unresolved path selection,
unsafe confidence, or unsafe primary election without traversing an unbounded
caller collection.

The T121 follow-up closes the direct Hold'em showdown seat-materialization gap.
`HoldemShowdownEvaluator` now applies the shared nine-seat launch invariant
before sorting seats, expanding cards, or evaluating hands. Oversized input
fails closed with `ERR_HOLDEM_SHOWDOWN_SEAT_COUNT`, and the same limit is reused
by `HoldemAdapter` identity and configuration validation.

The T122 follow-up closes the direct Hold'em settlement commitment-materialization
gap. `ShowdownSettlementProjector` now applies the shared nine-seat commitment
bound before invoking core side-pot construction for contested or uncontested
settlement. Overflow fails closed with
`ERR_HOLDEM_SETTLEMENT_PROJECT_COMMITMENT_COUNT`.

The T123 follow-up closes the direct Hold'em showdown projection-materialization
gap. `ShowdownEvaluationResult` now bounds result collections, pot-slice maps,
and per-slice contested seat-ID lists before building winner projections.
Overflow carries explicit `ERR_HOLDEM_SHOWDOWN_RESULT_COUNT`,
`ERR_HOLDEM_SHOWDOWN_SLICE_COUNT`, or
`ERR_HOLDEM_SHOWDOWN_SLICE_SEAT_COUNT` warnings into blocked settlement.

The T124 follow-up closes the direct core pot-materialization gap.
`SidePotBuilder` and `PotEngine` now apply variant-agnostic bounds of 64
commitments, 64 winning slice-map entries, and 64 winners per slice before
side-pot or award traversal. Overflow fails closed with
`ERR_CORE_SETTLEMENT_COMMITMENT_COUNT`,
`ERR_CORE_SETTLEMENT_WINNER_SLICE_COUNT`, or
`ERR_CORE_SETTLEMENT_WINNER_COUNT`.

The T125 follow-up closes the direct mode-governance collection gap.
`DefaultGovernanceEngine` now checks configurable limits before participant,
seat, or waitlist lookup/traversal, defaulting to 256 participants, 64 seats,
and 256 waitlist entries. Oversized collections and waitlist growth at
capacity fail closed with `ERR_GOVERNANCE_PARTICIPANT_COUNT`,
`ERR_GOVERNANCE_SEAT_COUNT`, or `ERR_GOVERNANCE_WAITLIST_COUNT`.

The T126 follow-up closes the direct wizard materialization gap.
`DefaultPresetResolver` now bounds preset layers, per-layer and merged values,
conflicts, helper suggestions, partial settings, ambiguities, and resolved
fields, while validating nested values through bounded protocol canonical JSON.
`DefaultGameFileCompiler` repeats the direct-plan boundary for resolved fields,
policy profiles, and validation messages, so oversized or unsupported values
cannot reach Game File construction; failures use stable `ERR_WIZARD_*` codes.

The T127 follow-up closes the direct receipt key-ring traversal gap.
`ReceiptKeyRingSnapshot` and `StaticReceiptSigningKeyProvider` now bound
retained verification/decryption collections to 128 entries by default before
lookup traversal. Oversized collections fail closed while active usable keys
remain available through the direct active-key path.

The T128 follow-up closes the app persisted-session recovery-window gap.
Mirrored `AppPersistedHoldemProductionSessionSource` adapters now enforce the
shared 4,096-event default, with a positive caller-owned override, immediately
after a recovery store returns a window. Oversized windows fail closed before
snapshot decoding, suffix materialization, identity provisioning, or replay.

The T129 follow-up closes the mirrored persistence-writer input gap.
`AppHoldemProductionSessionPersistenceWriter` now enforces the same shared
4,096-event default, with a positive caller-owned override, before traversing
or appending a caller-supplied suffix. Oversized suffixes fail closed without
creating durable event or snapshot data.

The T130 follow-up closes the app inbound event-batch materialization gap.
Mirrored `AppTableSessionRuntime` owners now enforce the shared 4,096-event
default, with a positive caller-owned override, before copying or reducing a
caller-supplied non-retention batch. Oversized input fails closed with
`ERR_APP_SESSION_EVENT_BATCH_TOO_LARGE` without mutating app state.

The T131 follow-up closes the production-composition limit propagation gap.
Mirrored bootstrap, route-registration, configuration, and session-factory
seams now carry one validated `maxRecoveryEvents` value into the app session
runtime. Persisted configuration reuses that value for source hydration and the
app persistence writer, so recovery paths do not silently diverge back to the
default.

The T132 follow-up closes the codable app-shell production handoff gap. Both
shells now accept an optional `AppHoldemProductionSessionConfigurationLoader`
that receives the accepted `JoinFlowSessionContext` from first join or rejoin
and returns the existing configuration-factory result. Available results must
carry configuration, persistence, and snapshot writers; the shell validates
dynamic route paths and collisions, mounts the existing bootstrap adapter behind
the native readiness gate, and fails closed on loader errors or unavailable
results. The product still owns the concrete source, state, route policy, and
factory invocation; device, platform, database, and signing validation remain
external.

The T133 follow-up adds local host-build and runtime evidence for the existing
native contracts. Android debug APK compilation and Windows debug host
compilation pass, and the dedicated Windows smoke target passes app storage,
capture, local-network, transport, and secure-key mutation checkpoints through
the default RTK-safe wrapper. This does not close real-device, cross-device,
other-platform, product persistence, or release-signing validation.

The T134 follow-up closes the remaining codable app-registration gap around
the persisted production-session factory. Both shells can now accept a
configured `AppHoldemProductionSessionConfigurationFactory` directly and
adapt it to the typed join/rejoin loader when no explicit loader is supplied.
The adapter preserves explicit route/handler precedence and passes the
accepted context through the existing bootstrap route. Product state/source
selection, route policy, database persistence, and native/device validation
remain caller-owned or external.

The T135 follow-up closes the codable persistence-discard gap in that route.
Both factories now share the existing typed snapshot writer with the existing
event-plus-snapshot persistence writer and a serialized route coordinator.
Accepted local projection suffixes and accepted remote events append through
the existing event-log policy before typed snapshot checkpointing. Failed
checkpoints remain ordered and visible as a retryable persistence-pending UI
state; accepted close/wipe retention clears pending checkpoint state so old
snapshots cannot be recreated after retention. This does not claim a product
session source, database, real-device storage, other-platform host, or release
signing implementation.

The T136 follow-up closes the remaining codable ordering gap in that retry
surface. Both mirrored coordinators retain newer accepted checkpoints behind a
repeatedly failing older checkpoint in FIFO order, preserve the durable-event
suffix marker, and resolve concurrent retry requests against the live pending
queue so an older retry cannot overwrite newer accepted state. Focused mobile
and desktop coordinator suites cover these paths. This remains route-level
recovery persistence, not product database persistence or cross-platform/device
validation.

The T137 follow-up closes the codable app-shell handoff race. Each asynchronous
loaded production-session handoff now carries a private generation token; late
success or failure from an older join/load is ignored after a newer handoff,
and disposal or higher-precedence route configuration invalidates the token
before fallback or production navigation. Mirrored mobile and desktop
app-shell suites cover delayed stale completion. This protects route
orchestration only and does not create product session state or a database.

The T138 follow-up closes the remaining app-shell configuration lifecycle edge.
Removing or replacing the optional production-session configuration factory now
invalidates any in-flight generated loader handoff before the next rebuild can
expose the changed route contract. Mirrored mobile and desktop suites cover
factory removal with a delayed stale completion. This remains app-shell route
orchestration hardening; product source/state selection, database persistence,
native host implementations, device validation, and release signing remain
separate readiness work.

The T139 follow-up closes a native contract-boundary mismatch in the Android
secure-key host. Android secure-key namespaces and record fields now enforce
the locked UTF-8 byte limits used by the Dart contract and the Windows host,
including multibyte values. The shared channel-contract suite covers the
multibyte rejection path, and Android debug compilation passes. This improves
host input hardening but does not replace Android device/runtime validation.

The T140 follow-up closes the corresponding Dart request-boundary gap. The
shared native-bridge contract now defines the 128-byte secure-key namespace
limit, and the method-channel wrapper rejects oversized UTF-8 namespaces before
dispatching to Android or Windows. Focused secure-key bridge coverage exercises
the multibyte rejection path. This keeps host and Dart request limits aligned;
device/runtime validation remains separate.

The T141 follow-up closes the remaining Dart secure-key text mismatch. Shared
safe UTF-8 validation now rejects oversized or control-bearing key IDs,
purposes, algorithms, secrets, namespaces, and delete requests before native
dispatch. The method-channel and channel-contract suites cover multibyte and
control-character rejection without weakening the generic bridge boundary.

The T142 follow-up aligns the remaining generic native bridge text boundaries
with the Android and Windows host rules. Transport identities and receive
scopes, local-network discovery values, capture diagnostics, and app-storage
paths and warnings now reject padded or C0/C1-control-bearing UTF-8 text before
native dispatch or app-policy projection. This closes shared Dart contract
drift without claiming other-platform hosts or runtime reachability.

The T143 follow-up closes the native app-support path contract mismatch. Android
no-backup storage and Windows `LocalAppData` results now fail closed unless the
path is valid UTF-8, non-padded, free of C0/C1 controls, and at most 4096 UTF-8
bytes. Android debug compilation and Windows debug compilation pass, and the
Windows native-host smoke asserts the returned path through the generic bridge.
This closes host boundary validation only; it does not claim production database
persistence, device/runtime reachability, other-platform hosts, or release
signing.

The T144 follow-up closes the app-shell context propagation mismatch. Mirrored
`AppHoldemProductionSessionConfigurationFactory` instances now accept an
optional `JoinFlowSessionContext` and context-aware route-policy factory, and
the generated loader forwards the exact accepted context before route/source
composition. Existing no-context factory callers retain their original policy
path. Focused mobile and desktop configuration suites cover the loader handoff;
this enables product-owned context policy but does not supply product state,
database persistence, device validation, other-platform hosts, or signing.

The T145 follow-up hardens the same factory's failure projection. If recovery
store creation succeeds with warnings but route-policy or persisted-source
composition later fails, the mirrored mobile and desktop factories retain those
warnings alongside the stable unavailable message. Exception detail remains
suppressed; this improves operator-visible truth without selecting product state
or changing persistence ownership.

The T146 follow-up closes a CI trigger gap. The repository workflow now runs on
direct pushes to `retrofit/**` and `hardening/**` in addition to `main` and
`master`, and supports manual `workflow_dispatch` runs. The existing analyze,
boundary, source-text, test, dependency, Android debug/signing-guard, Windows
build, and native-host smoke jobs are unchanged. This improves gate coverage;
it does not claim that GitHub-hosted execution, release credentials, device
reachability, or product state provisioning are complete.

The T147 follow-up closes a mounted-surface lifecycle gap. Mirrored production
Hold'em surfaces now clear pending projection/retry state when their runtime,
snapshot coordinator, peer, or local seat identity changes. Generation guards
ignore late persistence, transport, retry, and disposal completions from the
previous surface owner. Focused mobile and desktop route suites cover delayed
native-send completion after runtime replacement. Full repository gates plus
Android debug, Windows debug, and Windows native-host smoke validation pass;
product state provisioning, device/network validation, other-platform hosts,
and release signing remain separate.

The T148 follow-up closes the corresponding inbound-route lifecycle gap.
Mirrored table routes now capture accepted inbound events with their owning
runtime, snapshot coordinator, and lifecycle generation. Replaced or disposed
transport callbacks cannot checkpoint a replacement route or refresh its UI
state. Focused mobile and desktop route suites cover delayed inbound completion
after runtime replacement. Full repository gates plus Android debug, Windows
debug, and Windows native-host smoke validation pass; product state
provisioning, device/network validation, other-platform hosts, and release
signing remain separate.

The T149 follow-up closes the lower transport cancellation gap. Mirrored native
frame drains now receive the source cancellation signal and fail closed before
delivering late native frames; native sessions forward route cancellation into
the drain. Focused mobile and desktop transport/route suites cover late
receive suppression. Full repository gates plus Android debug, Windows debug,
and Windows native-host smoke validation pass; product state provisioning,
device/network validation, other-platform hosts, and release signing remain
separate.

The T164 follow-up closes the first-join typed-state provisioning gap in the
existing app-owned production-session source. Mirrored persisted Hold'em
sources and configuration factories now accept an optional product-owned
initial snapshot loader. When no recovery snapshot exists, the source validates
invite scope, zero event sequence, cursor sequence one, and the protocol
genesis hash, then checkpoints the typed state through the existing snapshot
coordinator before returning production input. Missing persistence, invalid
initial state, and checkpoint failures fail closed before route exposure;
focused mobile and desktop source/configuration suites cover the paths. Full
repository gates and Android/Windows artifact validation pass. Durable
database replacement, real product state selection, device/network validation,
other-platform hosts, release signing, and final UX remain separate.

The T165 follow-up closes the orphaned recovery-event integrity gap in the
app-owned persisted Hold'em source. A recovery window containing durable event
suffix data without a typed snapshot anchor now fails closed before invoking
the product initial-state loader, local identity provisioning, or checkpoint
coordinator; initial product state cannot mask an unanchored event log.
Focused mobile and desktop source suites cover the rejection and prove the
existing suffix remains unchanged. Durable database replacement, real product
state selection, device/network validation, other-platform hosts, release
signing, and final UX remain separate.

The T166 follow-up closes the persisted snapshot-integrity gap in the
app-owned Hold'em recovery source. Before typed hydration, mirrored sources
now recompute the canonical hash of the snapshot payload and require it to
match the persisted envelope `snapshot_hash`; malformed or tampered payloads
fail closed before local identity provisioning or route input construction.
Focused mobile and desktop source suites cover tampered-hash rejection while
canonical snapshots continue to load. Durable database replacement, real
product state selection, device/network validation, other-platform hosts,
release signing, and final UX remain separate.

The T167 follow-up closes the corresponding package-level snapshot-integrity
bypass in `peerdeal_sync`. `BasicConflictDetector` and
`BasicSnapshotApplier` now recompute the canonical snapshot payload hash and
reject mismatches with `ERR_SNAPSHOT_PAYLOAD_HASH_MISMATCH` before recovery
planning or projector access. The shared sync suite covers tampered hashes and
canonical valid snapshots. Durable database replacement, real product state
selection, device/network validation, other-platform hosts, release signing,
and final UX remain separate.

The T168 follow-up closes the inbound checkpoint event-identity gap in the
mirrored app session routes. Successful `AppTableSessionEventResult` values
now carry the exact accepted `EventEnvelope`, and Hold'em route callbacks pass
that value into checkpoint persistence instead of rereading mutable
`lastAcceptedEvent` state. Focused mobile and desktop runtime and
transport-handler suites cover the event identity fields across canonical
frame decoding. Durable database replacement, real product state selection,
device/network validation, other-platform hosts, release signing, and final UX
remain separate.

The T169 follow-up closes the app-session diagnostic ownership gap. Mirrored
`AppTableSessionEventResult` and `AppHoldemInboundEventResult` constructors now
defensively copy and freeze warning lists, so caller-owned input cannot mutate
projected diagnostics and result warning collections reject mutation. Focused
mobile and desktop runtime suites cover both properties. Durable database
replacement, real product state selection, device/network validation,
other-platform hosts, release signing, and final UX remain separate.

The T170 follow-up closes the app startup/session diagnostic ownership gap.
Mirrored recovery-store and production-session configuration load-result
constructors now defensively copy and freeze warning lists, preventing
caller-owned diagnostics from changing after route/session orchestration has
received them. Focused mobile and desktop configuration, recovery, and app-shell
suites cover source-list isolation and mutation rejection. Durable database
replacement, real product state selection, device/network validation,
other-platform hosts, release signing, and final UX remain separate.

The T171 follow-up closes the local-identity diagnostic ownership gap.
Mirrored local-identity loader and provisioner result constructors now
defensively copy and freeze warning lists, preventing secure-key and
production-session callers from changing projected identity diagnostics after
construction. Focused mobile and desktop local-identity suites cover source-list
isolation and mutation rejection. Durable database replacement, real product
state selection, device/network validation, other-platform hosts, release
signing, and final UX remain separate.

The T172 follow-up closes the native-readiness and transport-source diagnostic
ownership gap. Mirrored readiness snapshots and transport poll/start results
now defensively copy and freeze warning lists, preventing caller-owned
diagnostics from changing across native readiness and live transport lifecycle
boundaries. Focused mobile and desktop readiness and transport-source suites
cover source-list isolation and mutation rejection. Durable database replacement,
real product state selection, device/network validation, other-platform hosts,
release signing, and final UX remain separate.

The T173 follow-up closes the remaining app-boundary collection ownership gap.
Mirrored native bootstrap candidate, native transport session/frame-drain, and
receipt key-ring result constructors now defensively copy and freeze exposed
candidate, receive-result, and warning collections. Focused mobile and desktop
transport, bootstrap, and receipt suites cover source-list isolation and
mutation rejection. Durable database replacement, real product state
selection, device/network validation, other-platform hosts, release signing,
and final UX remain separate.

The T174 follow-up closes the generic native-bridge collection ownership gap.
Native bridge models now defensively copy and freeze local-network discovery
lists, secure-key record lists, native receive frame lists, and transport frame
payload bytes before results cross the package boundary. Focused native bridge
contract tests plus affected mobile and desktop suites cover source-list
isolation and mutation rejection. Durable database replacement, real product
state selection, device/network validation, other-platform hosts, release
signing, and final UX remain separate.

The T175 follow-up closes the generic network collection ownership gap.
Network models now defensively copy and freeze bootstrap peer/candidate lists,
LAN discovery lists, transport payload bytes, warning diagnostics, and
peer-election rankings before results cross the network package boundary.
Focused network and app transport suites cover source-list isolation and
mutation rejection. Durable database replacement, real product state
selection, device/network validation, other-platform hosts, release signing,
and final UX remain separate.

The T176 follow-up closes the generic sync/recovery collection ownership gap.
Sync models now defensively copy and freeze recovery event requests/windows,
conflict results, warning diagnostics, snapshot results, persistence results,
and reconciliation notes before results cross the recovery boundary. Focused
sync ownership, conflict, snapshot, and coordinator suites cover source-list
isolation and mutation rejection. Durable database replacement, real product
state selection, device/network validation, other-platform hosts, release
signing, and final UX remain separate.

The T177 follow-up closes the deterministic replay collection ownership gap.
Replay requests, snapshot suffix plans, and replay results now defensively copy
and freeze event windows, warning diagnostics, and replay mismatches before
crossing the replay boundary. Focused replay ownership, engine, mismatch,
suffix, and anchor suites cover source-list isolation and mutation rejection.
Durable database replacement, real product state selection, device/network
validation, other-platform hosts, release signing, and final UX remain
separate.

The T178 follow-up closes the variant-owned collection ownership gap. Variant
validation and hand-plan models, showdown inputs/results/projections, Hold'em
hand state and evaluation, transition/coordinator results, reducer/projection
results, settlement emissions, and settlement drafts now defensively copy and
freeze public collections, including nested showdown winner maps. A dedicated
ownership regression and the full `peerdeal_variants` suite cover source-list
isolation and mutation rejection. Durable database replacement, real product
state selection, device/network validation, other-platform hosts, release
signing, and final UX remain separate.

The T179 follow-up closes the wizard-owned collection ownership gap. Setup
intents, helper suggestions, resolved drafts, preset layers/results, validation
plans, and Game File compile results now defensively copy and recursively freeze
public JSON-like maps/lists/sets and diagnostic collections before they cross
the wizard boundary. A dedicated wizard ownership regression and the full
repository test matrix cover source-collection isolation and mutation
rejection. Durable database replacement, real product state selection,
device/network validation, other-platform hosts, release signing, and final
UX remain separate.

The T180 follow-up closes the crypto-owned verification collection gap.
`DealProofBundle` now owns normalized and raw proof maps, preserving one shared
immutable view when both inputs are the same bounded payload; verification
payload evidence/warnings and verification result layers are also defensively
copied at construction. Focused crypto ownership regressions, the full
repository test matrix, both app builds, and the native-host smoke gate pass.
Provider-specific proof semantics, product verification wiring, durable
database replacement, device/network validation, other-platform hosts, release
signing, and final UX remain separate.

The T181 follow-up closes the receipt-owned collection ownership gap. Receipt
scan results, export artifacts, export inspection results, and retained signing
or encryption key provider collections now defensively copy and recursively
freeze caller-owned maps/lists at construction. The focused receipt suite (54
tests), full repository gates, both app builds, and the native-host smoke gate
pass. Platform-secure storage, provider-specific proof semantics, product
verification wiring, durable database replacement, device/network validation,
other-platform hosts, release signing, and final UX remain separate.

The T182 follow-up closes the remaining core state and settlement collection
ownership gap. `TableState` now recursively freezes caller-owned metadata,
`PotSlice` owns its contested-seat list, and `SettlementResult` owns slices,
awards, ledger deltas, and warnings at construction. Focused core ownership
coverage, the full `peerdeal_core` suite, the repository gates, both app builds,
and the Windows native-host smoke pass. Product state provisioning, durable
database replacement, device/network validation, other-platform hosts, release
signing, and final UX remain separate.

The T183 follow-up closes the configurable reducer-policy ownership gap.
`CoreReducer()` retains the immutable baseline guard set, while
`CoreReducer.withInvariantGuards(...)` snapshots caller-supplied guards into an
unmodifiable collection before deterministic projection. Focused core tests,
the full repository gates, both app builds, and the Windows native-host smoke
pass. Product state provisioning, durable database replacement, device/network
validation, other-platform hosts, release signing, and final UX remain
separate.

The T184 follow-up closes the protocol wire-model collection ownership gap.
Command, event, and snapshot envelope constructors now recursively freeze
caller-owned payload trees, custom catalogs use an explicit owned-entry
constructor, and lock reports own their error lists. Focused protocol tests,
the full repository gates, both app builds, and the Windows native-host smoke
pass. Product state provisioning, durable database replacement, device/network
validation, other-platform hosts, release signing, and final UX remain
separate.

The T163 follow-up closes the app-owned receipt key-ring text-boundary gap.
Mirrored receipt key-ring loaders and writers now reuse the locked native
secure-key UTF-8 validator and byte limits for namespaces, key IDs, and
secrets, rejecting C1-bearing or oversized values before native load, delete,
save, or receipt-key projection. Focused mobile and desktop receipt suites
cover C1 and byte-oversized namespace rejection. Full repository gates remain
required; Android and Windows runtime key-store validation, device/network
validation, product state/database provisioning, other-platform hosts, and
release signing remain separate.

The T162 follow-up closes the remaining app-owned production-session peer
identity boundary gap. Mirrored local identity loaders and writers, persisted
Hold'em route policies, and production-session factories now reuse the shared
256-byte safe UTF-8/control-free validator before native identity save, dynamic
peer override, or route construction. C1-bearing and UTF-8-byte oversized peer
identities fail closed. Focused mobile and desktop identity, route-policy, and
factory suites cover the boundary. Full repository analyze, boundary,
source-text, dependency-audit, test, and diff gates remain required. Android
and Windows runtime/network validation, other-platform hosts, product
state/database provisioning, and release signing remain separate.

The T161 follow-up closes the Hold'em projection-publisher peer boundary gap.
Mirrored app publishers now reuse the shared 256-byte safe UTF-8/control-free
validator before handing canonical projection frames to the sender, rejecting
empty, padded, C0/C1-control-bearing, or oversized local/remote peer identities.
Focused mobile and desktop Hold'em runtime suites cover rejection before sender
calls. Full repository analyze, boundary, source-text, dependency-audit, test,
and diff gates pass. Android and Windows runtime/network validation,
other-platform hosts, product state/database provisioning, and release signing
remain separate.

The T160 follow-up closes the native readiness secure-key namespace gap.
Mirrored app-native readiness loaders now reuse the shared 128-byte safe UTF-8
validator before secure-key storage lookup, rejecting empty, padded,
C0/C1-control-bearing, or oversized namespaces before an injected bridge call.
Focused mobile and desktop readiness suites cover rejection before native
storage invocation. Full repository analyze, boundary, source-text,
dependency-audit, test, and diff gates pass. Android and Windows runtime/network
validation, other-platform hosts, product state/database provisioning, and
release signing remain separate.

The T159 follow-up closes the native transport source/provisioner scope gap.
Mirrored app transport sources and provisioners now reuse the shared native
bridge safe UTF-8 validator before source start, polling, or capability lookup,
rejecting empty, padded, C0/C1-control-bearing, or over-256-byte session and
peer scopes. Focused mobile and desktop source/provisioner suites cover the
lifecycle boundary. Full repository analyze, boundary, source-text,
dependency-audit, test, and diff gates pass. Android and Windows runtime/network
validation, other-platform hosts, product state/database provisioning, and
release signing remain separate.

The T158 follow-up closes a direct native transport send-model boundary gap.
Mirrored app-native transport sinks now validate converted `NativeTransportFrame`
values before invoking an injected native bridge, so the trim-only network
validator cannot bypass native UTF-8/control, identity, sequence, or payload
invariants. Focused mobile and desktop transport-adapter suites cover C0, C1,
and oversized identity rejection before native send. Full repository analyze,
boundary, source-text, dependency-audit, test, and diff gates pass. Android and
Windows runtime/network validation, other-platform hosts, product state/database
provisioning, and release signing remain separate.

The T157 follow-up closes a direct native transport receive-scope boundary gap.
Mirrored app transport drains now reuse the shared native bridge safe UTF-8
validator before invoking an injected native bridge, rejecting empty, padded,
C0/C1-control-bearing, or over-256-byte session and peer scopes. Focused mobile
and desktop transport-adapter suites cover rejection before native receive.
Full repository analyze, boundary, source-text, dependency-audit, test, and
diff gates pass. Android/Windows runtime and cross-device network validation,
other-platform hosts, product state/database provisioning, and release signing
remain separate.

The T156 follow-up closes a native bootstrap output-boundary gap. Mirrored join
bootstrap coordinators now apply the configured peer candidate cap to reachable
results returned by the injected provider, normalize and deduplicate provider
peer IDs, and pass only the bounded safe list into `BootstrapPlan`. Focused
mobile and desktop native-bootstrap suites cover provider output capacity and
normalization. Full repository analyze, boundary, source-text, dependency-audit,
test, and diff gates pass. Android debug, Windows debug, and Windows native-host
smoke builds and smoke validation pass. Product state provisioning, durable
database replacement, device/network validation, other-platform hosts, and
release signing remain separate.

The T155 follow-up closes an unbounded recovery-failure queue. Mirrored snapshot
coordinators now retain at most 64 failed checkpoints by default, accept a
positive caller-owned pending-checkpoint limit, and fail closed with a stable
queue-full warning when that limit is reached. Configuration factories pass the
same limit into the coordinator. Focused mobile and desktop coordinator and
configuration suites cover queue capacity and invalid-limit failure. Product
state provisioning, durable database replacement, device/network validation,
other-platform hosts, and release signing remain separate. Full repository
analyze, boundary, source-text, dependency-audit, test, and diff gates pass.
Android debug, Windows debug, and Windows native-host smoke builds and smoke
validation pass.

The T154 follow-up closes the snapshot coordinator recovery-bound mismatch.
Mirrored snapshot coordinators now enforce the configured recovery-event limit
before copying event suffixes or entering persistence, and configuration
factories pass one validated limit into both the persistence writer and
coordinator. Focused mobile and desktop coordinator/configuration suites cover
the bound and invalid-limit failure. Full repository gates plus Android debug,
Windows debug, and Windows native-host smoke validation pass. Product state
provisioning, device/network validation, other-platform hosts, and release
signing remain separate.

The T153 follow-up closes the snapshot serialization preflight boundary.
Mirrored snapshot writers now canonical-encode typed snapshots during
validation before appending event suffixes; serialization and hashing failures
return stable persistence results and cannot leave durable event state without
a snapshot checkpoint. Focused mobile and desktop persistence-writer and
snapshot-writer suites cover unsupported snapshot metadata. Full repository
analyze, boundary, source-text, dependency-audit, test, and diff gates pass.
Android debug, Windows debug, and Windows native-host smoke builds and smoke
validation pass. Product state provisioning, device/network validation,
other-platform hosts, and release signing remain separate.

The T152 follow-up closes the snapshot-ID factory failure boundary. Mirrored
production snapshot coordinators now invoke caller-owned snapshot-ID factories
inside the serialized checkpoint queue; factory exceptions fail closed with a
stable persistence warning, update the last result, and do not create pending
or durable state. Focused mobile and desktop snapshot coordinator suites cover
the failure. Full repository analyze, boundary, source-text, dependency-audit,
test, and diff gates pass. Android debug, Windows debug, and Windows
native-host smoke builds and smoke validation pass. Product state provisioning,
device/network validation, other-platform hosts, and release signing remain
separate.

The T151 follow-up closes the transport provisioning cancellation race.
Mirrored transport provisioners now recheck route cancellation after native
session creation and before returning an available session/source, so
cancellation during session creation fails closed instead of exposing a source
to a replaced route. Focused mobile and desktop provisioner, source,
transport-drain, and session-factory suites cover the race. Full repository
analyze, boundary, source-text, dependency-audit, test, and diff gates pass.
Android debug, Windows debug, and Windows native-host smoke builds and smoke
validation pass. Product state provisioning, device/network validation,
other-platform hosts, and release signing remain separate.

The T150 follow-up closes the standalone source lifecycle gap. Mirrored
transport sources now expose an additive cancellable drain callback and
complete its signal on source disposal or external route cancellation; native
session factories use it to prevent disposed source mounts from leaving
in-flight native receives active. Focused mobile and desktop source,
transport-drain, and session-factory suites cover disposal propagation. Full
repository analyze, boundary, source-text, dependency-audit, test, and diff
gates pass. Android debug, Windows debug, and Windows native-host smoke builds
and smoke validation pass. Product state provisioning, device/network
validation, other-platform hosts, and release signing remain separate.

The T185 follow-up closes mode policy collection ownership. `GovernanceContext`
now snapshots participant, seat, and waitlist input collections;
`GovernanceDecision` snapshots next-ordering and note collections; and
`ValidationResult` snapshots warning and error collections. Focused
`peerdeal_modes` validation passed 28 tests and package analysis. Full
repository analyze, boundary, source-text, dependency-audit, test, and diff
gates pass. Android debug, Windows debug, and Windows native-host smoke builds
and smoke validation pass. Product state provisioning, device/network
validation, other-platform hosts, and release signing remain separate.

The T186 follow-up closes shared UI collection ownership. `SafeSurfaceRenderModel`
now snapshots warning and native-note lists, and `PeerDealAppScaffold` snapshots
action-widget lists at construction. Focused `peerdeal_ui_kit` validation passed
11 tests; the mirrored mobile and desktop app packages analyze cleanly. Full
repository analyze, boundary, source-text, dependency-audit, test, and diff
gates pass. Android debug, Windows debug, and Windows native-host smoke builds
and smoke validation pass. Product visual/accessibility/navigation validation,
product state provisioning, device/network validation, other-platform hosts,
and release signing remain separate.

The T187 follow-up closes mirrored app join-flow collection ownership.
`RoleGrant` now snapshots authorization permissions, `BootstrapPlan` snapshots
reachable peer candidates, and `JoinFlowOutcome` snapshots protocol diagnostics
before exposing accepted or rejected join state. Focused mobile and desktop join
flow suites passed 46 tests each, including ownership regressions. Full
repository analyze, boundary, source-text, dependency-audit, test, and diff
gates pass. Android debug, Windows debug, and Windows native-host smoke builds
and smoke validation pass. Product state provisioning, device/network
validation, other-platform hosts, release signing, and final navigation/UX
validation remain separate.

The T188 follow-up closes mirrored app runtime configuration ownership.
`PeerDealMobileRuntime` and `PeerDealDesktopRuntime` now snapshot join/setup
mode gates, enabled demo paths, production route maps, production navigation,
and native-readiness route gates at construction; `withOverrides` applies the
same snapshot boundary to replacement collections. Focused mobile and desktop
runtime ownership tests passed, and both full app-shell suites passed. Full
repository analyze, boundary, source-text, dependency-audit, test, and diff
gates passed. Android debug, Windows debug, and Windows native-host smoke
validation also passed, including all 16 native-host smoke markers. Product
state provisioning, device/network validation, other-platform hosts, release
signing, and final navigation/UX validation remain separate.

The T189 follow-up closes mirrored app output collection ownership.
`SetupFlowOutcome` now deep-freezes compiled Game File maps and snapshots
setup errors and warnings; `SafeReceiptScanVm` deep-freezes nested shareable
receipt fields, and `SafeRecoveryVm` snapshots protocol diagnostics before
exposing safe-surface state. Focused mirrored setup, safe-projection, and
receipt-screen suites passed 30 tests each, and both app packages analyze
cleanly. Full repository analyze, boundary, source-text, dependency-audit,
test, and diff gates passed. Android debug, Windows debug, and Windows
native-host smoke validation also passed, including all 16 native-host smoke
markers. Product state provisioning, durable database replacement,
device/network validation, other-platform hosts, release signing, and final
navigation/UX validation remain separate.

The T190 follow-up closes mirrored route and home-policy collection ownership.
`JoinFlowRoute` and `SetupFlowRoute` now snapshot their enabled mode sets at
construction, and `DemoHomeScreen` snapshots demo and production navigation
action lists before rendering. Focused mobile and desktop route suites passed
36 tests each, including ownership regressions. Full repository gates and
Android/Windows artifact validation passed. Android debug, Windows debug, and
Windows native-host smoke validation passed, including all 16 native-host
smoke markers. Product state provisioning, durable database replacement,
device/network validation, other-platform hosts, release signing, and final
navigation/UX validation remain separate.

The T191 follow-up closes the remaining direct app warning-list ownership
leaks found in the mounted table path. Mirrored `DemoRecoveryPersistenceLoadResult`
constructors now snapshot available and unavailable recovery warning lists, and
the unavailable native transport sender owns its fallback warning list before
reusing it for rejected sends. Focused mobile and desktop demo-table plus
native-transport suites passed 23 tests each, including recovery ownership
regressions. Full repository gates, Android debug, Windows debug, and Windows
native-host smoke validation passed, including all 16 native-host smoke
markers. Product state provisioning, durable database replacement,
device/network validation, other-platform hosts, release signing, and final
navigation/UX validation remain separate.

The T192 follow-up closes the Android multicast permission deployment gap. The
mobile manifest now declares the existing native transport's required Wi-Fi
state and multicast-state permissions alongside `INTERNET`, so the Android
host can acquire its bounded multicast lock on real devices. The Android debug
APK build passed after the manifest change. Real-device permission/runtime
behavior, cross-device reachability, release signing, and the remaining
product-state/database work remain separate.

The T193 follow-up closes the Android native transport teardown delivery gap.
Transport work that completed after handler closure could previously post its
stale success payload on the main looper. Delivery now re-checks closure and
returns the operation-specific unavailable payload for capability, send, and
receive calls, matching the secure-key handler's fail-closed lifecycle rule.
The Android debug APK build passed after the change. Real-device engine
teardown behavior, cross-device reachability, release signing, and the
remaining product-state/database work remain separate.

The T194 follow-up closes the Android multicast-readiness false-positive gap.
The Android receiver now requires a created and held `WifiManager.MulticastLock`
before publishing transport availability; missing or unheld multicast state
closes the receiver instead of claiming receive support. The Android debug APK
build passed after the change. Real-device lock behavior, cross-device
reachability, release signing, and the remaining product-state/database work
remain separate.

The T195 follow-up closes the Android native receive-queue concurrency gap.
Receive drain/requeue now shares the receiver lifecycle lock, preventing
concurrent arrivals from reordering drained frames or bypassing the bounded
512-frame queue invariant. Closed receivers return the existing unavailable
receive fact. The Android debug APK build passed after the change; real-device
transport behavior and cross-device reachability remain separate.

The T196 follow-up closes the app-owned pending-checkpoint resource gap.
Mirrored Hold'em snapshot coordinators now bound queued failed checkpoints by
both count and the serialized typed-state/event byte budget, reject invalid
byte-budget configuration, and release tracked bytes on successful retry or
terminal discard. FIFO retry ordering and the existing event-plus-snapshot
write policy are unchanged. This bounds coordinator-held recovery data; it does
not replace product-owned durable database persistence.

The T197 follow-up closes two Android native transport teardown boundaries.
Malformed receive requests are validated before receiver initialization, so
untrusted method calls cannot allocate multicast resources. Android sends now
recheck the closed state under the lifecycle lock while emitting, preventing an
in-flight send from publishing after engine teardown. The focused Android
contract test and debug APK build pass; real-device transport behavior,
cross-device reachability, and release signing remain separate.

The T198 follow-up closes the remaining app-owned first-join state-context gap.
Mirrored mobile and desktop persisted Hold'em sources and configuration
factories now accept an optional context-aware initial snapshot loader. When a
new accepted session has no recovery snapshot, that loader receives the exact
`JoinFlowSessionContext` containing the validated remote peer and local seat;
the existing invite-only loader remains the compatibility fallback. Snapshot
scope validation, identity ordering, checkpoint persistence, and fail-closed
errors are unchanged, with focused mobile and desktop source coverage. This
does not select product state, provide a durable database, or prove device,
network, signing, or other-platform readiness.

The T199 follow-up closes a concrete Android secure-key persistence defect.
Encrypted envelope writes now use same-filesystem POSIX replacement through
Android's supported `Os.rename` API, so an existing envelope is replaced
atomically instead of relying on `File.renameTo`, whose replacement behavior is
not guaranteed. This preserves the generic secure-key method-channel contract
and enables subsequent receipt-key updates and rotations after the first save.
Focused mobile receipt/key-ring suites and the Android debug APK build pass;
real-device secure-key persistence remains external validation.

The T200 follow-up closes a secure-key channel integrity gap. The shared
method-channel decoder now rejects malformed or duplicate native key records
as an unavailable snapshot instead of silently dropping records and exposing
partial key-ring state to receipt provisioning or verification. Focused native
bridge contract coverage, full repository gates, Android debug, Windows debug,
and Windows native-host smoke validation pass. Platform/device behavior,
other-platform storage, product state, and release signing remain separate.

The T202 follow-up closes mutable diagnostic payload leaks across protocol and
replay boundaries. `ProtocolDiagnostic` and `ReplayMismatch` now deep-freeze
nested expected/actual values at construction, and serialized diagnostic trees
remain immutable snapshots. Focused protocol, privacy, replay, mobile, and
desktop suites pass; product state, native/device, durable database, and
release-signing validation remain separate.

The T201 follow-up closes immutable-model leaks in the Hold'em settlement event
drafts. Projected, blocked, and completed settlement drafts now deep-freeze
payload trees, and projected award maps are independently owned before event
emission. Focused variant ownership and settlement-builder suites pass; native
platform, product state, durable database, and release-signing validation
remain separate.

The T203 follow-up closes a durable recovery-load fail-open gap. The sync file
and in-memory stores now expose an additive load-result contract, so invalid
scope, lock, corruption, size, and other read failures remain observable while
the legacy window projection stays compatible. Mirrored mobile and desktop
persisted Hold'em sources reject unsuccessful loads before initial snapshot or
identity provisioning. Focused sync, mobile, and desktop suites passed; full
analyze, boundary, source-text, test, dependency-audit, and diff gates passed;
Android debug APK and Windows debug artifacts built successfully. This does
not replace product-owned database persistence or prove native/device,
cross-device, other-platform, or release-signing readiness.

The T204 follow-up closes the remaining user-facing demo recovery read path.
Mirrored mobile and desktop demo table routes now consume the explicit sync
load-result contract and render recovery persistence as unavailable when a
stored window cannot be read, instead of projecting an empty window as zero
events. Focused mobile and desktop demo-table suites passed; full analyze,
boundary, source-text, test, dependency-audit, and diff gates passed; Android
debug APK and Windows debug artifacts built successfully. Native/device,
cross-device, product-state/database, other-platform, and release-signing
validation remain separate production-boundary work.

The T205 follow-up closes the app-shell production-session cancellation gap.
Mirrored mobile and desktop typed configuration loaders now accept route
cancellation, forward it through configuration and persisted local-identity
construction, and complete it when a load is superseded, disposed, rejected,
or successfully mounted. Stale configured loads therefore cannot continue
cancellable app-owned construction after the route handoff is no longer
valid; the mounted bootstrap route remains the owner of downstream native
identity/storage cancellation.
Focused mobile and desktop app-shell and configuration-factory suites pass;
full analyze, boundary, source-text, serialized test, dependency-audit, and
diff gates pass; Android debug APK and Windows debug artifacts build
successfully.
This does not supply product-owned state/database inputs or prove native/device,
cross-device, other-platform, or release-signing readiness.

The T206 follow-up closes the remaining app-native-readiness cancellation
traversal gap. Mirrored readiness loaders now check cancellation before and
between capability lookups, return the existing stable all-unavailable warning
projection, and avoid invoking later legacy non-cancellable bridges after a
stale loader is cancelled. An already-dispatched host call remains host-owned.
Focused mobile and desktop readiness suites pass; full analyze, boundary,
source-text, serialized test, dependency-audit, and diff gates pass; Android
debug APK and Windows debug artifacts build successfully.

The T207 follow-up closes the app-owned bootstrap scope boundary. Mirrored
mobile and desktop join coordinators now apply the shared native transport
identity UTF-8, control-character, and byte-size validator to direct
session/table scope inputs before native capability lookup, local discovery, or
provider resolution. Unsafe or oversized scope therefore preserves relay
fallback without crossing the app-owned native/network boundary. Focused
mobile and desktop bootstrap suites pass; full analyze, boundary, source-text,
serialized test, dependency-audit, and diff gates pass; Android debug APK and
Windows debug artifacts build successfully.

The T208 follow-up closes the app-owned hydrated-session identity boundary.
Mirrored mobile and desktop production-session factories now apply the shared
native transport UTF-8, control-character, and byte-size validator to hydrated
table, session, and protocol identities before constructing the app runtime,
persistence, or native transport route. Focused mobile and desktop
production-factory suites pass; full analyze, boundary, source-text,
serialized test, dependency-audit, and diff gates pass; Android debug APK and
Windows debug artifacts build successfully.

The T209 follow-up closes the app-owned snapshot metadata text boundary.
Mirrored mobile and desktop Hold'em snapshot writers now reject C0/C1/DEL
controls and text exceeding the protocol canonical-JSON 4,096-byte limit for
snapshot IDs, types, and versions before persistence. Focused mobile and
desktop snapshot-writer suites pass; full repository gates and debug artifact
builds pass: analyze, boundary, source-text, serialized test,
dependency-audit, and diff gates are green; Android debug APK and Windows
debug artifacts build successfully.

The T210 follow-up closes the app-owned snapshot coordinator pre-queue
identity boundary. Mirrored mobile and desktop coordinators now apply the
writer's snapshot metadata validator to factory-produced snapshot IDs before
checkpoint byte measurement, persistence, or pending-queue insertion. Unsafe
or oversized IDs therefore cannot consume retry budget or cause repeated
store attempts. Focused mobile and desktop coordinator suites pass; full
analyze, boundary, source-text, serialized test, dependency-audit, and diff
gates pass; Android debug APK and Windows debug artifacts build successfully.

The T211 follow-up closes the app-owned recovery-window budget and metadata
propagation gap. Mirrored snapshot coordinators now measure the canonical
persisted recovery window, including the complete snapshot envelope and event
JSON, rather than an optimistic payload-plus-wire estimate. They also carry
configured snapshot type and version through measurement and persistence, with
unsafe configured metadata rejected before queueing. Focused mobile and
desktop coordinator and configuration-factory suites pass; full repository
gates and debug artifact builds pass: analyze, boundary, source-text,
serialized test, dependency-audit, and diff gates are green; Android debug APK
and Windows debug artifacts build successfully.

The T212 follow-up closes the app-owned persisted snapshot read boundary.
Mirrored production session sources now validate stored snapshot IDs, types,
and versions with the same bounded metadata rule used by snapshot writers,
before snapshot hydration, replay, or local identity provisioning. Malformed
legacy or externally supplied recovery metadata therefore fails closed at the
app boundary. Focused mobile and desktop persisted-source suites pass; full
repository gates and debug artifact builds pass: analyze, boundary,
source-text, serialized test, dependency-audit, and diff gates are green;
Android debug APK and Windows debug artifacts build successfully.

The T213 follow-up closes the shared persistence snapshot-integrity gap.
In-memory and JSON-file recovery stores now validate snapshot canonical JSON and
payload hashes before mutating a recovery window or hydrating durable data.
Tampered or unencodable snapshots therefore fail closed consistently with the
existing conflict-detector and snapshot-applier contracts. Focused sync,
mobile, and desktop persisted-source suites pass; full repository gates and
debug artifact builds pass: analyze, boundary, source-text, serialized test,
dependency-audit, and diff gates are green; Android debug APK and Windows
debug artifacts build successfully. Product-owned database persistence,
native/device, cross-device, other-platform, and release-signing validation
remain separate.

The T214 follow-up closes the generic crypto verification input boundary.
`DefaultVerificationEngine` now rejects unsafe or oversized request identity and
anchor text, invalid positive ordered event windows, hand-scoped requests
without a hand identity, and provider proof metadata or maps that exceed the
configured `DealProofLimits`. The normalizer applies the same safe-text rule to
provider ID, version, and reference while preserving bounded arbitrary proof
JSON text. Malformed inputs return a scrubbed `errVerificationDataIncomplete`
result before evidence projection, without echoing untrusted values. Focused
crypto coverage passes. Provider-specific proof semantics, product
verification wiring, real device/network validation, durable database
persistence, other-platform hosts, and release signing remain separate.

The T217 follow-up closes the remaining public-input traversal gap in the
endpoint boundary. `parseAll` now bounds inspection of caller-provided
discovery values, and `projectCandidates` bounds both endpoint and candidate
iterables before producing an immutable projection. Malformed or excess
values therefore cannot force unbounded traversal through the network API.

The T218 follow-up closes the mirrored demo bootstrap duplication gap. Mobile
and desktop `NativeBootstrapCandidateLoader` now use the same bounded
`peerdeal_network` endpoint parser and metadata projector as the production
join path, with the native bridge's 64-entry discovery budget applied before
provider resolution. Interface-hint normalization is bounded at the same
boundary, so mounted demo bootstrap cannot bypass the shared endpoint rules
or traverse an oversized direct caller collection. Native discovery
advertisement and real endpoint provisioning remain separate.

The T219 follow-up closes the remaining demo-bootstrap scope boundary. Mirrored
mobile and desktop loaders now require session and table identities to satisfy
the shared safe UTF-8 transport-identity limit before any native capability
lookup or provider resolution. Control-bearing, padded, empty, or oversized
scope values fail closed consistently with the production join coordinator.

The T220 follow-up closes the direct demo-table result materialization gap.
Mirrored bootstrap and recovery result models now cap candidates, warnings,
and persisted-event display counts at construction, preserve stable truncation
markers, and normalize negative counts to zero. Screen-level scrubbing remains
in place, but direct callers can no longer bypass the app-owned collection and
counter budgets before rendering.

The T221 follow-up closes the mirrored transport-result warning boundary.
Native frame-drain, transport-source, and transport-provision result models now
scrub control-bearing, padded, and oversized warning text at construction,
bound warning collections to four entries, and preserve explicit truncation
markers. Lower-layer markers are translated at the source boundary so callers
receive stable source-level diagnostics without retaining unbounded bridge
payloads.

The T222 follow-up extends that warning boundary through native transport
session loading. Mirrored session-factory load results and unavailable sender
models now apply the same text and collection limits before warnings reach the
provisioner or transport source, preserving fail-closed behavior for direct
callers without changing the generic native bridge contract.

The T223 follow-up closes the native-readiness aggregate warning boundary.
Mirrored `AppNativeReadinessSnapshot` construction now applies the same
control-free text and four-entry collection budget to direct callers while
preserving the loader's stable capability warning vocabulary.

The T224 follow-up closes the local identity result warning boundary. Mirrored
load and provision result constructors now scrub unsafe warning text and cap
direct warning collections at four entries with stable labels, before identity
diagnostics reach persisted-session composition or route surfaces.

The T225 follow-up closes the receipt key-ring load and provision warning
boundary. Mirrored receipt result constructors now scrub control-bearing,
padded, and oversized warning text and cap direct warning collections at four
entries with stable lower-layer markers. The receipt artifact verifier
translates those markers back to its stable public diagnostic vocabulary while
preserving fail-closed signing and encryption-key behavior; the generic native
secure-key bridge remains receipt-agnostic.

The T226 follow-up closes the production-session configuration warning
boundary. Mirrored `AppHoldemProductionSessionConfigurationLoadResult`
constructors now scrub control-bearing, padded, and oversized warning text and
cap direct warning collections at four entries before configuration failures
reach app-shell route loading. The existing app-owned source, recovery store,
identity, and route policy seams remain unchanged. The workspace also aligns
its existing Melos dev dependency to the newest resolvable 8.3.0 release.

The T227 follow-up closes the projection-publish result warning bypass.
Mirrored `AppHoldemProjectionPublishResult` constructors now route direct
warning input through the publisher's existing control-free, padded, length,
and four-entry sanitizer before exposing immutable diagnostics. This hardens
the app-owned transport result boundary without changing projection events,
transport contracts, variant rules, or session truth ownership.

The T228 follow-up closes the remaining app-session result warning bypass.
Mirrored `AppTableSessionEventResult`, `AppTableSessionEventBatchResult`, and
`AppHoldemInboundEventResult` constructors now apply bounded control-free
warning sanitization, preserve stable truncation markers, and expose immutable
diagnostics. Universal and Hold'em runtime behavior, reducer ownership, event
identity, and transport contracts remain unchanged.

The T229 follow-up closes the remaining raw app diagnostic constructors.
Mirrored `SetupFlowOutcome` constructors now apply the existing four-entry
setup token policy to direct errors and warnings, while
`AppRecoveryPersistenceStoreLoadResult` applies bounded control-free recovery
warning handling with a stable truncation marker. Setup orchestration, recovery
storage, and route ownership remain unchanged.

The T230 follow-up closes a release-build configuration invariant gap. Public
limit-bearing services in `peerdeal_core`, `peerdeal_sync`,
`peerdeal_network`, `peerdeal_variants`, `peerdeal_modes`, and
`peerdeal_wizard` now validate positive limits at their operational entry
points instead of relying only on Dart `assert`, which is removed from release
builds. Receipt key-ring constructors now perform the same explicit
`ArgumentError` validation. Existing `const` constructors, bounded result
codes, package boundaries, event truth ownership, and native contracts remain
unchanged.

Verification:
- Focused release-configuration tests passed for core, network, sync, variants,
  modes, and wizard; receipt signer and key-ring snapshot regressions passed.
- Full `melos run analyze`, `boundary-check`, `source-text`, and serialized
  `test` gates passed.
- Dependency audit passed with 0 actionable upgrades and 11 newer versions
  below the current toolchain ceiling.
- Android debug APK and Windows debug builds passed; `git diff --check` passed.

The T231 follow-up removes CI/toolchain drift. GitHub Actions now activates
the same Melos `8.3.0` baseline declared by the root workspace and lockfile,
and the stable AI repository brief reports that same version. This changes no
package boundary or runtime behavior; it keeps CI orchestration aligned with
the local production gate commands.

The T232 follow-up closes three source-backed fail-closed gaps without changing
the protocol or native bridge contracts. Mirrored app production routes now
carry the local recipient identity separately from the remote peer identity;
native receive filtering uses the local identity, and configured app handlers
reject frames whose sender or recipient does not match the route. Event
decoding stops consuming an iterable once the protocol byte limit is exceeded.
Core `SessionWiped` now requires a prior `SessionClosed` event, and inbound
Hold'em `SettlementProjected` awards must be non-empty and conserve the current
pot. These checks do not provide cryptographic peer authenticity; that remains
an explicit protocol/session-auth contract gap rather than an invented wire
extension.

The T233 follow-up closes the mirrored app-surface transport replacement race.
A pending Hold'em projection is now bound to the transport session/source that
created it. Replacing that transport invalidates the surface operation
generation and pending projection before the old send can complete, so a stale
completion cannot publish through the replacement session or duplicate events.
Focused mobile and desktop route regressions pass; protocol, native bridge,
runtime state, and transport contracts remain unchanged.

The T234 follow-up closes the production-session bootstrap cancellation gap.
Mirrored mobile and desktop bootstraps now give each source load an idempotent
app-owned cancellation signal. Caller cancellation and the configured source
timeout both complete that signal before the bootstrap fails closed, allowing
source implementations to stop pending persistence or native work instead of
continuing after the route handoff has ended. Focused bootstrap regressions
pass, as do the full repository gates and Android/Windows debug builds;
the Windows native-host smoke gate also passes; source-owned persistence and
device behavior remain separate.

The T235 follow-up closes the mirrored transport-source cancellation leak.
External route cancellation now stops an active source timer, marks the source
unavailable for restart, and rejects later polls before another native drain is
started. An already-running cancellable or legacy drain remains host-owned
until it settles. Focused mobile and desktop source regressions pass; transport
contracts and native host implementations remain unchanged.

The T236 follow-up closes the persisted-source initial-checkpoint cancellation
race. Mirrored mobile and desktop sources now check route cancellation before
calling the existing typed snapshot coordinator and after that checkpoint
settles, so a cancelled load never returns a production session input. An
already-started checkpoint remains owned by the persistence boundary until it
settles; no package, snapshot, or native bridge contract changed.

The T237 follow-up hardens the Windows native-host smoke gate itself. Once the
smoke key is written, the harness now removes it from a terminal cleanup path
when a later assertion fails, preventing failed validation from leaving test
credentials in the host key store. The native secure-key contract and host
implementation remain unchanged.

The T238 follow-up closes the production table surface action-ordering gap.
Mirrored mobile and desktop surfaces now block local hand starts and actions
while a projection or snapshot checkpoint is pending, leaving the existing
retry controls as the only mutation path until the older work clears. This
preserves app-local event ordering without changing core, protocol, sync, or
native bridge ownership.

The T239 follow-up closes the shipped-app receipt startup wiring gap. Mirrored
mobile and desktop executable entrypoints now provide the existing native-backed
receipt export and artifact-verifier factories by default, so the mounted receipt
route uses native key provisioning and verification without requiring a separate
caller injection. Tests and explicit product integrations can still override the
app-owned factories; the generic native bridge and receipt policy boundaries are
unchanged.

The T240 follow-up closes the queued stale-checkpoint gap in the mirrored
production table surfaces. A local projection whose route is replaced before
the serialized snapshot callback runs now returns without writing stale typed
state into recovery storage, while existing post-await generation checks still
prevent publication through the replacement transport. Focused mobile and
desktop route regressions and the full repository gates pass; Android debug,
Windows debug, and all 16 Windows native-host smoke markers also pass.
Already-running store calls remain owned by the existing persistence boundary,
and no sync acknowledgement or outbound durable queue was invented.

The T241 follow-up closes the mirrored inbound-event version of that gap.
`AppHoldemTableSessionRoute` now binds accepted remote-event checkpointing to
the current transport lifecycle generation, so a replaced route cannot queue
stale inbound state after its callback has been invalidated. Deterministic
mobile and desktop coordinator and route regressions pass; protocol, sync, and
native contracts remain unchanged.

The T216 follow-up closes the app-owned bootstrap endpoint handoff gap. The
network boundary now parses the existing `peer-id` and `peer-id@host[:port]`
discovery values into bounded typed endpoint metadata, and mirrored mobile and
desktop join coordinators retain the selected `BootstrapCandidate` through
`BootstrapPlan`, `JoinFlowSessionContext`, and the safe route boundary. Provider
endpoint metadata remains authoritative when present, malformed locations fail
closed, and bare peer IDs remain compatible. Native discovery advertisement,
real endpoint provisioning/reachability, product state, other-platform hosts,
and release signing remain separate.

The T215 follow-up closes the replay snapshot trust and reconstruction gap.
`BasicReplayEngine` now recomputes canonical snapshot payload hashes, rejects
negative snapshot base sequences, and requires the optional
`ReplaySnapshotStateProjector` contract before applying a verified contiguous
suffix. Snapshot replay therefore hydrates typed product state through the
projector boundary instead of silently discarding the snapshot and rebuilding
from a fresh base state. Tampered snapshots and projectors without snapshot
hydration fail closed with stable mismatch codes; no-snapshot replay remains
compatible. Product-owned snapshot payload interpretation, durable database
persistence, device/network validation, other-platform hosts, provider-specific
proof semantics, release signing, and final UX remain separate.

The T250 follow-up aligns the mirrored app diagnostic and safe-display text
boundary. Native readiness, transport, recovery, receipt-key, local-identity,
session, route, safe-surface, bootstrap, join, and demo display helpers now
reject or scrub C0/C1 control-bearing text consistently before app UI, route
composition, or app-owned handoff. This preserves the original app/package
boundaries and does not claim native platform reachability, product state, or
durable database behavior.

The T249 follow-up aligns the mirrored app production-session text boundary.
Bootstrap invite identities, persisted route-policy paths and labels, and final
production route metadata now reject blank, padded, and C0/C1-control-bearing
values before source handoff or native route composition. Mobile and desktop
focused session suites cover the new rejection paths. This preserves app-owned
source/state policy and does not claim a concrete product source, database, or
device validation.

The T248 follow-up aligns the remaining protocol/core text boundary. Invite
required text and core command/scope identities now reject blank, padded, and
C0/C1-control-bearing values at their existing package-owned validation seams,
matching native, network, and variant boundary policy while preserving existing
diagnostics and wire shape. This remains structural validation only; it does
not add cryptographic session authentication or product persistence.

The T244 follow-up closes the invite payload structural-validation gap.
`InvitePayloadSchema` now rejects present required fields that are not safe,
non-empty strings, rejects unsupported `mode_type` values, and retains the
existing role-hint allowlist. This is protocol shape validation only; signature
verification and cryptographic session authentication remain explicit product
or protocol contracts.

The T265 follow-up closes the secure-key mutation-result integrity gap at the
generic channel and mirrored app writer boundaries. Negative expected
revisions fail before native mutation, negative returned revisions cannot be
reported as successful writes, and malformed successful channel payloads fail
closed. Nullable revisions remain compatible for legacy non-CAS bridges. This
preserves the existing secure-storage contract and app-owned receipt/identity
boundaries; native persistence atomicity, real-device validation, product
database wiring, session authentication, release signing, and final UX remain
separate.

The T264 follow-up closes the remaining secure-key consumer integrity gap at
the generic channel and mirrored app read boundaries. Available snapshots now
cannot carry negative revisions or unusable records into receipt-key or local
identity projection, even when a custom app bridge bypasses the generic
decoder. Receipt namespace validation is aligned with the existing native
secure-storage separator policy. This preserves the generic native bridge and
app-owned receipt/identity boundaries; native persistence atomicity,
real-device validation, product database wiring, session authentication,
release signing, and final UX remain separate.

The T266 follow-up closes the negotiated transport payload-boundary gap in the
mirrored app session factories. A loaded session now applies the native
capability's validated payload ceiling to both its sender and receiver while
preserving any injected app validator rules. This prevents custom bridge
implementations from accepting outbound or inbound frames larger than their
reported native capability without changing protocol, network, or native
channel ownership. Flutter-focused execution remains locally runner-blocked;
real-device reachability, release signing, product state/database wiring,
session authentication, other-platform hosts, and final UX remain separate.

The T267 follow-up closes the remaining app-side conditional secure-key revision
regression gap. Mirrored local-identity and receipt-key writers now reject a
successful conditional mutation that reports a revision below the caller's
expected revision. Nullable revisions remain compatible for legacy non-CAS
bridges, and equal revisions remain valid for conditional no-op deletes. The
generic native bridge contract and package ownership remain unchanged; native
persistence atomicity, real-device validation, product state/database wiring,
session authentication, release signing, other-platform hosts, and final UX
remain separate.

The T268 follow-up closes a release-configuration gap in the network frame
validator. A non-positive `maxPayloadBytes` now fails at validation time even
when assertions are disabled, preventing invalid production configuration from
silently rejecting every frame as oversized. The existing const API, transport
contracts, and package ownership remain unchanged; native/device reachability,
session authentication, product state/database wiring, release signing,
other-platform hosts, and final UX remain separate.

The T269 follow-up closes the mirrored app transport provisioning configuration
gap. Invalid polling intervals now fail before native capability lookup instead
of producing an apparently available session whose source can only fail when
started. The existing source bounds, transport contracts, and package ownership
remain unchanged; native/device reachability, session authentication, product
state/database wiring, release signing, other-platform hosts, and final UX
remain separate.

The T270 follow-up closes an Android native secure-key revision-overflow gap.
Android secure-key save and delete mutations now reject revision exhaustion
explicitly before incrementing a signed `Long`, matching the existing Windows
host behavior and preserving the generic channel contract. The Android debug
host compiles successfully; device persistence and cross-process runtime
validation remain external.

The T271 follow-up closes an Android local-network resource-bound gap. Android
local-network capability inspection now caps per-interface address traversal at
the same 256-entry bound already used by the Windows host. Discovery remains
unsupported by contract; this change only bounds native interface inspection.

The T272 follow-up closes a false-negative app-shell readiness gap. Configured
production routes now use a route-critical readiness projection requiring
capture protection, native transport, and secure-key storage, while preserving
the existing all-capabilities projection for flows that require peer discovery.
This allows invite/context-based production routes to mount on hosts whose
discovery advertisement is intentionally unsupported without changing the
native channel or protocol contract.

The T273 follow-up closes a Windows Credential Manager size-bound gap. Windows
secure-key serialization now enforces the platform's 2,560-byte generic
credential blob limit instead of allowing records that `CredWriteW` must reject.
The generic secure-key channel and app package boundaries remain unchanged;
normal interactive-profile persistence and real-device validation remain
external runtime gates.

The T274 follow-up closes the adjacent Windows secure-key serializer arithmetic
gap. Individual fields larger than the complete platform blob limit are now
rejected before the bounded-size subtraction, preventing an unsigned-size
underflow during record serialization. The storage format and channel contract
remain unchanged.

The T275 follow-up closes a network metric-integrity gap. Confidence
classification and primary-peer election now fail closed when a peer supplies
negative duration or counter measurements, preventing malformed input from
improving a route score. Network ownership and the existing decision contract
remain unchanged.

The T276 follow-up closes a Windows native address-eligibility gap. Local
network capability and multicast interface selection now reject all loopback,
unspecified, broadcast, and IPv4 link-local/APIPA addresses, matching the
existing Android and Windows transport semantics before reporting a usable
network interface. The generic native channel remains unchanged.

The T277 follow-up closes the mirrored Android capability false-positive. Android
local-network availability and interface hints now require a usable IPv4
address, excluding any, loopback, and link-local addresses before advertising
host readiness. Existing multicast transport and method-channel contracts are
unchanged.

The T278 follow-up closes an Android native text-boundary mismatch. Transport
identities, secure-key fields, and app-support paths now require UTF-8
round-trip fidelity before byte limits or native persistence are applied,
matching the Windows host's invalid-UTF-8 rejection without changing any
method-channel fields or package boundary.

The T280 follow-up closes an Android transport argument-type parity gap. The
Android method-call decoder now accepts only `Int`/`Long` values for sequence
and payload bytes, matching the Windows `int32`/`int64` contract and failing
closed on fractional values instead of truncating them. The generic transport
channel and host-private envelope remain unchanged.

The T281 follow-up closes an Android persisted secure-key revision coercion
gap. Authenticated storage envelopes now require integer `Int`/`Long` revision
values; fractional, string, and null revisions fail closed, while legacy
envelopes without a revision continue to load as revision zero. The encrypted
storage format and generic channel contract remain unchanged.

The T282 follow-up restores the aggregate app test gate after the full Flutter
run exposed a stale mirrored receipt-loader expectation. Mobile and desktop
tests now assert the existing metadata-specific warning for malformed key
metadata; no production behavior or architecture changed.

The T283 follow-up closes a provider-proof identity coercion gap. The existing
crypto normalizer now requires exactly one supported proof-reference alias with
a string value; numeric, boolean, object, null, and duplicate alias values fail
closed instead of becoming proof identities through string coercion. The
provider proof boundary and package ownership remain unchanged.

The T284 follow-up closes a wizard policy-profile coercion gap. Policy values
from resolved setup fields now require safe, unpadded strings before entering
the typed `ValidatedSetupPlan`; numeric, null, blank, padded, and control-bearing
values fail validation instead of becoming profile identifiers through string
coercion. The wizard boundary and profile keys remain unchanged.

The T285 follow-up closes a direct Game File metadata gap. The existing
`DefaultGameFileCompiler` now rejects padded or control-bearing plan IDs and
policy profile keys/values before emitting a Game File. Canonical JSON bounds
remain in place, and the wizard compiler/result boundary is otherwise unchanged.

The T286 follow-up closes a privacy redaction bypass. The existing diagnostics
scrubber now redacts unsafe map keys, including sensitive keys with appended
control data, and replaces control-bearing diagnostic code/message text with
the stable truncation marker. Privacy ownership and diagnostic contracts remain
unchanged.

The T287 follow-up closes the remaining wizard selection coercion gap. The
existing preset resolver now requires bounded, UTF-8-safe, non-padded strings
for `mode_type` and `variant_id` before they become typed setup identifiers;
non-string and control-bearing values fail closed as unsupported. The wizard
mode and variant contracts remain unchanged.

The T288 follow-up hardens signed opaque receipt inspection. Required receipt
identifiers are now required to be bounded, UTF-8-safe, non-padded text without
C0/C1 controls before the verified payload is exposed. Artifact format,
signature handling, opaque payload semantics, and receipt package ownership
remain unchanged.

The T289 follow-up hardens the existing receipt key-material boundary. Signing
and encryption key IDs now reject empty, padded, oversized, colon-bearing,
malformed-UTF-8, and C0/C1 control-bearing values before they enter the
colon-delimited signature or cipher formats. Key-provider contracts and
cryptographic provider ownership remain unchanged.

The T290 follow-up closes a metadata minimization bypass caused by case-
variant field names. Existing device, IP, and personal-field stripping rules
now normalize keys before matching, so case variants cannot bypass the active
privacy profile. Metadata minimizer ownership and policy semantics remain
unchanged.

The T291 follow-up closes the matching case-variant bypass in diagnostics
redaction. Sensitive diagnostic field names are normalized for comparison while
safe original keys remain in the scrubbed shape. Scrubber limits, output shape,
and privacy package ownership remain unchanged.

The T292 follow-up hardens deterministic core state identity handling. Table
state hydration and baseline invariant guards now reject padded or control-
bearing table, session, protocol, and active-hand identities with explicit
unsafe-state violations. Core state ownership, reducer behavior, and package
boundaries remain unchanged.

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
   session/state source and local identity through the app-owned typed loader
   after first-join and rejoin handoff, using `snapshotWriter` for authoritative typed snapshot
   persistence where product inputs are available through the now-wired
   event-plus-snapshot coordinator and `persistenceWriter`, supplying event
   identity and snapshot IDs, and defining event-log policy and route policy;
   complete product state/route provisioning and navigation/UI validation while
   keeping native transport/device validation and durable database persistence
   separate.

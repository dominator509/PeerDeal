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
- Live transport, native OS implementations, production cryptographic key
  management, and durable platform persistence remain scaffold-level.
- App shells now mount demo, receipt, safe-surface, and join-flow routes, but
  runtime navigation still needs production UI and non-demo orchestration.
- App UI is not production-polished.

## Covered hardening slices
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
- Core reducer ingress now rejects whitespace-only event envelope identity,
  scope, timestamp, actor, and hash-chain fields before protocol-compatible
  events can mutate deterministic state.
- Replay full-window validation now uses the protocol-owned genesis hash marker
  and rejects windows that do not start at `event_seq` 1 or whose first event
  does not chain from genesis.
- Sync recovery conflict detection, snapshot apply, and recovery persistence
  now enforce the protocol-owned genesis hash for no-snapshot event windows and
  first persisted events.
- Canonical Hold'em settlement breadcrumb coverage now spans protocol fixtures,
  core metadata projection, replay through the core projector, and sync
  snapshot + suffix recovery.
- Hold'em variant coverage now spans betting-round completion through checked
  streets, showdown reveal, settlement preparation/projection, uncontested
  settlement, hand completion, and settlement event emission.
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
- Mounted app table routes now load native local-network bootstrap snapshots
  through an app-owned factory, map normalized discovery facts into
  `peerdeal_network` bootstrap candidate resolution, and fail closed when
  native capability, discovery, factory construction, or candidate resolution
  is unavailable.
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
- Platform-native secure storage, capture blocking, real local-network
  discovery, production transport, production database/platform persistence,
  and final production app UI cannot be completed inside the current ChatGPT
  project environment because they require native platform implementations,
  device/OS integration, and product design validation. The Dart contracts,
  shared app-shell UI primitives, app-owned receipt key
  provisioning/read/write mapping, file-backed recovery persistence seam,
  app-owned recovery store construction, exact environment-configured recovery
  root loading, app-owned recovery root validation, mounted recovery-window loading,
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
  locked for those follow-up implementations.

## Next production hardening order
1. Replace native bridge stubs with platform implementations that satisfy the
   locked method-channel contracts and return the normalized capability facts
   already covered by package tests.
2. Add platform-secure receipt key storage behind the existing key-ring,
   cipher, and signer contracts.
3. Build app flows on top of the stable public package APIs.

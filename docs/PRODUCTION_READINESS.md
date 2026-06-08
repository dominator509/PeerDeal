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
- Canonical Hold'em settlement breadcrumb coverage now spans protocol fixtures,
  core metadata projection, replay through the core projector, and sync
  snapshot + suffix recovery.
- Hold'em variant coverage now spans betting-round completion through checked
  streets, showdown reveal, settlement preparation/projection, uncontested
  settlement, hand completion, and settlement event emission.
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
- Network transport contracts now include a package-owned frame validation gate
  that fails closed on malformed session/peer identities, self-send frames,
  invalid sequence numbers, empty payloads, and oversized payloads before
  platform transport adapters send data.
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
- App shells now include app-owned native transport adapters that compose the
  generic native byte-frame bridge with `peerdeal_network` validating
  sender/receiver boundaries, so app transport sends and inbound drains cannot
  bypass network frame validation.
- App shells now include native transport session factories that default to
  `MethodChannelNativeTransportBridge` and only expose validated
  `peerdeal_network` sender/drain construction to app orchestration.
- Native transport session factories now fail closed during session loading
  unless native capability reports send and receive support, so app
  orchestration can reject unavailable platform transport before exposing
  validated send/drain handles.
- Native transport session factories now enforce app-owned payload limits
  against native capability claims, rejecting invalid or oversized native
  payload limits before exposing validated send/drain handles.
- Mounted app table routes now load native local-network bootstrap snapshots
  through an app-owned factory, map normalized discovery facts into
  `peerdeal_network` bootstrap candidate resolution, and fail closed when
  native capability, discovery, factory construction, or candidate resolution
  is unavailable.
- Mounted join-flow factories now use an app-owned native bootstrap coordinator
  instead of hard-coded fake peer candidates, mapping normalized local-network
  discovery into join `BootstrapPlan` inputs while preserving relay fallback
  when local discovery is unavailable.
- App-owned local-network bootstrap loaders and join coordinators now bound
  normalized native peer discovery before candidate resolution, warning or
  falling back safely when platform discovery is invalid or exceeds the app
  candidate limit.
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
- App demo receipt paths now map native secure key storage snapshots into
  receipt-owned key-ring providers before signed artifact verification.
- App demo receipt presenters can consume a verifier boundary that loads native
  key material and fails closed before projecting receipt UI.
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
- App shell mounted route maps now validate against the app-owned route
  registries at construction time, allowing only the explicit framework default
  route alias so mounted navigation cannot silently drift from the registry.
- Demo receipt presenters in both app shells can route signed receipt export
  artifacts through fail-closed verification before projecting safe receipt
  fields.
- Mounted app receipt routes receive artifact verifier factories from the app
  shell boundary, keeping method-channel construction out of receipt screens.
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
- App shells now fail closed for unknown route names with an explicit rejected
  route-unavailable surface instead of relying on default framework route
  errors.
- App route-unavailable surfaces now scrub unknown route diagnostics before UI
  rendering, dropping query/fragment detail and bounding displayed paths while
  preserving explicit rejected navigation outcomes.
- App receipt key-ring loaders now fail closed to an empty key ring when native
  secure key storage throws.
- App receipt key-ring writers now map receipt signing/encryption keys into
  generic native secure-key mutation records, fail closed before invalid
  save/delete requests, and keep receipt semantics out of
  `peerdeal_native_bridges`.
- App receipt key-ring provisioners now load native-backed receipt key rings,
  create missing active signing/encryption keys with secure random material,
  persist them through the app-owned writer boundary, and fail closed when
  native storage is unavailable or mutation fails.
- App receipt export artifact factories now provision native-backed receipt
  keys before signed/encrypted export, build signer/cipher adapters from the
  provisioned key ring, and fail closed when key provisioning is unavailable.
- Mounted app receipt routes can now receive app-owned receipt export artifact
  factories, generate signed/encrypted artifacts from deterministic route
  receipt inputs, and verify them through the same native-backed key boundary.
- Receipt export now fails closed to an unavailable artifact when signing or
  encryption adapters throw.
- Receipt import inspection now rejects signed artifacts when verifier adapters
  throw during signature verification.
- Opaque receipt export encoding now fails closed for direct callers when signer
  or cipher adapters throw.
- Receipt HMAC signature verification now fails closed when verification key
  lookup throws.
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
- Mounted app table routes now consume the app-owned recovery persistence
  factory when one is supplied, load the active scenario recovery window, and
  fail closed with an explicit warning when no platform persistence root is
  available.

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
  app-owned recovery store construction, environment-configured recovery root
  loading, mounted recovery-window loading, app-owned transport payload-limit
  enforcement, bounded app-owned table/join bootstrap mapping, app-owned
  capture diagnostic scrubbing, scrubbed route-failure diagnostics, and
  method-channel payload gates are locked for those follow-up implementations.

## Next production hardening order
1. Replace native bridge stubs with platform implementations that satisfy the
   locked method-channel contracts and return the normalized capability facts
   already covered by package tests.
2. Add platform-secure receipt key storage behind the existing key-ring,
   cipher, and signer contracts.
3. Build app flows on top of the stable public package APIs.

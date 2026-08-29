# Handoff Log

Use this for concise agent handoffs only.

### 2026-08-29 - Codex - Close Capture Cancellation Race

Summary:
- Mirrored app capture coordinators now re-check route cancellation after
  legacy capability lookup and before queued native blocking dispatch.
- Cancelled sensitive surfaces fail closed to visual obscuring without starting
  stale host blocking; release remains uncancelled so host blocking can clear.
- Regression coverage verifies both a late legacy capability result and a
  queued enable cancelled before dispatch.

Verification:
- Focused mobile and desktop capture suites: 11 tests passed each.
- Full analysis, boundary/source/native-contract, Dart, Flutter, and diff gates
  passed.
- The live dependency audit reports 9 resolvable upgrades; no dependency change
  is included in this focused hardening task.

Next reviewer:
Continue with documented device/native-platform, cross-device network,
product session-source, and release-signing gates without changing locked
boundaries.

### 2026-08-29 - Codex - Forward App Native Transport Cancellation

Summary:
- Mirrored app native transport session factories and frame adapters now forward
  the existing cancellation future to compatible bridges for capability, send,
  and receive operations.
- Pre-cancelled calls fail closed before native dispatch; legacy in-flight calls
  retain existing host-owned settlement and Dart late-result suppression.
- The receipt provisioning fast path avoids an unnecessary uncancelled async
  yield, and Hold'em controls remain reachable in narrow viewports.

Verification:
- Focused mobile and desktop transport suites: 45 tests passed each.
- Full analysis, boundary, source-text, native-contract, Dart, Flutter, direct
  dependency-resolution, and diff gates passed.
- The live dependency audit reports 9 resolvable upgrades; no dependency change
  is included in this focused hardening task.

Next reviewer:
Continue with documented device/native-platform, cross-device network, product
session-source, and release-signing gates without changing locked boundaries.

### 2026-08-29 - Codex - Make Receipt Key Provisioning Cancellation-Safe

Summary:
- Mirrored receipt key loaders and writers now check cancellation before
  invoking legacy secure-key bridges and after results return for load, save,
  and delete operations.
- Receipt key provisioning fails closed before generation, after mutation,
  conflict reload, and verification boundaries, and before returning key
  material; mirrored regressions cover pre-cancelled storage, late results,
  and generation cancellation.

Verification:
- Repository boundary, source-text, native-contract, checker-unit, and diff
  gates passed.
- Flutter analysis and focused Flutter execution remained unverified because
  both runners were silent during bounded attempts; no Flutter pass is claimed.

Next reviewer:
Continue with the documented real-device/native-platform and product-owned
session-source integration gates without changing locked package boundaries.

### 2026-08-29 - Codex - Align Native Readiness Payload Defaults

Summary:
- Mirrored `AppNativeReadinessLoader` defaults now reference the locked native
  transport payload ceiling instead of the self-rejecting 64 KiB value.
- The native contract checker enforces both readiness defaults, and mirrored
  readiness coverage exercises the full native payload ceiling.

Verification:
- Repository boundary, source-text, native-contract, checker-unit, and diff
  gates passed.
- Focused Flutter execution remained unverified because both runners were
  silent during bounded attempts; no Flutter pass is claimed.

Next reviewer:
Continue with the documented real-device/native-platform and product-owned
session-source integration gates without changing locked package boundaries.

### 2026-08-29 - Codex - Make Local Identity Provisioning Cancellation-Safe

Summary:
- Mirrored local identity loaders and writers now check cancellation before
  invoking legacy secure-key bridges and after results return.
- Provisioning fails closed before generation, after storage boundaries, and
  before returning a newly persisted identity; mirrored regressions cover the
  pre-cancelled, late-result, and generation-cancellation paths.

Verification:
- Repository boundary, source-text, native-contract, checker-unit, and diff
  gates passed.
- Flutter analysis and focused Flutter execution remained unverified because
  both runners were silent during bounded attempts; no Flutter pass is claimed.

Next reviewer:
Continue with the documented real-device/native-platform and product-owned
session-source integration gates without changing locked package boundaries.

### 2026-08-29 - Codex - Make App Recovery Factory Cancellation-Safe

Summary:
- Mirrored app recovery persistence factories now check cancellation before
  invoking legacy or non-cancellable native app-support bridges and after the
  lookup completes, preventing stale recovery factory creation.
- Added pre-cancelled no-invocation and cancellation-wins regressions.

Verification:
- Repository boundary, source-text, native-contract, checker-unit, and diff
  gates passed.
- Flutter analysis and focused Flutter execution remained unverified because
  both runners were silent during bounded attempts; no Flutter pass is claimed.

Next reviewer:
Continue with the documented real-device/native-platform and product-owned
session-source integration gates without changing locked package boundaries.

### 2026-08-29 - Codex - Suppress Pre-cancelled Native Dispatch

Summary:
- Mirrored generic method-channel bridges now register cancellation before
  lazily dispatching native secure-key, transport, local-network,
  capture-protection, and app-storage calls.
- Added dispatch-level regressions proving pre-cancelled requests do not reach
  native handlers.

Verification:
- Direct analysis of `peerdeal_native_bridges`: passed.
- Repository boundary, source-text, and native-contract checks: passed.
- Focused Flutter test attempts remained silent during bounded runs; no
  Flutter test pass is claimed.

Next reviewer:
Continue with the documented real-device/native-platform and product-owned
session-source integration gates without changing locked package boundaries.

### 2026-08-29 - Codex - Enforce Persisted Holdem Variant Admission

Summary:
- Mirrored persisted Holdem sources reject unsupported invite variants before
  recovery-state access.
- Mirrored configuration factories reject unsupported accepted context
  variants before recovery-root creation, avoiding unnecessary persistence or
  identity work.
- Added side-effect-ordering regressions.

Verification:
- Direct analysis of both app packages: passed.
- Repository boundary, source-text, native-contract, checker-unit, formatting,
  and diff checks: passed.
- Existing Flutter and Melos runner attempts remain limited by silent startup;
  no pass is claimed for those runners.

Next reviewer:
Continue with the documented real-device/native-platform and product-owned
session-source integration gates without changing locked package boundaries.

### 2026-08-29 - Codex - Preserve Invite Variant Identity

Summary:
- Mirrored `ResolvedInvite` contracts now preserve the required protocol
  `variant_id` through accepted join/session handoff.
- Generic join safety correlates the complete invite identity, and Holdem
  production bootstrap rejects unsupported variants before source loading.
- Updated all in-repo invite constructors and added unsupported-variant
  regressions.

Verification:
- Direct analysis of both app packages: passed.
- Repository boundary, source-text, native-contract, checker-unit, and diff
  checks: passed.
- Focused Flutter test attempt: stopped after the local runner produced no
  output during a bounded attempt; no Flutter test pass is claimed.

Next reviewer:
Continue with the documented real-device/native-platform and product-owned
session-source integration gates without changing the locked package
boundaries.

### 2026-08-29 - Codex - Bind Accepted Session Context Identity

Summary:
- Mirrored context-aware production-session bootstrap now requires hydrated
  `peerId` and `localSeat` to match the accepted `JoinFlowSessionContext`.
- Added peer-drift and seat-drift regressions while keeping invite-only loads
  compatible.

Files:
- Mirrored mobile and desktop production-session bootstrap implementations and
  focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct analysis of both app packages: passed.
- Repository boundary, source-text, native-contract, checker-unit, formatting,
  and diff checks: passed.
- Focused Flutter test attempt: stopped after the local runner produced no
  output during a bounded attempt; no Flutter test pass is claimed.

Risks:
- Real Android/Windows secure-key, transport, device reachability, release
  signing, and product persistence/route integration remain separate gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Mirrored App Production Peer-Identity Normalization

Summary:
- Mirrored app production-session bootstrap/factory, persisted route policy,
  projection publisher, and native local identity loader/writer now enforce
  the existing operational peer-identity predicate.
- Reserved `none`, `unresolved`, and `peer::reserved` values fail closed across
  context, route, runtime, projection, and native identity persistence paths.
- Generic session, table, and invite scopes retain their existing safe-text
  validation behavior.

Files:
- Mirrored mobile and desktop session sources, factories, bootstrap paths,
  projection publisher, local identity load/save paths, and focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct analysis of both app packages: passed.
- Dart formatting and repository boundary, source-text, native-contract,
  checker-unit, and diff checks: passed.
- Focused Flutter test attempt: stopped after the local runner produced no
  output during a bounded attempt; no Flutter test pass is claimed.

Risks:
- Real Android/Windows secure-key, transport, device reachability, release
  signing, and product persistence/route integration remain separate gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Operational App/Native Peer Scope Normalization

Summary:
- Mirrored direct native transport receive drains now reject reserved peer
  scopes before bridge receive lookup.
- Mirrored app table session sources and provisioners reuse the existing
  operational-peer predicate while session IDs retain safe-text validation.
- Reserved `none`, `unresolved`, and `peer::reserved` regressions are covered.

Files:
- Mirrored mobile and desktop native transport adapters, session sources,
  provisioners, and focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct analysis of both app packages: passed.
- Dart formatting and repository boundary, source-text, native-contract, and
  diff checks: passed.
- Focused Flutter test attempt: stopped after the local runner produced no
  output during a bounded attempt; no Flutter test pass is claimed.

Risks:
- Real Android/Windows transport, device reachability, and product transport
  provisioning remain separate integration gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Direct Native Adapter Payload Enforcement

Summary:
- Mirrored direct native transport sinks now use the existing 60 KiB native
  payload ceiling as their default network validator limit.
- Mirrored receive drains reject oversized frames from custom native bridges
  before conversion or session-handler dispatch.

Files:
- `apps/peerdeal_mobile/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_frame_adapter_test.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_frame_adapter_test.dart`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct analysis of both app packages: passed.
- Dart formatting: passed.
- Focused Flutter test attempt: stopped after the local runner produced no
  output during a bounded attempt; no Flutter test pass is claimed.
- `git diff --check`: passed.

Risks:
- Real Android/Windows transport, device reachability, and product transport
  provisioning remain separate integration gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - App Transport Default Drift Gate

Summary:
- Extended the existing native transport bound checker to load both mirrored
  app factory sources.
- The checker now requires each constructor default to reference
  `NativeBridgePayloadLimits.maxTransportPayloadBytes` and rejects drift.

Files:
- `scripts/check_native_contract_bounds.py`
- `scripts/test_check_native_contract_bounds.py`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Native contract-bound check: passed.
- Checker unit suite: passed (7 tests).
- No runtime or package-boundary behavior changed.

Risks:
- Real Android/Windows transport, device reachability, and product transport
  provisioning remain separate integration gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - App/Native Transport Default Bound Alignment

Summary:
- Corrected the mirrored mobile and desktop native transport factory default
  from 64 KiB to the existing `NativeBridgePayloadLimits` 60 KiB ceiling.
- This removes a self-rejecting default that made default sender, drain, and
  provisioner construction unavailable before native capability use.

Files:
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct analysis of both app packages: passed.
- Focused Flutter test attempt: stopped after the local runner produced no
  output during a bounded attempt; no Flutter test pass is claimed.
- `git diff --check`: passed.

Risks:
- Real Android/Windows transport, device reachability, and product transport
  provisioning remain separate integration gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Network/Native Transport Sequence Parity

Summary:
- Applied the existing signed 32-bit transport sequence ceiling to network
  frame validation and replay protection.
- Extended the native contract-bound checker to compare the network sequence
  declaration with the native bridge and host contract.

Files:
- `packages/peerdeal_network/lib/src/models/network_input_limits.dart`
- `packages/peerdeal_network/lib/src/services/basic_transport_frame_validator.dart`
- `packages/peerdeal_network/lib/src/services/sliding_window_transport_frame_replay_guard.dart`
- `packages/peerdeal_network/test/`
- `scripts/check_native_contract_bounds.py`
- `scripts/test_check_native_contract_bounds.py`
- `packages/peerdeal_network/README.md`, `HANDOFF.md`, `HANDOFF_QUEUE.md`,
  `PROJECT_STATE.md`, and `docs/PRODUCTION_READINESS.md`

Verification:
- Complete `peerdeal_network` suite: passed (81 tests).
- Direct package analysis: passed.
- Native contract-bound checker and unit tests: passed.

Risks:
- Native/device reachability, other-platform transport, durable product
  persistence, and release signing remain separate production gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Operational Network Peer-Identity Boundary

Summary:
- Centralized the existing operational peer-identity rule in
  `NetworkInputLimits`.
- Applied it across bootstrap, path selection, primary election, endpoint
  parsing, transport validation, replay protection, and direct confidence
  classification.
- Generic session/table scope IDs retain the broader safe-text predicate.

Files:
- `packages/peerdeal_network/lib/src/models/network_input_limits.dart`
- `packages/peerdeal_network/lib/src/services/`
- `packages/peerdeal_network/test/`
- `packages/peerdeal_network/README.md`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Complete `peerdeal_network` suite: passed (79 tests).
- Direct package analysis: passed.

Risks:
- Native/device reachability, other-platform transport, durable product
  persistence, and release signing remain separate production gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Core Event Sequence Fixture Hash Chain

Summary:
- Repaired the existing root core event fixture with canonical content hashes
  and a contiguous `prev_event_hash` chain.
- Added a typed test-only sequence decoder and reducer replay test covering the
  root core event fixture directory.

Files:
- `packages/peerdeal_core/fixtures/open_table_open_sequence.json`
- `packages/peerdeal_core/test/fixture_loader.dart`
- `packages/peerdeal_core/test/fixture_core_event_sequence_test.dart`
- `packages/peerdeal_core/README.md`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct `peerdeal_core` analysis: passed.
- Independent JSON parse and canonical event-hash-chain check: passed.
- Focused Flutter test runner stalled without output and was terminated; no
  focused test pass is claimed.

Risks:
- This closes stale local core fixture drift only. Product ledger wiring,
  device validation, durable persistence, and release signing remain separate
  integration or operator-owned gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Core Pot Fixture Settlement Boundary

Summary:
- Wired the existing side-pot and folded-dead-money JSON fixtures through a
  typed test-only pot decoder.
- Added a directory-driven fixture test asserting deterministic side-pot slices
  and balanced uncontested settlement through the existing core engines.

Files:
- `packages/peerdeal_core/test/fixture_loader.dart`
- `packages/peerdeal_core/test/fixture_pot_settlement_test.dart`
- `packages/peerdeal_core/README.md`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct `peerdeal_core` analysis: passed.
- Focused Dart test runner attempted with `--no-pub`, then stopped after the
  known pub.dev advisory network stall; no focused test pass is claimed.

Risks:
- This closes local core pot fixture/parser drift only. Product ledger wiring,
  device validation, durable persistence, and release signing remain separate
  integration or operator-owned gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Privacy Retention Fixture Boundary

Summary:
- Wired the existing strict-ephemeral and timed-sandbox JSON fixtures through
  a typed test-only `RetentionPolicy` decoder.
- Added a directory-driven fixture test asserting restore eligibility, derived
  export/wipe behavior, and the exact timed wipe boundary.

Files:
- `packages/peerdeal_privacy/test/fixture_loader.dart`
- `packages/peerdeal_privacy/test/fixture_retention_policy_test.dart`
- `packages/peerdeal_privacy/README.md`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct `peerdeal_privacy` analysis: passed.
- Focused Dart test runner stalled without output in the local runner and was
  stopped; no focused test pass is claimed.

Risks:
- This closes local privacy fixture/parser drift only. Platform storage,
  product retention coordination, device validation, and release signing remain
  separate integration or operator-owned gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Receipt Fixture Authorization Boundary

Summary:
- Wired the existing live, wiped, and wrong-user authorization JSON fixtures
  through typed test-only receipt and authorization decoders.
- Added a directory-driven fixture test asserting matching access, wrong-user
  restore rejection, and wiped-receipt rejection through `DefaultReceiptAuthorizer`.

Files:
- `packages/peerdeal_receipts/test/fixture_loader.dart`
- `packages/peerdeal_receipts/test/fixture_receipt_authorization_test.dart`
- `packages/peerdeal_receipts/README.md`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct `peerdeal_receipts` analysis: passed.
- Focused Dart test runner stalled without output in the local runner and was
  stopped; no focused test pass is claimed.

Risks:
- This closes local receipt fixture/parser drift only. Native secure storage,
  product receipt/session wiring, device validation, and release signing remain
  separate integration or operator-owned gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Crypto Verification Fixture Boundary Enforcement

Summary:
- Wired the existing verified-hand, partial-session, and wiped-request JSON
  fixtures through a typed test-only `VerificationRequest` decoder.
- Added a directory-driven test requiring every request fixture to decode and
  asserting the existing verified, partial, and wiped engine outcomes.

Files:
- `packages/peerdeal_crypto/test/fixture_loader.dart`
- `packages/peerdeal_crypto/test/fixture_verification_test.dart`
- `packages/peerdeal_crypto/README.md`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct `peerdeal_crypto` analysis: passed.
- Focused Dart test runner stalled without output in the local runner and was
  stopped; no focused test pass is claimed.

Risks:
- This closes local crypto fixture/parser drift only. Real provider proof
  verification, product receipt/session wiring, native/device validation, and
  release signing remain separate integration or operator-owned gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-29 - Codex - Wizard Fixture Boundary Enforcement

Summary:
- Wired the existing simple, advanced, conversational, and preset-stack JSON
  fixtures through typed test-only decoders.
- Added a directory-driven resolver gate requiring every setup-intent fixture
  to produce a build-ready validated plan.
- Added assertions for deterministic preset priority and advisory helper
  application without changing wizard behavior.

Files:
- `packages/peerdeal_wizard/test/fixture_loader.dart`
- `packages/peerdeal_wizard/test/setup_equivalence_test.dart`
- `packages/peerdeal_wizard/test/fixtures/starter_fixture_notes.md`
- `packages/peerdeal_wizard/README.md`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct `peerdeal_wizard` analysis: passed.
- Focused Dart test runner stalled without output in the local runner and was
  stopped; no focused test pass is claimed.

Risks:
- This closes local wizard fixture/parser drift only. Full app setup flow,
  product session wiring, native/device validation, and release signing remain
  separate integration or operator-owned gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-28 - Codex - Sync Recovery Fixture Breadth

Summary:
- Wired the existing sync snapshot recovery JSON through a typed test-only
  `RecoveryRequest` fixture decoder.
- Added valid snapshot-plus-suffix and unsupported-protocol safe-close fixture
  assertions, plus a directory-driven test requiring every sync recovery JSON
  fixture to decode.
- Corrected the valid fixture to use the canonical SHA-256 hash of its payload.

Files:
- `packages/peerdeal_sync/test/fixture_loader.dart`
- `packages/peerdeal_sync/test/basic_sync_coordinator_test.dart`
- `packages/peerdeal_sync/test/fixtures/basic_snapshot_recovery.json`
- `packages/peerdeal_sync/test/fixtures/fatal_protocol_recovery.json`
- `packages/peerdeal_sync/test/fixtures/starter_fixture_notes.md`
- `packages/peerdeal_sync/README.md`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`

Verification:
- Direct `peerdeal_sync` analysis: passed.
- Fixture JSON parsing, snapshot payload hash verification,
  package-boundary, source-text, native-contract, and checker unit tests:
  passed.
- Focused Dart/Flutter test runners stalled without output in the local
  runner and were stopped; no focused test pass is claimed.

Risks:
- This closes local sync fixture/parser drift only. Production persistence,
  product session wiring, native/device validation, and cross-network recovery
  remain separate integration or operator-owned gates.

Next reviewer:
Continue with the next codable production-readiness gap without changing the
locked PeerDeal package boundaries.

### 2026-08-28 - Codex - Enforce Rejected Protocol Fixtures

Summary:
- Added a generic protocol fixture assertion that sends every `invalid_` and
  `unsupported_` JSON fixture through its existing catalog/schema family and
  requires fail-closed rejection.

Files:
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Static review, boundary, source-text, and `git diff --check` gates passed.
- The focused Dart test runner stalled without output in the current local
  runner state; no test failure was reported.

Remaining:
- Android/Windows device and cross-network reachability, operator release
  signing, other-platform native implementations, durable product persistence,
  and final UX validation remain external or integration-owned.

### 2026-08-28 - Codex - Add Native Contract Bound Parity Gate

Summary:
- Added a standard-library checker that compares the canonical Dart native
  transport payload, identity, batch, and signed sequence bounds with the
  Android and Windows host declarations.
- Added negative-path checker tests and wired both the checker and tests into
  Melos and GitHub Actions.

Files:
- `scripts/check_native_contract_bounds.py`
- `scripts/test_check_native_contract_bounds.py`
- `pubspec.yaml`, `.github/workflows/ci.yml`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Native contract checker and five checker tests passed.
- Boundary check, source-text check, and `git diff --check` passed.

Remaining:
- Android/Windows device and cross-network reachability, operator release
  signing, other-platform native implementations, durable product persistence,
  and final UX validation remain external or integration-owned.

### 2026-08-28 - Codex - Add Transport Replay Admission Guard

Summary:
- Added bounded sequence-window replay protection to the network validating
  receive boundary, keyed by complete session/sender/recipient scope.
- Duplicate and stale frames fail before handler dispatch; unique frames inside
  the window remain admissible, and accepted sequences are recorded only after
  successful handling so downstream failures remain retryable.

Files:
- `packages/peerdeal_network/lib/src/contracts/transport_frame_replay_guard.dart`
- `packages/peerdeal_network/lib/src/models/transport_frame_replay_result.dart`
- `packages/peerdeal_network/lib/src/services/sliding_window_transport_frame_replay_guard.dart`
- `packages/peerdeal_network/lib/src/services/validating_transport_frame_receiver.dart`
- Focused replay-guard tests and network/readiness documentation.

Verification:
- Full `peerdeal_network` suite passed: 73 tests.
- Network analyzer passed after explicit type cleanup.

Remaining:
- Native queue-level deduplication, key/session authorization policy,
  real-device reachability, product persistence, release signing, and final UX
  remain separate integration or operator gates.

### 2026-08-28 - Codex - Add Production Session Message Authentication

Summary:
- Added the protocol-owned versioned `SessionAuthenticatedPayloadCodec` and
  HMAC-SHA256 `SessionMessageAuthenticator` contract.
- Production mobile and desktop Hold'em route composition now requires an
  injected authenticator, authenticates canonical event bytes with transport
  session/peer/sequence scope, and fails closed when authentication is absent
  or invalid.
- Updated mirrored route fixtures and added fail-closed bootstrap coverage.

Files:
- `packages/peerdeal_protocol/lib/src/authentication/session_message_authenticator.dart`
- Mirrored mobile and desktop production session/transport composition files.
- Mirrored route and bootstrap regression tests.
- `docs/ARCHITECTURE.md`, `docs/PRODUCTION_READINESS.md`,
  `docs/ai/API_CONTRACTS.md`, and `docs/ai/ARCHITECTURE_MAP.md`.

Verification:
- Full mobile (577) and desktop (576) Flutter suites passed.
- Protocol authentication, mirrored route/bootstrap, analyzer, boundary,
  source-text, and `git diff --check` gates passed.
- Dependency audit remains toolchain-sensitive locally; the latest completed
  audit for this dependency state reported zero actionable upgrades.

Remaining:
- App-owned key provisioning, session authorization and rotation policy,
  real-device/cross-device transport validation, other-platform hosts,
  product session/database wiring, and final UX remain separate readiness gates.

### 2026-08-20 - Codex - Align Replay Snapshot Ingress

Summary:
- `BasicReplayEngine` now applies the shared snapshot-envelope identity
  validator before projection.
- Direct `SnapshotSuffixReplayer` calls reject unsafe snapshot identities and
  negative bases before filtering events.

Files:
- `packages/peerdeal_replay/lib/src/engine/basic_replay_engine.dart`
- `packages/peerdeal_replay/lib/src/engine/snapshot_suffix_replayer.dart`
- Focused replay regression tests.

Verification:
- `peerdeal_replay` analysis passed.
- Full package-local replay suite passed: 47 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Harden Snapshot Suffix Event Sequences

Summary:
- Snapshot-backed sync conflict detection and application now reject
  non-positive event sequences before filtering events covered by the snapshot
  base.
- Existing full-window, replay, hash, and suffix policy contracts remain
  unchanged.

Files:
- `packages/peerdeal_sync/lib/src/engine/basic_conflict_detector.dart`
- `packages/peerdeal_sync/lib/src/engine/basic_snapshot_applier.dart`
- Focused snapshot-backed sync regression tests.

Verification:
- `peerdeal_sync` analysis passed.
- Full package-local sync suite passed: 94 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Harden Recovery Snapshot Ingress

Summary:
- Added shared protocol snapshot-envelope identity validation using the
  existing strict UTF-8, bounded, control-free identity rule.
- Sync persistence, conflict detection, and snapshot application now reject
  unsafe identities and negative snapshot base sequences before mutation,
  planning, or projection.

Files:
- `packages/peerdeal_protocol/lib/src/validation/snapshot_envelope_validation.dart`
- `packages/peerdeal_protocol/lib/peerdeal_protocol.dart`
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/engine/basic_conflict_detector.dart`
- `packages/peerdeal_sync/lib/src/engine/basic_snapshot_applier.dart`
- Focused protocol and sync regression tests.

Verification:
- `peerdeal_protocol` analysis passed.
- Full protocol suite passed: 73 tests.
- `peerdeal_sync` analysis passed.
- Full sync suite passed: 92 tests.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Harden Governance Identity Boundary

Summary:
- `DefaultGovernanceEngine` now rejects malformed action identities and fails
  closed on duplicate or unsafe context identities before first-match lookup.
- Existing mode role, seat, and waitlist policy decisions remain unchanged.

Files:
- `packages/peerdeal_modes/lib/src/models/mode_input_limits.dart`
- `packages/peerdeal_modes/lib/src/governance/default_governance_engine.dart`
- `packages/peerdeal_modes/lib/src/governance/governance_result.dart`
- `packages/peerdeal_modes/test/governance_engine_test.dart`

Verification:
- `peerdeal_modes` analysis passed.
- Full package-local mode suite passed: 37 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Validate Bootstrap Resolution Scope

Summary:
- `BasicBootstrapCandidateProvider` now rejects malformed session and table
  scope identities before candidate materialization.
- Peer candidate filtering, route selection, and package boundaries remain
  unchanged.

Files:
- `packages/peerdeal_network/lib/src/services/basic_bootstrap_candidate_provider.dart`
- `packages/peerdeal_network/test/basic_bootstrap_candidate_provider_test.dart`

Verification:
- `peerdeal_network` analysis passed.
- Full package-local network suite passed: 65 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Validate Uncontested Settlement Winner Identity

Summary:
- `ShowdownSettlementProjector.projectUncontestedAndSettle` now rejects a
  negative winner seat before side-pot construction.
- The existing Hold'em seat invariant and variant/core ownership remain
  unchanged.

Files:
- `packages/peerdeal_variants/lib/src/contracts/showdown_settlement_projector.dart`
- `packages/peerdeal_variants/test/holdem_settlement_projection_test.dart`

Verification:
- `peerdeal_variants` analysis passed.
- Full package-local variant suite passed: 184 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Harden Direct Showdown Result Projection

Summary:
- `ShowdownEvaluationResult` now rejects negative or duplicate result seats,
  negative rank indexes, and unsafe summaries before winner grouping or pot
  projection.
- Invalid direct results return stable projection warnings and cannot become
  settlement winners; the existing variant/core boundary is unchanged.

Files:
- `packages/peerdeal_variants/lib/src/contracts/showdown_models.dart`
- `packages/peerdeal_variants/test/holdem_adapter_test.dart`

Verification:
- `peerdeal_variants` analysis passed.
- Focused showdown adapter suite passed: 25 tests.
- Full package-local variant suite passed: 184 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Validate Hold'em Showdown Seat Identities

Summary:
- `HoldemShowdownEvaluator` now rejects negative and duplicate seat numbers
  before sorting or evaluating showdown inputs.
- The evaluator now matches the existing Hold'em hand-state invariant without
  changing the variant or core package boundary.

Files:
- `packages/peerdeal_variants/lib/src/holdem/holdem_showdown_evaluator.dart`
- `packages/peerdeal_variants/test/holdem_adapter_test.dart`
- `packages/peerdeal_variants/README.md`

Verification:
- `peerdeal_variants` analysis passed.
- Full package-local variant suite passed: 181 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Harden Core Pot Input Validation

Summary:
- `PotEngine` now rejects negative commitments, unsafe or duplicate commitment
  seat IDs, and unsafe or duplicate winner IDs before side-pot or award
  traversal.
- Direct `SidePotBuilder` calls also fail closed on invalid or duplicate
  commitment identities; Hold'em-specific rules remain in `peerdeal_variants`.

Files:
- `packages/peerdeal_core/lib/src/pot/pot_input_validation.dart`
- `packages/peerdeal_core/lib/src/pot/pot_engine.dart`
- `packages/peerdeal_core/lib/src/pot/side_pot_builder.dart`
- `packages/peerdeal_core/lib/src/pot/settlement_result.dart`
- Core pot tests and README/API records.

Verification:
- `peerdeal_core` analysis passed.
- Full package-local core suite passed: 78 tests.
- Focused pot suites, boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned session/database wiring, native/device validation,
  authentication/replay contracts, signing, and final UX remain separate
  readiness gates.

### 2026-08-20 - Codex - Bound Wizard Validation Diagnostics

Summary:
- `DefaultGameFileCompiler` now rejects unsafe or oversized validation
  diagnostics with stable wizard result codes.
- Rejected compile results and successful Game Files no longer expose invalid
  diagnostic text; the existing compiler and protocol boundaries remain.

Files:
- `packages/peerdeal_wizard/lib/src/engine/default_game_file_compiler.dart`
- `packages/peerdeal_wizard/lib/src/models/wizard_result_codes.dart`
- `packages/peerdeal_wizard/test/game_file_compiler_test.dart`
- `packages/peerdeal_wizard/README.md`

Verification:
- `peerdeal_wizard` analysis passed.
- Full `peerdeal_wizard` suite passed: 39 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned Game File source policy, session/database wiring, native/device
  validation, authentication/replay contracts, signing, and final UX remain
  separate readiness gates.

### 2026-08-20 - Codex - Harden Deterministic Preset Merging

Summary:
- Direct preset merging now rejects unsafe layer IDs before producing merged
  values or diagnostics.
- Equal-priority layers now preserve supplied order as the deterministic
  tie-breaker; merge policy and package ownership remain unchanged.

Files:
- `packages/peerdeal_wizard/lib/src/engine/default_preset_resolver.dart`
- `packages/peerdeal_wizard/test/preset_resolver_test.dart`
- `packages/peerdeal_wizard/README.md`

Verification:
- `peerdeal_wizard` analysis passed.
- Full `peerdeal_wizard` suite passed: 37 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned Game File source policy, session/database wiring, native/device
  validation, authentication/replay contracts, signing, and final UX remain
  separate readiness gates.

### 2026-08-20 - Codex - Validate Wizard Draft Preset IDs

Summary:
- `DefaultPresetResolver.validateDraft(...)` now rejects padded,
  control-bearing, or otherwise unsafe applied preset IDs before marking a
  draft build-ready.
- The existing compiler check remains as a second output boundary; no wizard
  model or package contract changed.

Files:
- `packages/peerdeal_wizard/lib/src/engine/default_preset_resolver.dart`
- `packages/peerdeal_wizard/test/preset_resolver_test.dart`
- `packages/peerdeal_wizard/README.md`

Verification:
- `peerdeal_wizard` analysis passed.
- Full `peerdeal_wizard` suite passed: 35 tests.
- Boundary-check, source-text, and `git diff --check` passed.

Remaining:
- Product-owned Game File source policy, session/database wiring, native/device
  validation, authentication/replay contracts, signing, and final UX remain
  separate readiness gates.

### 2026-08-20 - Codex - Honor Explicit Wizard Preset References

Summary:
- `DefaultPresetResolver.resolveIntent(...)` now honors nonempty
  `SetupIntent.presetRefs` instead of merging unrelated supplied layers.
- Explicit references must be bounded, safe, unique, and resolve to exactly one
  supplied layer; missing or invalid references fail closed. Empty references
  preserve existing caller-supplied layer behavior.

Files:
- `packages/peerdeal_wizard/lib/src/engine/default_preset_resolver.dart`
- `packages/peerdeal_wizard/test/preset_resolver_test.dart`
- `packages/peerdeal_wizard/README.md`

Verification:
- `peerdeal_wizard` analysis passed.
- Full `peerdeal_wizard` suite passed: 34 tests.

Remaining:
- Product-owned Game File source policy, session/database wiring, native/device
  validation, authentication/replay contracts, signing, and final UX remain
  separate readiness gates.

### 2026-08-20 - Codex - Validate Complete Invite Payloads

Summary:
- `InvitePayloadSchema` now runs the full payload through the existing bounded
  canonical JSON encoder before accepting required fields, preventing unsupported
  nested values from reaching later serialization.
- Invite field validation, catalog compatibility, and package ownership remain
  unchanged.

Files:
- `packages/peerdeal_protocol/lib/src/schemas/invite_payload_schema.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- Protocol README and readiness records.

Verification:
- `peerdeal_protocol` analysis passed.
- Full protocol suite passed: 71 tests.

Remaining:
- Product-owned invite/session authorization, persistence, native/device
  validation, authentication/replay contracts, signing, and final UX remain
  separate readiness gates.

### 2026-08-20 - Codex - Harden Game File Schema Shape Validation

Summary:
- `GameFileSchema` now validates required Game File identity text, required
  object sections, and the variant identifier type instead of checking only
  top-level key presence.
- Unsupported protocol versions remain the existing `ProtocolCatalog`
  responsibility; no schema fields or package boundaries changed.

Files:
- `packages/peerdeal_protocol/lib/src/schemas/game_file_schema.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- Production-readiness and queue records.

Verification:
- `peerdeal_protocol` analysis passed.
- Full protocol suite passed: 70 tests.

Remaining:
- Product-owned Game File policy, session/database wiring, native/device
  validation, authentication/replay contracts, signing, and final UX remain
  separate readiness gates.

### 2026-08-20 - Codex - Validate Complete Wizard Game Files

Summary:
- `DefaultGameFileCompiler` now emits the complete protocol-shaped Game File
  instead of the prior partial object and uses the catalog's `1.0.0` protocol
  version.
- The wizard plan now carries the existing pseudonymous creator and applied
  preset IDs, and successful output is checked by `GameFileSchema` and
  `ProtocolCatalog` before it reaches app setup flows.

Files:
- `packages/peerdeal_wizard/lib/src/engine/default_game_file_compiler.dart`
- `packages/peerdeal_wizard/lib/src/engine/default_preset_resolver.dart`
- `packages/peerdeal_wizard/lib/src/models/resolved_setup_draft.dart`
- `packages/peerdeal_wizard/lib/src/models/validated_setup_plan.dart`
- `packages/peerdeal_wizard/test/game_file_compiler_test.dart`

Verification:
- `peerdeal_wizard` analysis passed.
- Focused wizard compiler, resolver, and equivalence tests passed: 27 tests.

Remaining:
- Product-owned Game File source policy, session/database wiring, native/device
  validation, authentication/replay contracts, signing, and final UX remain
  separate readiness gates.

### 2026-08-20 - Codex - Compose Production Session Factory From Native Support

Summary:
- Mirrored app shells now expose
  `AppHoldemProductionSessionConfigurationFactory.fromNativeAppSupport(...)`.
- The helper composes the existing generic native app-support directory into
  the existing recovery store factory and forwards all existing product-owned
  route, state, identity, event, and persistence inputs without changing their
  ownership.

Files:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_configuration_factory.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_configuration_factory.dart`
- Mirrored configuration-factory tests and demo-slice README API notes.
- Production-readiness note.

Verification:
- Mobile and desktop package analysis passed.
- `dart format` passed for the changed Dart files.
- The focused mobile Flutter test was attempted, but the runner produced no
  output for 30 seconds and was stopped; no Flutter test pass is claimed.
- Deterministic boundary/source-text checks are required before commit.

Remaining:
- Product route/state/database inputs, native/device reachability, transport
  authentication/replay, provider proof semantics, release signing, and final
  UX remain separate gates.

### 2026-08-20 - Codex - Normalize Failed Capture and Ungranted Discovery Results

Summary:
- The generic capture-action decoder now forces `blockingEnabled` to false
  whenever `success` is false.
- The generic local-network discovery decoder now discards peer endpoints when
  `permissionGranted` is false while retaining non-sensitive interface hints.
- Existing channel fields, native behavior, and package ownership remain
  unchanged.

Files:
- `packages/peerdeal_native_bridges/lib/src/capture_protection/capture_protection_channel_contract.dart`
- `packages/peerdeal_native_bridges/lib/src/local_network/local_network_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- Production-readiness note.

Verification:
- `dart analyze packages/peerdeal_native_bridges` passed.
- `dart format` passed for the changed Dart files.
- Deterministic repository gates are required after this boundary change.

Remaining:
- Native/device reachability, transport authentication/replay, product state
  and database wiring, provider proof semantics, release signing, and final UX
  remain separate gates.

### 2026-08-20 - Codex - Normalize Unavailable Transport Receive Frames

Summary:
- The generic native transport receive decoder now discards decoded frames
  whenever the native payload reports `available: false`.
- The existing channel fields, native hosts, transport negotiation, and package
  ownership remain unchanged.

Files:
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- Production-readiness note.

Verification:
- `dart analyze packages/peerdeal_native_bridges` passed.
- `dart format` passed for the changed Dart files.
- The plain Dart test runner cannot execute this Flutter package because its
  public barrel imports `dart:ui`; no test pass is claimed. The focused Flutter
  runner remains subject to the existing startup stall.

Remaining:
- Native/device reachability, transport authentication/replay, product state
  and database wiring, provider proof semantics, release signing, and final UX
  remain separate gates.

### 2026-08-20 - Codex - Normalize Unavailable Transport Capability Limits

Summary:
- The generic native transport channel decoder now forces
  `maxPayloadBytes` to zero when `available` is false, preventing malformed
  capability payloads from exposing a usable ceiling on an unavailable
  transport.
- The existing channel fields, native hosts, negotiation rules, and package
  ownership remain unchanged.

Files:
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- Production-readiness note.

Verification:
- `dart analyze packages/peerdeal_native_bridges` passed.
- `melos run boundary-check` passed.
- `melos run source-text` passed.
- `git diff --check` passed.
- The focused Flutter tests were attempted, but the runner produced no output
  for 30 seconds and was stopped; no Flutter test pass is claimed.

Remaining:
- Native/device reachability, transport authentication/replay, product state
  and database wiring, provider proof semantics, release signing, and final UX
  remain separate gates.

### 2026-08-20 - Codex - Harden Windows Native Readiness Failure Boundaries

Summary:
- Windows local-network and app-support handlers now reject unknown methods
  before performing native work and convert handler exceptions into the
  existing stable unavailable payloads.
- Windows transport capability now reports zero payload bytes when its socket
  is unavailable, matching the generic native transport model.
- Channel names, payload schemas, package ownership, and transport semantics
  remain unchanged.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_local_network.cpp`
- `apps/peerdeal_desktop/windows/runner/windows_app_storage.cpp`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart`
- Production-readiness note and gap queue.

Verification:
- Direct Dart analysis for `peerdeal_native_bridges` and
  `peerdeal_desktop`, boundary-check, source-text, formatting, and
  `git diff --check` passed.
- Elevated CMake compilation passed and compiled all four changed native host
  translation units.
- The existing Windows host smoke reached app storage, capture,
  local-network, and transport checkpoints, but the current Windows profile
  rejected Credential Manager save at `secure_key.save`; no full smoke pass is
  claimed for this run.

Remaining:
- Android/Windows device and network reachability, transport authentication
  and replay, release signing, other native hosts, durable product state, and
  final UX remain separate gates.

### 2026-08-20 - Codex - Harden Windows Transport Receive Request Ordering

Summary:
- Windows native transport now rejects malformed raw receive scopes before
  socket initialization, matching Android and preventing invalid method-channel
  input from triggering native setup.
- The Windows host smoke path now exercises malformed raw receive rejection in
  addition to malformed raw send-frame rejection.
- Transport contracts, authentication semantics, and package ownership remain
  unchanged.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart`
- Production-readiness note and gap queue.

Verification:
- Source-text and boundary validation remain the required local gates; the
  no-pub Windows build was attempted but stalled before output in this
  environment.
- The smoke assertions are ready for the existing Windows native host lane.

Remaining:
- Real device/network reachability, transport authentication/replay, release
  signing, and other native platform hosts remain external or product-owned.

### 2026-08-20 - Codex - Close Windows Native Transport Egress Validation

Summary:
- Windows `FrameFromArguments` now rejects non-safe session and peer identity
  strings before encoding or socket send, matching Android and the generic
  native payload contract.
- The Windows native host smoke path now sends a raw malformed frame through
  the method channel and requires the stable invalid-frame result.
- No transport authentication, replay, or package-contract behavior was
  invented; this only closes the existing egress validation parity gap.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart`
- Production-readiness note and gap queue.

Verification:
- Dart receipt package gates remain green after the prior commit.
- The native source change passed `git diff --check` and repository source-text
  validation; Windows host runtime/build smoke remains environment-dependent.

Remaining:
- Real Windows/Android device reachability, transport authentication/replay,
  release signing, and other native platform hosts remain external or
  product-owned gates.

### 2026-08-20 - Codex - Align Receipt Model and Authorization Validation

Summary:
- `PeerDealReceipt.hasRequiredEnvelopeFields` now applies bounded, strict
  UTF-8, non-padded, control-free text validation to every required envelope
  field before scan or authorization policy runs.
- Direct receipt authorization can no longer approve a receipt identity that
  strict export encoding would reject; binding semantics and package ownership
  are unchanged.

Files:
- `packages/peerdeal_receipts/lib/src/models/peer_deal_receipt.dart`
- `packages/peerdeal_receipts/test/default_receipt_authorizer_test.dart`
- Receipt README, production-readiness note, and gap queue.

Verification:
- Receipt package analyzer passed with the Flutter SDK Dart executable and a
  redirected writable telemetry directory.
- All 66 receipt package tests passed.
- `git diff --check` passed.

Remaining:
- Product session/auth state must still supply real caller identity.
- Native/device, provider-proof, durable persistence, release-signing,
  other-platform, and final UX gates remain external or integration-owned.

### 2026-08-20 - Codex - Harden Receipt Authorization Request Boundary

Summary:
- `DefaultReceiptAuthorizer` now rejects blank, padded, oversized, malformed
  UTF-8, or control-bearing caller user/session identity fields before applying
  the existing receipt binding policy.
- `DefaultReceiptService.authorize` now converts authorizer exceptions into a
  denied, normalized unavailable result instead of leaking the exception.
- Receipt package ownership and the app/native authorization flow are
  unchanged; product callers still supply the authorization request.

Files:
- `packages/peerdeal_receipts/lib/src/services/default_receipt_authorizer.dart`
- `packages/peerdeal_receipts/lib/src/services/default_receipt_service.dart`
- Focused receipt authorization/service tests and package README.

Verification:
- Receipt package analyzer passed with the Flutter SDK Dart executable and a
  redirected writable telemetry directory.
- All 65 receipt package tests passed.
- `git diff --check` passed.

Remaining:
- Product session/auth state must still supply real caller identity.
- Native/device, provider-proof, durable persistence, release-signing,
  other-platform, and final UX gates remain external or integration-owned.

### 2026-08-20 - Codex - Receipt Export Authorization and Provider Proof Verification

Summary:
- The generic crypto verification engine no longer treats a non-null provider
  proof bundle as verified. It now requires the provider-owned
  `DealProofVerifier` seam and fails closed on missing, rejected, or throwing
  verification.
- Receipt export now requires an explicit `ReceiptAuthorizationRequest` and
  invokes the existing receipt authorizer before encoding. Missing, denied, or
  failed authorization returns an unavailable artifact.
- Mirrored mobile and desktop receipt factories, routes, runtimes, and focused
  tests carry the optional product-owned authorization request. No caller
  identity is copied from receipt fields, and generic native bridges remain
  receipt-agnostic.

Files:
- `packages/peerdeal_crypto/lib/src/contracts/deal_proof_verifier.dart`
- `packages/peerdeal_crypto/lib/src/services/default_verification_engine.dart`
- `packages/peerdeal_receipts/lib/src/contracts/receipt_service.dart`
- `packages/peerdeal_receipts/lib/src/services/default_receipt_service.dart`
- Mirrored mobile/desktop receipt export factories, routes, runtimes, and tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- `peerdeal_receipts` analyzer clean; all 62 package tests passed.
- Mirrored mobile and desktop package analyzers clean.
- Direct Flutter test attempts were stopped after bounded no-output startup
  windows; no Flutter test pass is claimed for this slice.
- Direct Dart execution of Flutter-dependent tests is invalid because
  `dart:ui` is unavailable outside the Flutter test runner.
- `git diff --check` passed.

Remaining:
- Provider integrations must supply real proof verification semantics.
- Product session/auth state must supply the caller authorization request for
  receipt export; absent state remains fail closed.
- Real-device/native transport and secure-key validation, release signing,
  durable product persistence, other-platform hosts, and final UX remain
  external or integration-owned gates.

### 2026-08-20 - Codex - Align Event Identity Ingress and Native Queue Admission

Summary:
- Added the protocol-owned event-envelope identity validator and applied it
  before core, replay, recovery conflict, snapshot, and persistence paths.
- Added Android and Windows native receive-scope admission so unrelated
  multicast traffic cannot evict frames for an actively polled session/peer.
- Hardened mode governance so seat acceptance, assignment, and expiry require
  participant/seat binding, while reject/remove/ban actions emit terminal
  states and terminal participants cannot be re-admitted.
- Package boundaries, transport channel shapes, hash policy seams, and the
  original app architecture remain unchanged.

Files:
- `packages/peerdeal_protocol/lib/src/validation/event_envelope_validation.dart`
- Core, replay, and sync ingress validators plus focused tests.
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
  and `.h`
- `packages/peerdeal_modes/lib/src/governance/default_governance_engine.dart`
  and focused governance tests.
- `docs/PRODUCTION_READINESS.md` and package READMEs.

Verification:
- Focused protocol, core, replay, sync, and modes suites pass: 69, 75, 43,
  86, and 36 tests respectively; all five package analyzers report no issues.
- Direct boundary-check and source-text gates pass.
- Android and Windows debug build attempts were stopped after bounded
  no-output windows and are not claimed as verified in this handoff.

Remaining:
- Native frame authentication/replay protection needs the product identity
  and key contract; snapshot authenticity needs a trusted persistence anchor.
- Real-device transport/key validation, product session/state/database wiring,
  release signing, other-platform hosts, and final UX remain external gates.

### 2026-08-18 - Codex - Verify Android Gradle Distribution Integrity

Summary:
- The existing Gradle 8.14 wrapper distribution URL now carries the official
  Gradle SHA-256 checksum, so a substituted or corrupted archive fails closed.
- Gradle version, Android build configuration, signing ownership, and package
  boundaries remain unchanged.

Files:
- `apps/peerdeal_mobile/android/gradle/wrapper/gradle-wrapper.properties`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- The checksum was retrieved from the official Gradle distribution endpoint.
- Android debug build plus analyzer, boundary, source-text, dependency, and
  serialized test gates are the required verification path.

Remaining:
- Android real-device and Windows interactive persistence, cross-device
  transport, operator release signing, other-platform hosts, product-owned
  session state/database wiring, session authentication, and final UX remain
  documented production gates.

### 2026-08-18 - Codex - Pin Android CI Java Toolchain

Summary:
- The Android CI job now installs pinned Temurin Java 17, matching the existing
  Gradle/Kotlin `JavaVersion.VERSION_17` configuration instead of inheriting a
  GitHub runner default.
- `actions/setup-java` v4.7.1 was resolved to an immutable commit before use.
- Android source, release-signing ownership, workflow permissions, and other
  jobs remain unchanged.

Files:
- `.github/workflows/ci.yml`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Local Java 17.0.17 and Android Gradle Java 17 requirements were inspected.
- Repository analyzer, boundary, source-text, dependency, and serialized test
  gates are the required verification path.

Remaining:
- Android real-device and Windows interactive persistence, cross-device
  transport, operator release signing, other-platform hosts, product-owned
  session state/database wiring, session authentication, and final UX remain
  documented production gates.

### 2026-08-18 - Codex - Pin CI Flutter Toolchain

Summary:
- All CI jobs now request Flutter `3.41.8`, matching the verified local Flutter
  revision and the repository Dart SDK floor of `3.11.5`, instead of the
  mutable stable channel.
- The Flutter release tag was verified upstream before the workflow change.
- Jobs, action pins, permissions, timeouts, commands, and package boundaries
  remain unchanged.

Files:
- `.github/workflows/ci.yml`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Local Flutter 3.41.8 and Dart 3.11.5 versions were inspected.
- Upstream Flutter tag `3.41.8` resolved successfully.
- Repository analyzer, boundary, source-text, dependency, and serialized test
  gates are the required verification path.

Remaining:
- Android real-device and Windows interactive persistence, cross-device
  transport, operator release signing, other-platform hosts, product-owned
  session state/database wiring, session authentication, and final UX remain
  documented production gates.

### 2026-08-18 - Codex - Disable Persisted CI Checkout Credentials

Summary:
- All CI checkout steps now set `persist-credentials: false`, preventing the
  read-only workflow token from being retained in the workspace after source
  retrieval.
- Existing immutable action pins, permissions, jobs, and build behavior remain
  unchanged.

Files:
- `.github/workflows/ci.yml`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Workflow inspection confirms all three checkout steps carry the setting.
- Repository analyzer, boundary, source-text, dependency, and serialized test
  gates are the required verification path.

Remaining:
- Android real-device and Windows interactive persistence, cross-device
  transport, operator release signing, other-platform hosts, product-owned
  session state/database wiring, session authentication, and final UX remain
  documented production gates.

### 2026-08-18 - Codex - Remove Redundant Global Melos Install

Summary:
- CI now resolves Melos through the root workspace dependency and invokes it
  with `dart run melos` after `flutter pub get`.
- The redundant global Melos activation was removed; workflow jobs, commands,
  permissions, timeouts, and package boundaries otherwise remain unchanged.

Files:
- `.github/workflows/ci.yml`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Root `pubspec.yaml` and `pubspec.lock` both declare Melos 8.3.0.
- Local analyzer, boundary, source-text, dependency, and serialized test gates
  are the required repository verification path.

Remaining:
- Android real-device and Windows interactive persistence, cross-device
  transport, operator release signing, other-platform hosts, product-owned
  session state/database wiring, session authentication, and final UX remain
  documented production gates.

### 2026-08-18 - Codex - Pin CI Actions To Immutable Commits

Summary:
- CI checkout, Python setup, and Flutter setup actions now use verified
  immutable upstream commit SHAs with version comments instead of mutable tags.
- Existing jobs, permissions, timeouts, build commands, and package boundaries
  are unchanged.

Files:
- `.github/workflows/ci.yml`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Upstream tag refs were resolved with `git ls-remote` before pinning.
- Repository analyzer, boundary, source-text, dependency, and serialized test
  gates remain the required verification path.

Remaining:
- Android real-device and Windows interactive persistence, cross-device
  transport, operator release signing, other-platform hosts, product-owned
  session state/database wiring, session authentication, and final UX remain
  documented production gates.

### 2026-08-18 - Codex - Extend Source-Text Gate To Native Sources

Summary:
- The existing source-text checker now scans committed Kotlin, C/C++, header,
  manifest, Gradle, PowerShell, Python, and shell sources for the same BOM,
  mojibake, em dash, replacement-character, and UTF-8 violations already
  enforced for Dart and repository metadata.
- The generated `docs/ai/repomix-summary.xml` artifact is explicitly excluded
  because it contains copied context rather than runtime source.
- No application behavior, package boundary, native channel contract, or
  architecture changed.

Files:
- `scripts/check_source_text.py`
- `scripts/test_check_source_text.py`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Source-text unit tests: 9 passed.
- Full serialized `melos run test`, analyzer, boundary, source-text, and
  dependency-audit gates passed.
- Android debug APK and Windows release executable builds passed.

Remaining:
- Android real-device and Windows interactive persistence, cross-device
  transport, operator release signing, other-platform hosts, product-owned
  session state/database wiring, session authentication, and final UX remain
  documented production gates.

### 2026-08-18 - Codex - Harden CI Workflow Boundaries

Summary:
- The repository CI workflow now uses read-only contents permission, cancels
  superseded pull-request runs, and applies explicit job timeouts.
- Build, test, dependency, boundary, source-text, and release-signing checks
  remain unchanged; application architecture and package ownership are
  unchanged.

Files:
- `.github/workflows/ci.yml`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Workflow structure was reviewed locally; repository gates are pending in
  this handoff.

Remaining:
- Android real-device and Windows interactive persistence, cross-device
  transport, operator release signing, other-platform hosts, product-owned
  session state/database wiring, session authentication, and final UX remain
  documented production gates.

### 2026-08-18 - Codex - Reject Duplicate Native Key IDs Across App Boundaries

Summary:
- Mirrored mobile and desktop local-identity and native-readiness adapters now
  fail closed when a generic secure-key snapshot contains duplicate key IDs.
- This matches the locked native channel decoder and the existing receipt
  key-ring loader, preventing ambiguous app state from direct bridge adapters.

Files:
- Mirrored `native_local_peer_identity_loader.dart` and
  `app_native_readiness_loader.dart` files and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile identity and readiness tests passed: 21 and 14 tests.
- Focused desktop identity and readiness tests passed: 21 and 14 tests.
- Full `melos run analyze`, `boundary-check`, `source-text`, serialized
  `test`, `dependency-audit`, and `git diff --check` gates passed.

Remaining:
- Real-device secure-key persistence, cross-device transport, release signing,
  other-platform native hosts, and product-owned session state remain open
  documented gates.

### 2026-08-18 - Codex - Reject Duplicate Receipt Key IDs At App Boundary

Summary:
- Mirrored mobile and desktop `NativeReceiptKeyRingLoader` adapters now fail
  closed when any generic secure-key snapshot contains duplicate key IDs.
- This aligns direct app bridge implementations with the locked native channel
  decoder and prevents ambiguous receipt signer/cipher key lookup.

Files:
- Mirrored `native_receipt_key_ring_loader.dart` files and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile loader test passed: 19 tests.
- Focused desktop loader test passed: 19 tests.
- Full `melos run analyze`, `boundary-check`, `source-text`, serialized
  `test`, `dependency-audit`, and `git diff --check` gates passed.

Remaining:
- Real-device secure-key persistence, cross-device transport, release signing,
  other-platform native hosts, and product-owned session state remain open
  documented gates.

### 2026-08-18 - Codex - Fix Windows First-Run Secure-Key Availability

Summary:
- Windows secure-key storage now maps a missing Credential Manager record to
  an available empty key ring at revision zero, matching Android and the
  locked generic bridge contract.
- Existing corrupt or unreadable credentials still fail closed as unavailable.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_secure_key_storage.cpp`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Windows native build and repository gates remain to be run for this change.

Remaining:
- Real Windows runtime validation, operator signing, and product-owned session
  state wiring remain documented production gates.

### 2026-08-18 - Codex - Validate Production Snapshot Metadata Before Identity

Summary:
- Mirrored app-owned persisted Hold'em sources now reject unsafe snapshot type
  and version metadata before secure local-identity provisioning.
- Direct source construction and the existing configuration path share the
  same snapshot metadata safety predicate; package boundaries are unchanged.

Files:
- Mirrored `app_persisted_holdem_production_session_source.dart` files and
  focused source tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile and desktop persisted-session tests remain to be run.

Remaining:
- Product-owned session state, real-device/native validation, and operator
  release signing remain open documented gates.

### 2026-08-18 - Codex - Bound Core Event Payloads

Summary:
- `CoreReducer` now rejects typed event envelopes whose payloads exceed the
  existing canonical JSON limits or contain non-canonical values.
- The rejection uses `ERR_EVENT_ENVELOPE_PAYLOAD_INVALID`; event fields,
  reducer ownership, protocol identities, and package boundaries are unchanged.

Files:
- `packages/peerdeal_core/lib/src/models/core_invariant_codes.dart`
- `packages/peerdeal_core/lib/src/reducer/core_reducer.dart`
- `packages/peerdeal_core/test/peerdeal_core_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused core tests pass after formatting.

Remaining:
- Product-owned event authorization and session-authentication semantics remain
  separate explicit contracts.

### 2026-08-18 - Codex - Bound Core Command Payloads

Summary:
- `CoreCommandValidator` now applies the existing canonical JSON limits to
  typed command payloads before command compatibility and reducer ingress.
- Command fields, protocol identities, deterministic core ownership, and package
  boundaries are unchanged.

Files:
- `packages/peerdeal_core/lib/src/validation/core_command_validator.dart`
- `packages/peerdeal_core/test/peerdeal_core_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused core tests pass after formatting.

Remaining:
- Product-owned command authorization and session-authentication semantics
  remain separate explicit contracts.

### 2026-08-18 - Codex - Bound Game File Schema Payloads

Summary:
- `GameFileSchema` now applies the existing canonical JSON limits during direct
  validation, rejecting oversized or otherwise non-canonical nested payloads.
- Game File fields, schema semantics, catalog identity, and package boundaries
  are unchanged.

Files:
- `packages/peerdeal_protocol/lib/src/schemas/game_file_schema.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused protocol tests pass after formatting.

Remaining:
- Product-owned Game File acceptance and session-authentication semantics remain
  separate integration contracts.

### 2026-08-18 - Codex - Bound Invite Schema Text Input

Summary:
- `InvitePayloadSchema` now applies the existing canonical UTF-8 text byte
  ceiling and rejects malformed UTF-16 text during direct validation.
- Invite fields, signature semantics, catalog identity, and package boundaries
  are unchanged.

Files:
- `packages/peerdeal_protocol/lib/src/schemas/invite_payload_schema.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused protocol tests pass after formatting.

Remaining:
- Session authentication still requires an explicit product/protocol contract;
  this slice only bounds and validates the existing signature field.

### 2026-08-18 - Codex - T317 Fail Closed On Recovery Write Filesystem Errors

Summary:
- `JsonFileRecoveryPersistenceStore.saveSnapshot` and `appendEvents` now
  convert root-directory, temporary-file, and other write-path filesystem
  failures into the existing fatal `ERR_RECOVERY_PERSISTENCE_WRITE_FAILED`
  result instead of leaking synchronous exceptions.
- Temporary-file cleanup remains best effort and the recovery format, locking,
  and package boundaries are unchanged.

Files:
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused `recovery_persistence_store_test.dart` passed all 33 tests.
- Full serialized repository tests, analyze, boundary-check, source-text, and
  dependency-audit gates passed.

Remaining:
- Android real-device/profile validation and release signing, cross-device
  multicast/firewall validation, other-platform hosts, product session/state
  wiring, session authentication, and final UX remain open.

### 2026-08-18 - Codex - T316 Respect Windows No-Multicast Adapter Flags

Summary:
- Windows local-network capability reporting and native multicast interface
  selection now skip adapters marked `IP_ADAPTER_NO_MULTICAST`.
- This removes a false-ready interface from the existing native seams without
  changing the generic channel contracts, transport envelope, or package
  boundaries.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_local_network.cpp`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- `rtk flutter build windows --debug --no-pub -t
  tool/windows_native_host_smoke.dart` passed.
- The generated host exited 0 with `PEERDEAL_NATIVE_HOST_SMOKE_PASS` for every
  existing storage, capture, local-network, transport, and secure-key marker.

Remaining:
- Android real-device/profile validation and release signing, cross-device
  multicast/firewall validation, other-platform hosts, product session/state
  wiring, session authentication, and final UX remain open.

### 2026-08-18 - Codex - T315 Retry Windows Native Transport Initialization

Summary:
- Windows native multicast transport initialization is now lock-serialized
  and retried on demand when capability, send, or receive is requested after
  startup had no usable interface.
- This closes the existing Android/Windows lifecycle asymmetry without changing
  the generic transport channel, host-private envelope, or package boundaries.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.h`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- `rtk flutter build windows --debug --no-pub -t
  tool/windows_native_host_smoke.dart` passed.
- The generated host exited 0 with `PEERDEAL_NATIVE_HOST_SMOKE_PASS` for every
  existing storage, capture, local-network, transport, and secure-key marker.
- The smoke run proves current-host initialization and transport behavior; it
  cannot simulate a startup with no interface or prove cross-device reachability.

Remaining:
- Android real-device/profile validation and release signing, cross-device
  multicast/firewall validation, other-platform hosts, product session/state
  wiring, session authentication, and final UX remain open.

### 2026-08-18 - Codex - T314 Harden Android Secure-Key Read Semantics

Summary:
- Android secure-key loads now inspect the existing Android Keystore alias
  without creating one. A missing namespace therefore remains read-only, and a
  persisted envelope whose key is missing fails closed instead of creating a
  replacement key before decryption fails.
- Write-time key creation, AES-GCM envelope format, namespace locking,
  revisions, and the generic method-channel contract are unchanged.

Files:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- `rtk flutter build apk --debug --no-pub` passed.
- Full repository analyze, boundary, source-text, serialized test, dependency
  audit, and diff gates passed.
- No Android device or emulator is connected, so runtime Keystore persistence
  and recovery behavior remain unverified on hardware.

Remaining:
- Android real-device/profile validation and release signing, cross-device
  multicast/firewall validation, other-platform hosts, product session/state
  wiring, session authentication, and final UX remain open.

### 2026-08-18 - Codex - T313 Verify Windows Native Host Smoke

Summary:
- Built and executed the existing Windows native host smoke target against the
  current committed app host.
- The registered app-storage, capture, local-network, transport, and generic
  secure-key channels passed their end-to-end smoke checkpoints, including
  secure-key stale-writer CAS rejection, conditional save/delete, and cleanup.
- No application architecture or package boundary changed.

Files:
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart` was executed;
  no source changes were required.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- `rtk flutter build windows --debug --no-pub -t tool/windows_native_host_smoke.dart`
  passed.
- The generated host exited 0 with
  `PEERDEAL_NATIVE_HOST_SMOKE_PASS` for every checkpoint.

Remaining:
- Android real-device/profile validation and release signing, cross-device
  multicast/firewall validation, other-platform hosts, product session/state
  wiring, session authentication, and final UX remain open.

### 2026-08-18 - Codex - T312 Harden Transport Source Cancellation Ordering

Summary:
- Mirrored mobile and desktop app transport source observers now attach
  disposal and route cancellation before poll completion handling.
- An already-signaled cancellation therefore wins over an immediately
  completing native poll and cannot publish stale receive counts after source
  teardown; transport ownership and native contracts remain unchanged.

Files:
- Mirrored `app_table_session_transport_source.dart` files and tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Mirrored mobile and desktop transport source focused Flutter tests pass,
  including the immediate-poll cancellation regression.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T311 Harden Native Cancellation Ordering

Summary:
- Existing native method-channel deadline wrappers now attach cancellation
  handlers before platform operation handlers across secure storage, capture,
  app storage, local network, and transport.
- Mirrored app transport frame drains and session provisioning now apply the
  same ordering, preventing stale native results from winning an already-
  signaled route cancellation; contracts and package boundaries remain
  unchanged.

Files:
- Existing method-channel bridge wrappers in `peerdeal_native_bridges`.
- Mirrored mobile and desktop transport adapters, provisioners, and focused
  regression tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused native bridge, mobile transport, and desktop transport Flutter
  tests pass, including immediate-completion cancellation regressions.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T310 Harden Session Bootstrap Cancellation Ordering

Summary:
- Mirrored mobile and desktop production-session bootstrap loaders now attach
  cancellation handling before source completion handling.
- An already-signaled route cancellation therefore wins over an immediately
  completing product source and prevents stale composition from being
  returned; source, transport, and persistence contracts remain unchanged.

Files:
- Mirrored `app_holdem_production_session_bootstrap.dart` files and tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Mirrored mobile and desktop production-session bootstrap focused Flutter
  tests pass, including the immediate-source cancellation regression.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T309 Harden Local Identity Warning Boundaries

Summary:
- Mirrored mobile and desktop local-identity loaders and provisioners now
  fail closed for non-round-tripping UTF-8 warning text.
- Identity validation, secure-key storage, conditional revisions, and
  provisioning behavior remain unchanged.

Files:
- Mirrored `native_local_peer_identity_loader.dart` and
  `native_local_peer_identity_provisioner.dart` files and tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Mirrored mobile and desktop local-identity focused Flutter tests pass.
- Full repository gates are pending in this handoff.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T308 Harden Bootstrap Provider Output

Summary:
- Mirrored mobile and desktop `NativeBootstrapCandidateLoadResult` boundaries
  now filter provider candidates before app state exposure.
- Unsafe peer identities, endpoint hosts/ports, negative priorities, and
  diagnostic reasons are dropped; valid candidate ordering and bounds remain
  unchanged.
- No network model, transport contract, or package boundary changed.

Files:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- Mirrored desktop implementation and test.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Mirrored mobile and desktop bootstrap-loader focused Flutter tests pass.
- Full repository gates are pending in this handoff.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T307 Harden Bootstrap Candidate UTF-8 Boundaries

Summary:
- Mirrored native join-bootstrap coordinators now drop malformed provider peer
  identities before producing a join plan.
- Mirrored bootstrap candidate loaders now fail closed for malformed native
  notes and interface identities while preserving existing valid normalization,
  bounds, and relay fallback behavior.
- Network contracts and package ownership remain unchanged.

Files:
- `apps/peerdeal_mobile/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- Mirrored desktop implementations and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Mirrored coordinator and bootstrap-loader focused Flutter tests pass.
- Full repository gates are pending in this handoff.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T306 Harden Join Acceptance Boundaries

Summary:
- Mirrored mobile and desktop join-flow routes now reject accepted outcomes
  when the resolved invite or supplied session context is unsafe instead of
  rendering a successful result while dropping the product handoff.
- Existing protocol-owned strict UTF-8 validation is applied to join identities
  and display messages; join-flow ownership and package boundaries remain
  unchanged.

Files:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Mirrored mobile and desktop focused join-flow tests pass.
- Full repository gates are pending in this handoff.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T305 Harden Shared UI Accessibility Semantics

Summary:
- `PeerDealAppScaffold` now exposes its title as a semantic heading.
- `PeerDealStatusPill` now exposes its bounded status text as a live semantic
  region so operational changes can be announced by assistive technology.
- Runtime state ownership, layout behavior, action handling, and package
  boundaries remain unchanged.

Files:
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_app_scaffold.dart`
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_status_pill.dart`
- `packages/peerdeal_ui_kit/test/app_shell_widgets_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Shared UI semantics and full UI package tests pass.
- Mirrored mobile and desktop production Hold'em route tests pass.
- Full analyze, boundary, source-text, dependency-audit, test, and diff gates
  pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T304 Harden Windows Native Smoke UTF-8 Boundary

Summary:
- The Windows native host smoke tool now validates the returned app-support
  path with the protocol-owned strict UTF-8 round-trip and 4096-byte ceiling,
  while preserving the existing C0/C1 and padding checks.
- No native channel, host implementation, or package boundary changed.

Files:
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused Dart analysis passes.
- Android Gradle `assembleDebug` passes.
- Windows debug build passes.
- Windows native host smoke passes all storage, capture, local-network,
  transport, secure-key, conditional-mutation, and cleanup checkpoints.
- Full analyze, boundary, source-text, dependency-audit, test, and diff gates
  pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T303 Harden App Invite UTF-8 Boundaries

Summary:
- Mirrored mobile and desktop Hold'em production session bootstraps now apply
  the protocol-owned UTF-8 byte ceiling and exact encode/decode round-trip
  check to invite and remote-peer identities before product source loading.
- Added regressions for unpaired UTF-16 and oversized invite identities; the
  source remains untouched when validation fails.
- Invite/source ownership, route composition, and package boundaries remain
  unchanged.

Files:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_bootstrap.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_bootstrap.dart`
- Mirrored bootstrap tests and `docs/PRODUCTION_READINESS.md`.

Verification:
- Focused mobile and desktop bootstrap Flutter tests pass.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T302 Harden Opaque Receipt UTF-8 Boundaries

Summary:
- `OpaqueExportEncoder` now validates all required receipt envelope text before
  JSON encoding, preventing unpaired UTF-16 values from becoming escaped
  replacement identities in an export artifact.
- Encoder and decoder plaintext/ciphertext payload limits now require exact
  UTF-8 encode/decode round-trips; malformed payloads fail closed before
  signature verification or payload exposure.
- Receipt artifact format, signer/cipher ownership, and package boundaries
  remain unchanged.

Files:
- `packages/peerdeal_receipts/lib/src/services/opaque_export_encoder.dart`
- `packages/peerdeal_receipts/lib/src/services/opaque_export_decoder.dart`
- `packages/peerdeal_receipts/test/opaque_export_encoder_test.dart`
- `packages/peerdeal_receipts/test/opaque_export_decoder_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused receipt encoder/decoder suites pass.
- `peerdeal_receipts` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T301 Harden Privacy/Crypto/App UTF-8 Boundaries

Summary:
- Privacy diagnostic text and field checks now use the protocol-owned strict
  UTF-8 round-trip limit before preserving scrubbed text.
- Crypto provider-proof normalization and verification metadata checks now
  reject unpaired UTF-16 text instead of accepting replacement bytes.
- Mirrored mobile and desktop Hold'em snapshot metadata checks now use the same
  strict limit before persistence.

Files:
- `packages/peerdeal_privacy/lib/src/services/default_diagnostics_scrubber.dart`
- `packages/peerdeal_privacy/test/default_diagnostics_scrubber_test.dart`
- `packages/peerdeal_crypto/lib/src/services/default_provider_proof_normalizer.dart`
- `packages/peerdeal_crypto/lib/src/services/default_verification_engine.dart`
- `packages/peerdeal_crypto/test/default_provider_proof_normalizer_test.dart`
- `packages/peerdeal_crypto/test/default_verification_engine_test.dart`
- Mirrored `app_holdem_production_session_snapshot_writer.dart` files and tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused privacy, crypto, mobile, and desktop suites pass.
- Privacy and crypto analyzers pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T300 Harden Hold'em UTF-8 Boundaries

Summary:
- `HoldemInputLimits` now delegates text validation to the protocol-owned
  strict UTF-8 round-trip limit.
- Hold'em hand state, public event reduction, and projection cursor identity
  checks now reject unpaired UTF-16 text without changing variant rules,
  protocol event shape, or package ownership.

Files:
- `packages/peerdeal_variants/lib/src/holdem/holdem_input_limits.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_hand_state.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_event_reducer.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_core_projection_adapter.dart`
- `packages/peerdeal_variants/test/holdem_hand_state_persistence_test.dart`
- `packages/peerdeal_variants/test/holdem_core_projection_adapter_test.dart`
- `packages/peerdeal_variants/test/holdem_event_reducer_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused Hold'em suite passes: 31 tests.
- `peerdeal_variants` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T299 Harden Protocol/Core UTF-8 Boundaries

Summary:
- `CanonicalJsonLimits` now exposes strict UTF-8 encode/decode round-trip
  validation for its existing text-byte ceiling.
- Canonical JSON serialization and core command validation, event reduction,
  table-state hydration, and baseline invariant identity checks now reject
  unpaired UTF-16 text instead of accepting replacement bytes.
- Protocol constructors, event shapes, deterministic state ownership, and
  package boundaries remain unchanged.

Files:
- `packages/peerdeal_protocol/lib/src/serialization/canonical_json_limits.dart`
- `packages/peerdeal_protocol/lib/src/serialization/canonical_json.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `packages/peerdeal_core/lib/src/validation/core_command_validator.dart`
- `packages/peerdeal_core/lib/src/reducer/core_reducer.dart`
- `packages/peerdeal_core/lib/src/models/table_state.dart`
- `packages/peerdeal_core/lib/src/invariants/baseline_invariant_guards.dart`
- `packages/peerdeal_core/test/peerdeal_core_test.dart`
- `packages/peerdeal_core/test/invariant_guards_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused protocol suite passes: 55 tests.
- Focused core suite passes: 56 tests.
- Protocol and core analyzers pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T298 Harden Native Bridge UTF-8 Boundaries

Summary:
- `NativeBridgePayloadLimits.isWithinUtf8Limit` now requires the encoded text
  to decode back to the exact original value, rejecting unpaired UTF-16 text
  instead of accepting replacement bytes.
- All existing native bridge channel, app-shell, and platform consumers inherit
  the stricter check without changing channel shapes, limits, or package
  boundaries.

Files:
- `packages/peerdeal_native_bridges/lib/src/native_bridge_payload_limits.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused native bridge contract suite passes: 32 tests.
- `peerdeal_native_bridges` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T297 Harden Network Identity Boundaries

Summary:
- `peerdeal_network` now applies one 256-byte, strict UTF-8, non-empty,
  unpadded, C0/C1-free peer identity predicate across transport frames,
  bootstrap candidates, path selection, primary election, relay fallback, and
  transfer policy.
- Discovery parsing now rejects oversized peer identities instead of silently
  truncating them into a different identity; C1 input is rejected before
  whitespace normalization can launder it.
- Existing network contracts, routing semantics, and package boundaries remain
  unchanged.

Files:
- `packages/peerdeal_network/lib/src/models/network_input_limits.dart`
- `packages/peerdeal_network/lib/src/services/basic_bootstrap_candidate_provider.dart`
- `packages/peerdeal_network/lib/src/services/basic_session_path_selector.dart`
- `packages/peerdeal_network/lib/src/services/default_primary_peer_election_service.dart`
- `packages/peerdeal_network/lib/src/services/basic_relay_fallback_service.dart`
- `packages/peerdeal_network/lib/src/services/default_transfer_policy.dart`
- `packages/peerdeal_network/lib/src/services/basic_transport_frame_validator.dart`
- `packages/peerdeal_network/lib/src/services/discovered_peer_endpoint_parser.dart`
- `packages/peerdeal_network/test/network_identity_boundary_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Full `peerdeal_network` suite passes: 65 tests.
- `peerdeal_network` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T296 Harden Replay Request Scope Text

Summary:
- `BasicReplayEngine` now validates table, session, and protocol request scope
  identities before protocol checks, filtering, or projector state creation.
- Scope text must be non-empty, unpadded, UTF-8 round-tripping, byte-bounded,
  and free of C0/C1 controls.
- Validation remains at the replay engine boundary; permissive protocol
  envelopes and replay request model construction remain unchanged.

Files:
- `packages/peerdeal_replay/lib/src/engine/basic_replay_engine.dart`
- `packages/peerdeal_replay/test/replay_request_identity_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused replay request identity regressions pass.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T295 Harden Recovery Storage Identity Text

Summary:
- `RecoveryPersistenceScope` now rejects C1 controls in table, session, and
  protocol identity parts before deriving its existing storage key.
- Scope validation now requires UTF-8 encode/decode round-trip fidelity, so
  unpaired UTF-16 text cannot become a different persisted identity.
- The delimiter-based storage format and sync package boundary remain
  unchanged.

Files:
- `packages/peerdeal_sync/lib/src/models/recovery_persistence_scope.dart`
- `packages/peerdeal_sync/test/recovery_persistence_scope_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused sync scope regression suite passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T294 Harden Hold'em Typed Text Boundaries

Summary:
- Hold'em hand-state validation now applies the existing canonical UTF-8 text
  byte ceiling to hand IDs and action summaries.
- Hold'em cursor identity checks now reject oversized and C1-bearing text and
  validate the optional `last_event_type` field at construction.
- Hold'em event-payload text validation now applies the same bound, preserving
  fail-closed handling for direct in-memory events that bypass JSON decoding.
- Variant ownership, protocol event shape, and package boundaries remain
  unchanged.

Files:
- `packages/peerdeal_variants/lib/src/holdem/holdem_input_limits.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_hand_state.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_core_projection_adapter.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_event_reducer.dart`
- `packages/peerdeal_variants/test/holdem_hand_state_persistence_test.dart`
- `packages/peerdeal_variants/test/holdem_core_projection_adapter_test.dart`
- `packages/peerdeal_variants/test/holdem_event_reducer_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused variant regression suite passes: 29 tests.
- Full `peerdeal_variants` Dart suite passes: 180 tests.
- `peerdeal_variants` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T293 Harden Core Typed Ingress Text Bounds

Summary:
- Core command validation now rejects typed command identities that exceed the
  existing canonical JSON text-byte ceiling before protocol compatibility is
  evaluated.
- Core reducer ingress now rejects unsafe or oversized event envelope
  identities, including direct in-memory envelopes that bypass wire decoding,
  with `ERR_EVENT_ENVELOPE_IDENTITY_UNSAFE`.
- Programmatic and hydrated `TableState` identities now use the same existing
  canonical text-byte ceiling as their unsafe-text checks.
- No protocol model, wire format, package boundary, or architecture changed.

Files:
- `packages/peerdeal_core/lib/src/validation/core_command_validator.dart`
- `packages/peerdeal_core/lib/src/reducer/core_reducer.dart`
- `packages/peerdeal_core/lib/src/invariants/baseline_invariant_guards.dart`
- `packages/peerdeal_core/lib/src/models/table_state.dart`
- `packages/peerdeal_core/lib/src/models/core_invariant_codes.dart`
- `packages/peerdeal_core/test/peerdeal_core_test.dart`
- `packages/peerdeal_core/test/invariant_guards_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused `peerdeal_core` suite passes: 68 tests.
- `peerdeal_core` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T292 Harden Core State Identities

Summary:
- Core `TableState` hydration now rejects padded or control-bearing table,
  session, protocol, and active-hand identities.
- Baseline invariant guards now report explicit unsafe-identity violations for
  programmatically constructed state as well, preventing malformed state from
  entering deterministic projection paths.
- Core state ownership and reducer architecture remain unchanged.

Files:
- `packages/peerdeal_core/lib/src/models/core_invariant_codes.dart`
- `packages/peerdeal_core/lib/src/invariants/baseline_invariant_guards.dart`
- `packages/peerdeal_core/lib/src/models/table_state.dart`
- `packages/peerdeal_core/test/invariant_guards_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused core invariant/state suite passes: 18 tests.
- `peerdeal_core` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T291 Normalize Diagnostics Redaction Keys

Summary:
- Diagnostics redaction now compares sensitive field names
  case-insensitively while preserving safe original field names in output.
- Case variants such as `RECEIPT_TOKEN`, `Session_Secret`, and `IP_ADDRESS`
  can no longer bypass the existing privacy scrubber.
- Scrubber limits, output shape, and privacy package ownership remain unchanged.

Files:
- `packages/peerdeal_privacy/lib/src/services/default_diagnostics_scrubber.dart`
- `packages/peerdeal_privacy/test/default_diagnostics_scrubber_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused diagnostics scrubber suite passes: 9 tests.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T290 Normalize Metadata Minimization Keys

Summary:
- Metadata minimization now applies existing device, IP, and personal-field
  stripping rules case-insensitively.
- Case variants such as `Device_Identifier`, `IP_ADDRESS`, and `EMAIL` can no
  longer bypass the existing privacy profile.
- The minimizer contract and metadata ownership remain unchanged.

Files:
- `packages/peerdeal_privacy/lib/src/services/default_metadata_minimizer.dart`
- `packages/peerdeal_privacy/test/default_metadata_minimizer_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused metadata minimizer suite passes: 3 tests.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T289 Harden Receipt Key IDs

Summary:
- Receipt signing and encryption key providers now reject empty, padded,
  oversized, colon-bearing, malformed-UTF-8, or C0/C1 control-bearing key IDs.
- The existing colon-delimited signature/cipher formats and key-provider
  contracts remain unchanged.

Files:
- `packages/peerdeal_receipts/lib/src/models/receipt_key_ring_input_limits.dart`
- `packages/peerdeal_receipts/lib/src/models/receipt_signing_key.dart`
- `packages/peerdeal_receipts/lib/src/models/receipt_encryption_key.dart`
- `packages/peerdeal_receipts/test/hmac_sha256_receipt_signer_test.dart`
- `packages/peerdeal_receipts/test/receipt_key_ring_snapshot_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused signer suite passes: 9 tests.
- Focused key-ring suite passes: 5 tests.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T288 Harden Receipt Export Identifier Inspection

Summary:
- Signed opaque receipt inspection now rejects padded, control-bearing, or
  malformed required receipt identifiers before exposing the verified payload.
- The artifact format, signature boundary, opaque payload semantics, and
  provider-owned proof behavior remain unchanged.

Files:
- `packages/peerdeal_receipts/lib/src/services/opaque_export_decoder.dart`
- `packages/peerdeal_receipts/test/opaque_export_decoder_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused opaque export decoder suite passes: 15 tests.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T287 Reject Coerced Wizard Selections

Summary:
- Wizard resolution now accepts only bounded, UTF-8-safe, non-padded strings
  for `mode_type` and `variant_id` values supplied through partial settings or
  preset resolution.
- Non-string or control-bearing selections fail closed as unsupported instead
  of becoming identifiers through `toString()` coercion.
- Existing mode and variant contracts remain unchanged.

Files:
- `packages/peerdeal_wizard/lib/src/engine/default_preset_resolver.dart`
- `packages/peerdeal_wizard/test/preset_resolver_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused preset resolver suite passes: 13 tests.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T286 Harden Diagnostics Redaction

Summary:
- The privacy scrubber now redacts non-string, padded, oversized, or
  control-bearing diagnostic keys instead of coercing them into output fields.
- Control-bearing diagnostic code/message text now fails closed to the stable
  truncation marker.
- Sensitive keys with appended control data can no longer bypass redaction.

Files:
- `packages/peerdeal_privacy/lib/src/services/default_diagnostics_scrubber.dart`
- `packages/peerdeal_privacy/test/default_diagnostics_scrubber_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused diagnostics scrubber suite passes: 8 tests.
- `peerdeal_privacy` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T285 Harden Direct Game File Metadata

Summary:
- Direct `DefaultGameFileCompiler` calls now reject padded or control-bearing
  plan IDs before emitting `config_id`.
- Policy profile keys and values now require bounded, safe metadata text;
  canonical JSON acceptance alone is no longer sufficient.
- The existing compiler contract, result-code surface, and wizard boundary
  remain unchanged apart from the additive invalid-plan-id code.

Files:
- `packages/peerdeal_wizard/lib/src/engine/default_game_file_compiler.dart`
- `packages/peerdeal_wizard/lib/src/models/wizard_result_codes.dart`
- `packages/peerdeal_wizard/test/game_file_compiler_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused Game File compiler suite passes: 12 tests.
- `peerdeal_wizard` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T284 Reject Coerced Wizard Policy Profiles

Summary:
- Wizard policy profile inputs now require safe, unpadded strings before they
  enter the typed `ValidatedSetupPlan` profile map.
- Numeric, null, blank, padded, and control-bearing values fail validation
  instead of being converted with `.toString()` into profile identifiers.
- The existing wizard package boundary and profile keys remain unchanged.

Files:
- `packages/peerdeal_wizard/lib/src/engine/default_preset_resolver.dart`
- `packages/peerdeal_wizard/test/preset_resolver_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused preset-resolver suite passes: 12 tests.
- `peerdeal_wizard` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T283 Reject Coerced Provider Proof References

Summary:
- Provider proof normalization now requires exactly one supported proof
  reference field (`proof_ref` or `proofReference`) with a string value.
- Numeric, boolean, object, null, and duplicate alias values fail closed
  instead of being coerced into proof identities.
- The existing crypto package boundary and provider proof shape remain intact.

Files:
- `packages/peerdeal_crypto/lib/src/services/default_provider_proof_normalizer.dart`
- `packages/peerdeal_crypto/test/default_provider_proof_normalizer_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused provider-proof normalizer suite passes: 8 tests.
- `peerdeal_crypto` analyzer passes.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T282 Restore Aggregate App Test Gate

Summary:
- Corrected mirrored mobile and desktop receipt key-ring loader expectations
  so malformed key metadata reports the existing metadata-specific warning.
- No production behavior or package boundary changed; the fix removes a stale
  test expectation exposed by the full Flutter gate.

Files:
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_loader_test.dart`

Verification:
- Mobile app suite passes: 559 tests.
- Desktop app suite passes: 558 tests.
- Aggregate `melos run test` passes, including package Dart tests, Flutter
  tests, boundary checks, dependency-audit tests, and source-text checks.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T281 Reject Coerced Android Secure-Key Revisions

Summary:
- Android secure-key recovery now requires persisted revision values to be
  actual integer `Int`/`Long` values.
- Fractional, string, and null revisions fail closed instead of being coerced
  by `JSONObject.getLong`; missing revisions retain legacy revision zero.
- The encrypted storage format, generic method-channel contract, and package
  boundaries are unchanged.

Files:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Android `assembleDebug --no-daemon --quiet` passes.
- Direct Dart analyzer, package-boundary/source-text checks, their 13 and 7
  focused tests, dependency-audit tests, and `git diff --check` pass.
- No Dart production code changed; Flutter test execution was not required
  for this Kotlin-only slice.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T280 Align Android Transport Integer Decoding

Summary:
- Android native transport method-call decoding now accepts only `Int` or
  `Long` values for sequence and payload bytes.
- Fractional `Number` values are rejected instead of being silently truncated
  by `toLong()`, matching the existing Windows integer-only decoder.
- The generic transport channel, host-private envelope, and package boundaries
  are unchanged.

Files:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Android `assembleDebug --no-daemon --quiet` passes.
- Direct Dart analyzer, package-boundary/source-text checks, their 13 and 7
  focused tests, dependency-audit tests, and `git diff --check` pass.
- No Dart production code changed; the focused Flutter test launcher was not
  needed for this Kotlin-only slice.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T279 Bound Native Secure-Key Revisions

Summary:
- Added a shared maximum secure-key revision equal to the signed 64-bit native
  storage limit used by Android and Windows.
- Generic snapshot/mutation decoding and method-channel compare-and-swap writes
  now reject oversized revisions before treating them as valid state or
  invoking native storage.
- Mirrored mobile and desktop readiness, local-identity, and receipt key-ring
  loaders/writers apply the same bound to custom bridge implementations.

Files:
- `packages/peerdeal_native_bridges/lib/src/native_bridge_payload_limits.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/`
- Mirrored app native-readiness, local-identity, and receipt key-ring adapters.
- Native bridge regression tests, `docs/PRODUCTION_READINESS.md`, and this log.

Verification:
- Direct Dart analyzer passes for `apps` and `packages`.
- Package-boundary/source-text checks, their 13 and 7 focused tests,
  dependency-audit tests, and `git diff --check` pass.
- The focused Flutter native-bridge suite now passes all 49 tests with direct
  host-access SDK execution; an earlier sandboxed launcher timeout was an
  environment limitation, not a repository test result.

Remaining:
- Android real-device and Windows interactive persistence validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T278 Reject Malformed Android UTF-8 Text

Summary:
- Android transport identity validation now rejects strings whose UTF-8
  encoding does not round-trip, instead of accepting replacement-byte output.
- Android secure-key namespace, key-record, and app-support path validation
  apply the same fail-closed UTF-8 rule before bounded native use.
- Windows already rejected malformed UTF-8; this aligns the Android host with
  that existing behavior without changing channel fields or package ownership.

Files:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/AppStorageDirectoryHandler.kt`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Android `assembleDebug --no-daemon --quiet` passes.
- Full workspace analyzer, boundary/source-text checks, their 13 and 7
  focused tests, dependency-audit tests, and `git diff --check` pass.
- The full Melos test runner and live dependency resolver remain separately
  documented as prior no-output timeouts; this Kotlin-only change introduced no
  Dart test path.

Remaining:
- Interactive Windows secure-key persistence, Android real-device validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T277 Align Android Network Capability Eligibility

Summary:
- Android local-network availability and interface hints now require a usable
  IPv4 address.
- Any, loopback, and link-local addresses are excluded before capability or
  broadcast readiness is reported, matching the existing Android multicast
  transport filter.
- No native channel, protocol, or package boundary changed.

Files:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/LocalNetworkHandler.kt`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Android `assembleDebug --no-daemon --quiet` passes after the pinned Gradle
  distribution was downloaded.
- Full Dart analyzer, package-boundary/source-text checks, their focused test
  suites, dependency-audit tests, and `git diff --check` pass.
- The live dependency-audit resolver produced no output and timed out after
  five minutes; the full Melos test runner likewise produced no output and
  timed out after ten minutes. No failure output was available from either
  runner.

Remaining:
- Interactive Windows secure-key persistence, Android real-device validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T276 Align Windows IPv4 Interface Eligibility

Summary:
- Windows local-network capability no longer treats non-routable IPv4
  addresses as usable interface evidence.
- Windows multicast interface selection now applies the same full loopback,
  unspecified, broadcast, and APIPA exclusions.
- The generic local-network/transport channels and package boundaries remain
  unchanged.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_local_network.cpp`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- `clang-cl` syntax-only compilation passes for both changed Windows native
  translation units with the generated Flutter include paths, Windows SDK
  headers, and the runner's `NOMINMAX` definition.
- Full workspace analyzer, boundary/source-text checks, their 13 and 7 script
  tests, dependency-audit script tests, and `git diff --check` pass.
- Runtime smoke remains a separate binary validation because Flutter/CMake
  orchestration has previously timed out during support-file generation.

Remaining:
- Interactive Windows secure-key persistence, Android real-device validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T275 Reject Invalid Network Measurements

Summary:
- `peerdeal_network` now rejects negative latency, acknowledgement lag,
  disconnect, reachability, event-index-lag, and snapshot-serve measurements.
- Confidence classification and primary-peer election return an unsafe,
  paused result before malformed values reach scoring.
- Routing contracts, package ownership, and native boundaries are unchanged.

Files:
- `packages/peerdeal_network/lib/src/models/peer_metric_snapshot.dart`
- Mirrored network classifiers/election tests and package/readiness docs.

Verification:
- The complete `peerdeal_network` package suite passes 57 tests, including
  focused negative-measurement coverage.
- Formatting, full workspace analyzer, boundary/source-text checks, their 13
  and 7 script tests, dependency-audit script tests, and `git diff --check`
  pass.

Remaining:
- Interactive Windows secure-key persistence, Android real-device validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T274 Guard Windows Credential Serialization Arithmetic

Summary:
- Windows secure-key `AppendString` now rejects a field larger than the full
  Credential Manager blob limit before subtracting its encoded size.
- This removes an unsigned-size underflow path introduced by the platform
  bound without changing the storage format, channel, or package boundaries.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_secure_key_storage.cpp`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- `clang-cl` syntax-only compilation of the changed Windows translation unit
  passes with the generated Flutter include paths, Windows SDK headers, and
  the runner's `NOMINMAX` definition.
- Boundary/source-text checks, their 13 and 7 script tests, dependency-audit
  script tests, and `git diff --check` pass.
- Full Flutter/CMake native orchestration remains separately timed out during
  Flutter support-file generation, as recorded by T273.

Remaining:
- Interactive Windows secure-key persistence, Android real-device validation,
  cross-device multicast, release signing, other-platform hosts, product
  session/state and database wiring, session authentication, and final UX.

### 2026-08-18 - Codex - T273 Enforce Windows Credential Blob Limit

Summary:
- Windows secure-key serialization now uses the Win32
  `CRED_MAX_CREDENTIAL_BLOB_SIZE` bound (2,560 bytes), matching the existing
  `CredWriteW` contract.
- Oversized serialized key rings fail closed before native persistence instead
  of reaching an API call that must reject them.
- No fallback to session-only credentials, channel change, or package-boundary
  change was introduced.

Files:
- `apps/peerdeal_desktop/windows/runner/windows_secure_key_storage.cpp`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Windows native host smoke reached app storage, capture, local-network,
  transport, and secure-key baseline checks. Secure-key save remains blocked in
  the Codex noninteractive logon session because Windows local-machine
  Credential Manager persistence returns `ERROR_NO_SUCH_LOGON_SESSION`; a
  session-only fallback would violate durable secure-key requirements.
- The Windows SDK header defines `CRED_MAX_CREDENTIAL_BLOB_SIZE` as 2,560
  bytes. Direct Dart analysis, boundary/source-text checks, their 13 and 7
  script tests, dependency-audit script tests, and `git diff --check` pass.
- Flutter/CMake native builds timed out during Flutter support-file generation;
  standalone Visual Studio `msbuild` is not on PATH. The dependency audit
  command also timed out without changing package state.

Remaining:
- Validate secure-key persistence under a normal interactive Windows profile,
  Android secure-key/capture behavior on a real device, cross-device multicast,
  release signing, other-platform hosts, product session/state and database
  wiring, session authentication, and final UX validation.

### 2026-08-18 - Codex - T272 Separate Production Route Readiness From Discovery

Summary:
- Mirrored mobile and desktop app shells now gate configured production routes
  with a route-critical readiness projection requiring capture protection,
  native transport, and secure-key storage.
- The existing `allCapabilitiesReady` projection still includes local peer
  discovery for join/bootstrap consumers.
- Invite/context-based production routes are no longer blocked by the
  intentionally unsupported discovery advertisement contract.

Files:
- Mirrored app native-readiness snapshots and app-shell route gates/tests.
- `docs/ARCHITECTURE.md`, `docs/PRODUCTION_READINESS.md`, and this handoff log.

Verification:
- Direct Flutter-bundled Dart analyzer passes all 17 workspace packages.
- Formatting passes with no changed files; boundary and source-text checks pass,
  their 13 and 7 script tests pass, dependency-audit script tests pass, and
  `git diff --check` passes.
- Focused mobile and desktop Flutter suites each timed out after 180 seconds
  without output; no assertion or compiler failure was reported.

Remaining:
- Real-device secure-key/capture validation, cross-device multicast, release
  signing, other-platform hosts, product session/state and database wiring,
  session authentication, and final UX validation remain open.

### 2026-08-17 - Codex - T271 Bound Android Local-Network Address Traversal

Summary:
- Android local-network capability inspection now caps per-interface address
  traversal at 256 entries, matching the existing Windows host bound.
- The unsupported peer-discovery contract and native channel shape remain
  unchanged; only native resource traversal is bounded.

Files:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/LocalNetworkHandler.kt`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Android `assembleDebug --no-daemon` passes, including Kotlin compilation.
- Direct Flutter-bundled Dart analyzer passes all 17 workspace packages.
- Boundary and source-text checks pass; their 13 and 7 script tests pass, and
  dependency-audit script tests pass.
- `git diff --check` passes.

Remaining:
- Real-device secure-key/capture validation, cross-device multicast, release
  signing, other-platform hosts, product session/state and database wiring,
  session authentication, and final UX validation remain open.

### 2026-08-17 - Codex - T270 Guard Android Secure-Key Revision Exhaustion

Summary:
- Android secure-key save and delete mutations now fail closed when the
  persisted revision reaches `Long.MAX_VALUE`, before signed arithmetic can
  overflow.
- This aligns Android with the existing Windows secure-key host guard without
  changing the generic method-channel contract or receipt semantics.

Files:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Android `assembleDebug --no-daemon` passes, including Kotlin compilation.
- Direct Flutter-bundled Dart analyzer passes all 17 workspace packages.
- Boundary and source-text checks pass; their 13 and 7 script tests pass, and
  dependency-audit script tests pass.
- `git diff --check` passes.

Remaining:
- Real-device secure-key/capture validation, cross-device multicast, release
  signing, other-platform hosts, product session/state and database wiring,
  session authentication, and final UX validation remain open.

### 2026-08-17 - Codex - T269 Fail Early Transport Provisioning Configuration

Summary:
- Mirrored mobile and desktop transport provisioners now reject polling
  intervals outside the existing 100ms-to-one-minute source bounds before
  native capability lookup.
- This prevents an invalid configuration from producing an apparently
  available transport session before source startup fails.
- No protocol, native channel, package boundary, or source contract changed.

Files:
- Mirrored app transport provisioners and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Direct Flutter-bundled Dart analyzer passes all 17 workspace packages.
- Boundary and source-text checks pass; their 13 and 7 script tests pass, and
  dependency-audit script tests pass.
- Focused mobile Flutter test invocation timed out after 180 seconds without
  output; no assertion failure was reported. The equivalent desktop Flutter
  test was not started because the runner is serialized and exhibits the same
  local startup limitation.
- The dependency audit command timed out after 180 seconds without output; no
  dependency files were changed.
- Dart formatting and `git diff --check` pass.

Remaining:
- Real-device/cross-device native validation, release signing, other-platform
  hosts, product session/state and database wiring, session authentication, and
  final UX validation remain open.

### 2026-08-17 - Codex - T268 Validate Network Payload Limit At Runtime

Summary:
- `BasicTransportFrameValidator` now rejects a non-positive payload limit at
  validation time, so release builds cannot silently classify every frame as
  oversized when configuration is invalid.
- The existing const constructor and network/package ownership remain intact.

Files:
- `packages/peerdeal_network/lib/src/services/basic_transport_frame_validator.dart`
- `packages/peerdeal_network/test/basic_transport_frame_validator_test.dart`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Direct Flutter-bundled Dart/Melos analyzer passes all 17 packages.
- The full `peerdeal_network` test suite passes, including the new runtime
  payload-limit regression.
- Boundary and source-text checks pass; their 13 and 7 script tests pass, and
  the dependency-audit script tests pass.
- `git diff --check` passes.
- A Windows native-host smoke build attempt timed out after 300 seconds without
  output; no compiler failure was emitted.

Remaining:
- Real-device/cross-device native validation, release signing, other-platform
  hosts, product session/state and database wiring, session authentication, and
  final UX validation remain open.

### 2026-08-17 - Codex - T267 Reject Conditional Revision Regression

Summary:
- Mirrored mobile and desktop local-identity and receipt-key writers now
  reject successful conditional native mutations whose returned revision is
  lower than the revision supplied by the caller.
- Nullable revisions remain compatible for legacy non-CAS bridges, and equal
  revisions remain valid for conditional no-op deletes.
- The generic native bridge contract and package ownership remain unchanged.

Files:
- Mirrored app local-identity and receipt-key writers and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Direct Flutter-bundled Dart/Melos analyzer passes all 17 packages with no
  issues.
- Boundary and source-text checks pass; their 13 and 7 script tests pass, and
  the dependency-audit script tests pass.
- Serialized non-Flutter regression tests pass across 13 packages.
- Focused mobile Flutter tests timed out after 120 seconds without test output,
  matching the known local runner limitation; no assertion failure was
  reported.
- `git diff --check` passes.

Remaining:
- Real-device secure-key/capture validation, cross-device multicast and
  release signing, other-platform native implementations, product
  session/state and durable database wiring, explicit session authentication,
  and final UX validation remain open.

### 2026-08-17 - Codex - T266 Enforce Negotiated Transport Payload Ceilings

Summary:
- Mirrored mobile and desktop native transport session factories now carry the
  validated native capability payload ceiling into both loaded-session sender
  and receiver validation.
- Existing injected app validators remain authoritative for their own rules;
  the negotiated native limit is an additional fail-closed bound.
- Custom bridge implementations can no longer accept oversized outbound or
  inbound frames after reporting a smaller native payload capability.

Files:
- Mirrored app native transport session factories and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile Flutter test invocation timed out after 180 seconds without
  test output, matching the known local Flutter runner limitation; no assertion
  failure was reported.
- The direct Flutter-bundled Dart/Melos analyzer passes all 17 packages with no
  issues.
- Boundary and source-text checks pass; their 13 and 7 script tests pass, and
  the dependency-audit script tests pass.
- Serialized non-Flutter regression tests pass across 13 packages.
- The command-level dependency audit timed out after 180 seconds without
  output in this environment; no dependency files were changed.
- `git diff --check` passes.

Remaining:
- Real-device secure-key/capture validation, cross-device multicast and
  release signing, other-platform native implementations, product session/state
  and durable database wiring, explicit session authentication, and final UX
  validation remain open.

### 2026-08-17 - Codex - T265 Validate Secure-Key Mutation Revisions

Summary:
- Mirrored local-identity and receipt-key writers now reject negative expected
  revisions before invoking native mutation bridges.
- Negative revisions returned by custom app bridges are no longer reported as
  successful writes.
- The generic secure-key channel decoder rejects successful payloads with
  malformed revision fields while preserving nullable revision compatibility
  for legacy non-CAS implementations.

Files:
- Generic secure-key channel contract and focused contract test.
- Mirrored local-identity and receipt-key writers and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- All 17 package analyzers pass with no issues.
- Direct boundary and source-text checks pass; their 13 and 7 script tests
  pass.
- Non-Flutter regression tests pass across 13 packages.
- Focused Flutter tests remain subject to the known local no-output runner
  timeout; no assertion failure was reported.
- `git diff --check` passes.

Remaining:
- Product session/state provisioning, durable database replacement,
  real-device and cross-device validation, session-auth contract, release
  signing, other-platform native implementations, and final UX remain open.

### 2026-08-17 - Codex - T264 Validate Secure-Key Consumer Snapshots

Summary:
- The generic secure-key channel decoder now rejects unusable records before
  returning an available snapshot.
- Mirrored receipt-key and local-identity loaders now reject negative snapshot
  revisions and unusable records even when a custom app bridge bypasses the
  generic decoder.
- Mirrored receipt-key loader and writer namespace validation now rejects the
  existing reserved `::` separator.
- Empty but available secure-key storage remains valid; native persistence and
  device behavior are unchanged.

Files:
- Generic secure-key channel contract and focused contract test.
- Mirrored receipt-key loaders/writers and focused tests.
- Mirrored local-identity loaders and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- All 17 package analyzers pass with no issues.
- Direct boundary and source-text checks pass; their 13 and 7 script tests
  pass.
- Focused Flutter package test timed out after 180 seconds without test output,
  matching the known local Flutter runner limitation; direct Dart fallback is
  invalid for this Flutter-dependent package because the engine libraries are
  unavailable to the bare VM.
- `git diff --check` passes.

Remaining:
- Product session/state provisioning, durable database replacement,
  real-device and cross-device validation, session-auth contract, release
  signing, other-platform native implementations, and final UX remain open.

### 2026-08-17 - Codex - T263 Validate Native Readiness Key Snapshots

Summary:
- Mirrored app native-readiness loaders now reject available secure-key
  snapshots with negative revisions, more than the locked
  `NativeBridgePayloadLimits.maxSecureKeyRecords`, or unusable key records.
- Empty but available key storage remains valid. The generic native bridge,
  receipt, and identity ownership boundaries are unchanged.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/native_readiness/app_native_readiness_loader.dart`
- Mirrored native-readiness tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Both focused Flutter readiness suites timed out after 180 seconds without
  test output, matching the known local Flutter runner limitation.
- All 17 package analyzers pass after the change.
- Direct boundary and source-text checks pass, including their 13 and 7
  script tests; serialized non-Flutter package tests pass.
- The Melos boundary/source wrappers and dependency audit timed out without
  output in the local environment; no dependency or package state changed.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T262 Bound Native App-Support Paths

Summary:
- Mirrored app recovery-store factories now apply the existing
  `NativeBridgePayloadLimits.maxAppStoragePathBytes` UTF-8 ceiling to
  app-support paths returned by custom native bridge implementations.
- This closes the app-owned decoder-bypass path while preserving the generic
  app-storage bridge contract and recovery persistence ownership.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/recovery/app_recovery_persistence_store_factory.dart`
- Mirrored recovery-store factory tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- The focused mobile Flutter recovery-store test timed out after 180 seconds
  without test output; no assertion failure was reported, matching the known
  local Flutter runner limitation.
- A direct Dart test attempt could not load the Flutter-dependent app package
  because the bare Dart VM lacks the Flutter engine libraries; this is an
  environment limitation, not a test assertion failure.
- All 17 package analyzers pass, boundary and source-text checks pass, their
  20 script tests pass, and serialized non-Flutter package tests pass.
- `git diff --check` passes.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T261 Bound Local Identity Key Records

Summary:
- Mirrored app `NativeLocalPeerIdentityLoader` owners now reject secure-key
  snapshots above `NativeBridgePayloadLimits.maxSecureKeyRecords` before
  selecting or projecting a local peer identity.
- This closes the custom-bridge path that could bypass the generic native
  secure-storage record ceiling while preserving the existing identity,
  provisioning, and writer contracts.
- The change remains app-owned session orchestration and does not add identity
  or receipt semantics to `peerdeal_native_bridges`.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/session/native_local_peer_identity_loader.dart`
- Mirrored local identity loader tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Both mirrored loader files and tests were formatted with the direct Dart
  SDK.
- Focused mobile Flutter local-identity tests timed out after 180 seconds
  without test output; no assertion failure was reported, matching the known
  local Flutter runner limitation.
- All 17 package analyzers pass with the direct Dart SDK.
- Boundary and source-text checks plus their 20 script tests pass.
- Serialized non-Flutter package tests pass.
- `git diff --check` passes.
- The dependency audit attempt recorded in T257 timed out after 600 seconds
  without output; no package state was changed.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T260 Bound Native Join Candidate Limits

Summary:
- Mirrored app `NativeJoinBootstrapCoordinator` owners now reject configured
  peer-candidate limits above `NativeBridgePayloadLimits.maxDiscoveryEntries`
  before native capability lookup or discovery parsing.
- The existing relay-fallback path now covers both non-positive and
  above-contract values, preventing custom bridges from expanding discovery
  parsing beyond the locked native entry ceiling.
- This remains app-owned join orchestration and does not change the native
  discovery channel, network contracts, or package ownership.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/join_flow/native_join_bootstrap_coordinator.dart`
- Mirrored native join bootstrap coordinator tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Both mirrored coordinator files and tests were formatted with the direct
  Dart SDK.
- Focused mobile Flutter join-flow tests timed out after 180 seconds without
  test output; no assertion failure was reported, matching the known local
  Flutter runner limitation.
- All 17 package analyzers pass with the direct Dart SDK.
- Boundary and source-text checks plus their 20 script tests pass.
- Serialized non-Flutter package tests pass.
- `git diff --check` passes.
- The dependency audit attempt recorded in T257 timed out after 600 seconds
  without output; no package state was changed.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T259 Bound Native Bootstrap Candidate Limits

Summary:
- Mirrored app `NativeBootstrapCandidateLoader` owners now reject configured
  peer-candidate limits above `NativeBridgePayloadLimits.maxDiscoveryEntries`
  before invoking native local-network capability discovery.
- The existing invalid-limit failure now covers both non-positive and
  above-contract values, keeping custom bridges from bypassing the locked
  native discovery-entry ceiling.
- This remains app-owned join/bootstrap orchestration and does not change the
  native discovery channel, network contracts, or package ownership.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- Mirrored native bootstrap candidate loader tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Both mirrored loader files and tests were formatted with the direct Dart
  SDK.
- Focused mobile Flutter bootstrap-loader tests timed out after 180 seconds
  without test output; no assertion failure was reported, matching the known
  local Flutter runner limitation.
- All 17 package analyzers pass with the direct Dart SDK.
- Boundary and source-text checks plus their 20 script tests pass.
- Serialized non-Flutter package tests pass.
- `git diff --check` passes.
- The dependency audit attempt recorded in T257 timed out after 600 seconds
  without output; no package state was changed.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T258 Bound Native Receipt Key Records

Summary:
- Mirrored app `NativeReceiptKeyRingLoader` owners now reject configured
  record limits above `NativeBridgePayloadLimits.maxSecureKeyRecords` before
  invoking native secure-key storage.
- The existing invalid-limit failure now covers both non-positive and
  above-contract values, preventing custom bridges from bypassing the locked
  native secure-storage record ceiling.
- This remains app-owned receipt orchestration and does not add receipt
  semantics to `peerdeal_native_bridges` or change the key-storage contract.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- Mirrored native receipt key-ring loader tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Both mirrored loader files and tests were formatted with the direct Dart
  SDK.
- Focused mobile Flutter receipt loader tests timed out after 180 seconds
  without test output; no assertion failure was reported, matching the known
  local Flutter runner limitation.
- All 17 package analyzers pass with the direct Dart SDK.
- Boundary and source-text checks plus their 20 script tests pass.
- Serialized non-Flutter package tests pass.
- `git diff --check` passes.
- The dependency audit attempt recorded in T257 timed out after 600 seconds
  without output; no package state was changed.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T257 Bound Native Transport Receive Batches

Summary:
- Mirrored app `NativeTransportFrameDrain` owners now reject configured
  receive-batch limits above `NativeBridgePayloadLimits.maxTransportFrames`
  before invoking the native receive bridge.
- The existing invalid-limit failure remains fail closed and now covers both
  non-positive and above-contract values, preventing custom app bridges from
  bypassing the locked native frame ceiling.
- This stays in app transport orchestration and does not change the native
  channel, protocol frame shape, package ownership, or host implementation.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/transport/native_transport_frame_adapter.dart`
- Mirrored native transport frame adapter tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Both mirrored adapter files and tests were formatted with the direct Dart
  SDK.
- Focused mobile Flutter transport tests timed out after 180 seconds without
  test output; no assertion failure was reported, matching the known local
  Flutter runner limitation.
- All 17 package analyzers pass with the direct Dart SDK.
- Boundary and source-text checks plus their 20 script tests pass.
- Serialized non-Flutter package tests pass.
- `git diff --check` passes.
- `melos run dependency-audit` timed out after 600 seconds without output;
  no package state was changed, so dependency status is not re-proven by this
  turn.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T256 Align Native Readiness Payload Limits

Summary:
- Mirrored app native-readiness loaders now reject configured transport limits
  above `NativeBridgePayloadLimits.maxTransportPayloadBytes` before invoking the
  native transport bridge.
- Reported native capability limits are checked against the same locked ceiling
  before readiness can become true.
- This aligns readiness with the T255 transport factory hardening without
  changing the native channel, protocol frame shape, package ownership, or host
  implementation.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/native_readiness/app_native_readiness_loader.dart`
- Mirrored native-readiness loader tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- All 17 package analyzers pass with the direct Dart SDK.
- Focused mobile Flutter readiness tests did not produce a result: the bounded
  180-second Flutter runner stalled without test output.
- Boundary and source-text checks plus their 20 script tests pass.
- Serialized non-Flutter package tests pass.
- `git diff --check` passes.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T255 Bound Native Transport Payload Limits

Summary:
- Mirrored app `NativeTransportSessionFactory` owners now reject configured
  payload limits above `NativeBridgePayloadLimits.maxTransportPayloadBytes`.
- Reported native capability limits are checked against the same ceiling before
  a session is exposed, and invalid limits fail closed across load, sender, and
  receiver entry points.
- This closes an app-to-native resource contract gap without changing the
  transport channel, protocol frame shape, package ownership, or host code.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/transport/native_transport_session_factory.dart`
- Mirrored native transport factory tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Mirrored app analyzers pass with the direct Dart SDK.
- Focused Flutter transport tests did not produce a result: both bounded
  180-second Flutter runner attempts stalled without test output. Plain
  `dart test` is not a valid substitute for these Flutter package tests because
  it cannot load the Flutter engine libraries.
- All 17 package analyzers pass with the direct Dart SDK.
- Boundary and source-text checks plus their 20 script tests pass.
- Serialized non-Flutter package tests pass.
- `git diff --check` passes.
- Android debug build and full Flutter app-suite verification remain
  environment-limited after bounded runner timeouts; no assertion failure was
  reported.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T254 Harden Safe Receipt Text Projection

Summary:
- Mirrored app safe receipt view models now validate status tokens and bound,
  scrub, and fail closed for unsafe receipt messages at construction time.
- This closes the app-boundary leak/DoS path without changing receipt protocol,
  artifact decoding, package ownership, or screen behavior.

Files:
- Mirrored `apps/peerdeal_{mobile,desktop}/lib/safe_surface/safe_result_projection.dart`
- Mirrored safe-surface projection tests
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Focused mirrored safe-surface Flutter tests pass: 5 tests in mobile and 5 in
  desktop.
- Direct SDK analysis passes for all 17 packages.
- Serialized non-Flutter package tests pass.
- Boundary, source-text, and their script tests pass.
- Full mobile Flutter verification did not produce a result: two bounded runs
  stalled in the local Flutter runner, the first timing out at 300 seconds; the
  desktop full suite was not started after that runner failure. No test
  assertion failure was reported.
- `git diff --check` passes.
- The dependency audit was not rerun for this dependency-free change; its
  prior invocation timed out after 180 seconds without output.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T253 Clean Stale Recovery Write Artifacts

Summary:
- The JSON recovery store now removes stale per-scope `.tmp.*` write artifacts
  under the existing scope lock before every read, write, or wipe operation.
- Cleanup is fail-closed with a stable fatal persistence conflict; no recovery
  store contract, package boundary, or database choice changed.

Files:
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Focused JSON recovery persistence suite passes (33 tests).
- Direct SDK analysis passes for all 17 packages.
- Serialized non-Flutter package tests pass.
- Full Flutter suites pass: mobile 541 tests, desktop 540 tests.
- Boundary, source-text, and their script tests pass; `git diff --check` passes.
- The latest dependency audit invocation timed out after 180 seconds without
  output; this change does not modify dependency manifests.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T252 Verify Persisted Hold'em Event Suffixes

Summary:
- Mirrored app-owned Hold'em persistence writers now read back and compare the
  exact event envelopes before honoring `eventsAlreadyPersisted` during ordered
  snapshot retries.
- A missing, changed, or unavailable event suffix fails closed before snapshot
  persistence; normal append-first retry behavior and package ownership remain
  unchanged.

Files:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_persistence_writer.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_persistence_writer.dart`
- Mirrored persistence-writer tests under `apps/peerdeal_{mobile,desktop}/test/session`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Mirrored focused persistence-writer suites pass (11 tests each).
- Direct SDK analysis passes for all 17 packages.
- Serialized non-Flutter package tests pass.
- Full Flutter suites pass: mobile 541 tests, desktop 540 tests.
- Boundary, source-text, and their script tests pass; `git diff --check` passes.
- The current dependency audit timed out after 180 seconds without output; no
  dependency changes were made.

Remaining:
- Product session/state provisioning, durable database replacement, real-device
  and cross-device validation, session-auth contract, release signing, and
  final UX remain separate readiness work.

### 2026-08-17 - Codex - T251 Bound Native Receive Error Retries

Summary:
- Mirrored Android and Windows multicast receive loops now wait 25 ms after a
  persistent socket error before retrying, preventing a host failure from
  becoming a busy CPU loop.
- Preserved the generic byte-frame channel contract, host-private envelope,
  filtering, and package ownership.

Files:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Android debug APK, Windows debug build, and all Windows native-host smoke
  markers pass.
- Direct Dart-SDK analysis, boundary, source-text, and their script-test gates
  pass; `git diff --check` passes.
- The Melos analyze/boundary wrappers and the full non-Flutter Dart test
  invocation timed out silently in this environment; no Dart source changed.
- Dependency audit also timed out while resolving external package metadata;
  the last completed audit reported zero actionable upgrades.

Remaining:
- Real-device and cross-device transport validation, product session/state
  provisioning, durable database persistence, release signing, and final UX
  remain separate readiness work.

### 2026-08-16 - Codex - T250 Align App Diagnostic Text Boundaries

Summary:
- Mirrored mobile and desktop app warning, diagnostic, fallback, route, safe
  display, recovery, identity, transport, receipt, bootstrap, join, and demo
  helpers now reject or scrub C0/C1-control-bearing text consistently.
- Preserved app/package ownership, native bridge contracts, route policy, and
  stable fail-closed diagnostics.

Files:
- Mirrored app files under `apps/peerdeal_mobile/lib` and
  `apps/peerdeal_desktop/lib`, with focused regression fixtures.
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Focused mobile and desktop app suites pass (106 tests each).
- Full `analyze`, `boundary-check`, `source-text`, serialized `test`,
  `dependency-audit`, formatter, and `git diff --check` gates pass.
- Dependency audit reports 0 actionable upgrades and 11 newer-resolvable
  versions below the current toolchain ceiling.

Remaining:
- Concrete product source/state selection, durable database persistence,
  real-device/network validation, remaining platform hosts, signing, and final
  UX remain separate readiness work.

### 2026-08-16 - Codex - T249 Harden App Production-Session Text Boundaries

Summary:
- Mirrored mobile and desktop production-session bootstrap invite identities,
  persisted route-policy metadata, and final route metadata now reject blank,
  padded, and C0/C1-control-bearing values before source or native route use.
- Product source/state ownership, persistence policy, transport contracts, and
  authentication scope remain unchanged.

Files:
- Mirrored files under `apps/peerdeal_mobile/lib/session` and
  `apps/peerdeal_desktop/lib/session`, with focused session tests.
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`

Verification:
- Focused mobile and desktop production-session suites pass (42 tests each).
- Full analyze, boundary-check, source-text, serialized test, dependency-audit,
  format, and diff checks pass; actionable dependency upgrades: 0.

Remaining:
- Concrete product source/state selection, durable database persistence,
  real-device/network validation, remaining platform hosts, signing, and final
  UX remain separate readiness work.

### 2026-08-16 - Codex - T248 Align Protocol/Core Text Boundaries

Summary:
- Extended invite required-text validation and core command/scope identity
  validation to reject C0/C1 control-bearing values, matching the existing
  native, network, and variant boundary policy.
- Preserved existing diagnostics, catalog behavior, wire shape, authentication
  scope, and package ownership.

Files:
- `packages/peerdeal_protocol/lib/src/schemas/invite_payload_schema.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `packages/peerdeal_protocol/README.md`
- `packages/peerdeal_core/lib/src/validation/core_command_validator.dart`
- `packages/peerdeal_core/test/peerdeal_core_test.dart`
- `packages/peerdeal_core/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Verification:
- Focused protocol and core suites pass (53 and 33 tests respectively).
- Full analyze, boundary-check, source-text, serialized test, dependency-audit,
  and diff checks pass; actionable dependency upgrades: 0.

Remaining:
- Real-device native validation, product session/state integration, durable
  product persistence, release signing, and final UX remain separate readiness
  work.

### 2026-08-16 - Codex - T247 Harden Hold’em Event Text Boundaries

Summary:
- Hardened `HoldemEventReducer` required public text, board-card lists,
  showdown summaries, settlement IDs, and award seat IDs against blank,
  padded, and C0/C1 control-bearing values.
- Preserved existing variant-specific rejection codes and input-state
  immutability; no protocol fields, wire authentication, or package boundaries
  changed.

Files:
- `packages/peerdeal_variants/lib/src/holdem/holdem_event_reducer.dart`
- `packages/peerdeal_variants/test/holdem_event_reducer_test.dart`
- `packages/peerdeal_variants/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`

Verification:
- Focused Hold’em event reducer tests pass.
- Full analyze, boundary-check, source-text, serialized test, dependency-audit,
  and diff checks remain required before commit.

Risks:
- Cryptographic session authentication, provider-specific proof semantics,
  product persistence, live device/network validation, release signing, and
  final UX remain separate readiness work.

### 2026-08-16 - Codex - T246 Reject Unsafe Transport Identities

Summary:
- Hardened `BasicTransportFrameValidator` so session and peer identities reject
  embedded C0/C1 control characters as malformed before transport sinks or
  session handlers are called.
- Reused the existing malformed-identity diagnostics and preserved the
  `TransportFrame` shape, native bridge contract, and package boundaries.

Files:
- `packages/peerdeal_network/lib/src/services/basic_transport_frame_validator.dart`
- `packages/peerdeal_network/test/basic_transport_frame_validator_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`

Verification:
- Focused network validator tests and full repository gates remain required
  before commit.

Risks:
- Cryptographic session authentication, product persistence, live device and
  network validation, release signing, and final UX remain separate readiness
  work.

### 2026-08-16 - Codex - T245 Enforce Network Transport Byte Range

Summary:
- Hardened `BasicTransportFrameValidator` so transport payload entries must be
  bytes in the inclusive 0-through-255 range.
- Invalid entries now fail before validating send/receive boundaries call
  platform adapters or handlers; the existing native bridge byte checks remain
  as defense in depth.
- Preserved the existing `TransportFrame` shape and all package boundaries;
  this does not add protocol fields or authentication semantics.

Files:
- `packages/peerdeal_network/lib/src/services/basic_transport_frame_validator.dart`
- `packages/peerdeal_network/test/basic_transport_frame_validator_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`

Verification:
- Focused network validator tests passed.
- Full analyze, boundary-check, source-text, serialized test, dependency-audit,
  and diff checks remain required before commit.

Risks:
- Real device/network reachability, endpoint provisioning, cryptographic
  session authentication, product persistence, release signing, and final UX
  remain separate readiness work.

### 2026-08-16 - Codex - T244 Harden Invite Payload Structure

Summary:
- Hardened `InvitePayloadSchema` so present required invite fields must be
  non-empty, unpadded, control-free strings and `mode_type` must be
  `tournament` or `open_table`.
- Kept signature verification and cryptographic session authentication outside
  this structural protocol change; no package boundary or wire-auth contract
  was invented.

Files:
- `packages/peerdeal_protocol/lib/src/schemas/invite_payload_schema.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `packages/peerdeal_protocol/README.md`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused protocol suite passed (53 tests).
- Full analyze, boundary-check, source-text, serialized test, and dependency
  audit gates passed; actionable upgrades: 0.
- Final `git diff --check` passed.

Risks:
- Cryptographic invite/session authentication, provider-specific fairness
  semantics, product session/state provisioning, durable database replacement,
  live device/network validation, release signing, and final UX remain separate.

### 2026-08-16 - Codex - T243 Preserve Matched-But-Unacted Hold'em Options

Summary:
- Fixed `HoldemActionFlow` so matching the current bet does not implicitly
  count as acting. A matched seat that has not acted remains eligible for its
  check, raise, or call decision, including the big blind option and a
  post-short-all-in call.
- Kept the rule inside `peerdeal_variants`; protocol, core, sync, network,
  native, and app contracts are unchanged.

Files:
- `packages/peerdeal_variants/lib/src/holdem/holdem_action_flow.dart`
- `packages/peerdeal_variants/test/holdem_action_flow_test.dart`
- `packages/peerdeal_variants/test/holdem_action_applier_test.dart`
- `packages/peerdeal_variants/test/holdem_action_street_coordinator_test.dart`
- `packages/peerdeal_variants/test/holdem_core_projection_adapter_test.dart`
- `packages/peerdeal_variants/test/holdem_event_reducer_test.dart`
- `packages/peerdeal_variants/test/holdem_lifecycle_settlement_test.dart`
- `apps/peerdeal_mobile/test/session/app_holdem_table_session_runtime_test.dart`
- `apps/peerdeal_desktop/test/session/app_holdem_table_session_runtime_test.dart`
- `packages/peerdeal_variants/README.md`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused Hold'em action-flow/applier/street-coordinator tests passed.
- Full `peerdeal_variants` suite passed (162 tests).
- Full mobile and desktop Flutter suites passed (535 and 534 tests).
- Repository analyze, boundary-check, source-text, and serialized test gates passed.
- Dependency audit passed with zero actionable upgrades.
- Final `git diff --check` passed.

Risks:
- Product session/state provisioning, cryptographic session authentication,
  provider-specific fairness semantics, durable database replacement, live
  device/network validation, release signing, and final UX remain separate.

### 2026-08-16 - Codex - T242 Enforce Short-All-In Raise Reopening

Summary:
- `BasicHoldemActionValidator` now rejects a raise from a seat that already
  acted since the last full raise when a short all-in increased the amount to
  call without reopening action.
- The same gate rejects an all-in that would be a full raise in that state,
  while preserving legal short all-in calls.

Files changed:
- `packages/peerdeal_variants/lib/src/holdem/holdem_action_validator.dart`
- `packages/peerdeal_variants/test/holdem_action_validator_test.dart`
- `packages/peerdeal_variants/README.md`
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused validator and reducer regressions plus the complete
  `peerdeal_variants` suite pass.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass; Android debug, Windows debug, and all 16 Windows native-host
  smoke markers pass.

Risks:
- This closes the existing variant-local no-limit reopen rule without adding
  protocol fields or moving poker policy outside `peerdeal_variants`.

### 2026-08-16 - Codex - T241 Cancel Queued Inbound Checkpoints

Summary:
- Mirrored mobile and desktop `AppHoldemTableSessionRoute` instances now pass
  their current transport lifecycle generation into inbound-event checkpoint
  persistence.
- The existing snapshot coordinator suppresses a queued accepted-remote-event
  checkpoint after route replacement while preserving the ownership of any
  already-running recovery-store call.

Files changed:
- Mirrored `app_holdem_table_session_route.dart` files and snapshot coordinator
  regression tests.
- `docs/ARCHITECTURE.md`, `docs/PRODUCTION_READINESS.md`,
  `docs/ai/API_CONTRACTS.md`, and this handoff log.

Verification:
- Focused mobile and desktop route and snapshot-coordinator suites pass.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass; Android debug APK, Windows debug, and all 16 Windows native-host
  smoke markers pass.

Risks:
- This closes app lifecycle queueing only; it does not add transport
  acknowledgements, cryptographic session authentication, or a durable
  outbound-sync queue.

### 2026-08-16 - Codex - T240 Cancel Queued Stale Checkpoints

Summary:
- Mirrored mobile and desktop production table surfaces now bind checkpoint
  persistence to the current route operation generation.
- The existing app snapshot coordinators check that predicate before queueing
  and again inside the serialized callback, preventing a replaced route from
  writing stale typed state while preserving FIFO retry and the existing
  persistence ownership of already-running store calls.

Files changed:
- Mirrored `app_holdem_production_session_snapshot_coordinator.dart`,
  `app_holdem_production_table_surface.dart`, and production route tests.
- `docs/ARCHITECTURE.md`, `docs/PRODUCTION_READINESS.md`,
  `docs/ai/API_CONTRACTS.md`, and this handoff log.

Verification:
- Focused mobile and desktop production route suites pass, including the
  stale-checkpoint replacement regression.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass; Android debug APK, Windows debug, and all 16 Windows native-host
  smoke markers pass.

Risks:
- Already-dispatched recovery-store calls remain host/store-owned. This change
  does not add network acknowledgements, an outbound durable sync queue, or a
  new protocol contract.

### 2026-08-16 - Codex - T239 Wire Native Receipt Flow Into App Startup

Summary:
- Mirrored mobile and desktop executable entrypoints now provide the existing
  native-backed receipt export and artifact-verifier factories by default.
  Mounted receipt routes therefore use native key provisioning and verification
  without requiring a separate caller injection.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `apps/peerdeal_desktop/lib/demo_slice/README.md`
- `docs/ARCHITECTURE.md`, `docs/PRODUCTION_READINESS.md`,
  `docs/ai/API_CONTRACTS.md`, and this handoff log.

Verification:
- Focused mobile and desktop app-shell suites pass.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass; Android debug APK, Windows debug, and Windows native-host smoke
  builds pass.

Risks:
- Receipt routes now fail closed when native key storage is unavailable; no
  native bridge contract, receipt policy, or package boundary changed.

### 2026-08-16 - Codex - T238 Block Actions During Pending Projection Work

Summary:
- Mirrored mobile and desktop production Hold'em surfaces now fail closed for
  new local hand starts and actions while a projection or snapshot checkpoint
  is pending. Existing retry controls remain available.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_table_surface.dart`
- `apps/peerdeal_mobile/test/session/app_holdem_table_session_route_test.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_table_surface.dart`
- `apps/peerdeal_desktop/test/session/app_holdem_table_session_route_test.dart`
- `docs/ARCHITECTURE.md`, `docs/PRODUCTION_READINESS.md`,
  `docs/ai/API_CONTRACTS.md`, and this handoff log.

Verification:
- Focused mobile and desktop production-table route suites pass.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass; Android debug APK, Windows debug, and Windows native-host smoke
  builds pass.

Risks:
- Local actions remain unavailable until retry clears older pending work; no
  protocol, core, sync, or native bridge contract changed.

### 2026-08-16 - Codex - T237 Make Native Smoke Key Cleanup Failure-Safe

Summary:
- The Windows native-host smoke harness now tracks successful smoke-key writes
  and removes the key in a terminal cleanup path if a later checkpoint fails.
  Successful conditional deletion clears the cleanup marker before read-back.

Files changed:
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart`
- `docs/PRODUCTION_READINESS.md` and `docs/ai/HANDOFF_LOG.md`.

Verification:
- Focused Dart analysis, Windows smoke-target build, and native-host smoke pass.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass.

Risks:
- Cleanup failure remains a smoke failure; the secure-key native contract and
  production host implementation are unchanged.

### 2026-08-16 - Codex - T236 Guard Initial Snapshot Checkpoint Cancellation

Summary:
- Mirrored mobile and desktop persisted production-session sources now check
  route cancellation before and after initial typed snapshot checkpointing.
  Cancelled loads fail closed without returning a production input.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_persisted_holdem_production_session_source.dart`
- `apps/peerdeal_mobile/test/session/app_persisted_holdem_production_session_source_test.dart`
- `apps/peerdeal_desktop/lib/session/app_persisted_holdem_production_session_source.dart`
- `apps/peerdeal_desktop/test/session/app_persisted_holdem_production_session_source_test.dart`
- `docs/PRODUCTION_READINESS.md`, `docs/ARCHITECTURE.md`, and
  `docs/ai/API_CONTRACTS.md`.

Verification:
- Focused mobile and desktop persisted-session source suites pass.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass; Android debug APK, Windows debug, and Windows native-host smoke
  builds pass.

Risks:
- A checkpoint already dispatched remains owned by the persistence boundary
  until it settles; no package, snapshot, or native bridge contract changed.

### 2026-08-16 - Codex - T235 Stop Transport Source After Route Cancellation

Summary:
- Mirrored mobile and desktop transport sources now stop active polling when
  external route cancellation wins, reject restart and later polls, and retain
  only already-started drain work until it settles.

Files changed:
- `apps/peerdeal_mobile/lib/transport/app_table_session_transport_source.dart`
- `apps/peerdeal_mobile/test/transport/app_table_session_transport_source_test.dart`
- `apps/peerdeal_desktop/lib/transport/app_table_session_transport_source.dart`
- `apps/peerdeal_desktop/test/transport/app_table_session_transport_source_test.dart`
- `docs/PRODUCTION_READINESS.md`, `docs/ARCHITECTURE.md`, and
  `docs/ai/API_CONTRACTS.md`.

Verification:
- Focused mobile and desktop transport-source suites pass.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass; Android debug APK, Windows debug, and Windows native-host smoke
  builds pass.

Risks:
- A native drain already dispatched remains host-owned; no protocol, native
  bridge, or transport frame contract changed.

### 2026-08-16 - Codex - T234 Propagate Production Source Timeout Cancellation

Summary:
- Mirrored mobile and desktop production-session bootstraps now pass each
  source load an idempotent app-owned cancellation signal. Caller cancellation
  and source timeout complete that signal before the bootstrap fails closed.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_bootstrap.dart`
- `apps/peerdeal_mobile/test/session/app_holdem_production_session_bootstrap_test.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_bootstrap.dart`
- `apps/peerdeal_desktop/test/session/app_holdem_production_session_bootstrap_test.dart`
- `docs/PRODUCTION_READINESS.md`, `docs/ARCHITECTURE.md`, and
  `docs/ai/API_CONTRACTS.md`.

Verification:
- Focused mobile and desktop bootstrap suites pass.
- Full analyze, boundary, source-text, serialized test, and dependency-audit
  gates pass; Android debug APK, Windows debug, and Windows native-host smoke
  builds pass.

Risks:
- Source implementations still own cancellation of persistence or native work
  beneath the app boundary; already-dispatched host calls remain host-owned.

### 2026-08-16 - Codex - T233 Close Transport Replacement Race

Summary:
- Mirrored mobile and desktop production table surfaces now invalidate pending
  projection work when the transport session/source identity changes, so a
  stale send completion cannot publish through a replacement transport.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_table_surface.dart`
- `apps/peerdeal_mobile/test/session/app_holdem_table_session_route_test.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_table_surface.dart`
- `apps/peerdeal_desktop/test/session/app_holdem_table_session_route_test.dart`
- `docs/PRODUCTION_READINESS.md`, `docs/ARCHITECTURE.md`, and
  `docs/ai/API_CONTRACTS.md`.

Verification:
- Focused mobile and desktop stale-completion regressions passed.
- Full repository gates and Android/Windows debug builds passed after this
  handoff update.

Risks:
- This is app lifecycle hardening only; protocol, native bridge, runtime state,
  and transport contracts are unchanged.

### 2026-08-16 - Codex - T232 Close Transport and State Invariant Gaps

Summary:
- Mirrored mobile and desktop production routes now carry remote and local
  peer identities separately. Native receive filtering uses the local peer,
  and configured app transport handlers reject sender or recipient mismatches
  before event decode or runtime mutation.
- `EventEnvelopeCodec.decode` stops consuming an input iterable at the
  configured byte limit instead of materializing an unbounded iterable.
- Core `SessionWiped` requires a prior `SessionClosed` event. Inbound Hold'em
  `SettlementProjected` requires non-empty positive awards whose total equals
  the current pot.

Files changed:
- Mirrored mobile and desktop transport handlers, provisioners, production
  route registrations, routes, and focused tests.
- `packages/peerdeal_protocol` event codec/test, `packages/peerdeal_core`
  lifecycle reducer/invariant code/test, and `packages/peerdeal_variants`
  settlement reducer/test.
- `docs/PRODUCTION_READINESS.md`, `docs/ARCHITECTURE.md`, and
  `docs/ai/API_CONTRACTS.md`.

Verification:
- Focused mobile and desktop transport/provisioner/route tests passed.
- Protocol codec, core lifecycle, and Hold'em reducer/settlement tests passed.
- Full repository gates remain required after this handoff update.

Risks:
- Existing frame identity checks bind configured route scope but do not provide
  cryptographic peer authenticity. A keyed session-auth contract is not added
  because it is not present in the locked protocol/native architecture.
- Real-device, cross-device, other-platform, release-signing, and product-owned
  session/database validation remain external or integration-owned.

Next reviewer:
- Run the complete repository gates, then continue only with the documented
  external/platform or product-owned production inputs.

### 2026-08-16 - Codex - T230 Enforce Release Limit Invariants

Summary:
- Replaced assert-only positive-limit checks with explicit runtime
  `ArgumentError` validation at public operations in core, sync, network,
  variants, modes, and wizard services.
- Receipt signing-key and key-ring snapshot constructors now validate limits at
  runtime as well; existing const APIs and bounded input result contracts are
  preserved.
- Added focused regression tests for the const-configured service boundaries
  and updated receipt expectations from debug-only assertions to runtime
  argument errors.

Verification:
- Focused release-configuration tests passed for core, network, sync, variants,
  modes, and wizard.
- Focused receipt signer and key-ring snapshot suites passed.
- Full analyze, boundary-check, source-text, serialized test, and dependency
  audit gates passed; actionable upgrades: 0.
- Android debug APK, Windows debug build, and `git diff --check` passed.

Risks:
- Native runtime/device validation, real local-network discovery and endpoint
  provisioning, other-platform secure storage, durable product state/database
  wiring, operator release signing, and final UI/accessibility validation
  remain external or integration-owned gaps.

Next reviewer:
- Continue only with product-owned state or externally validated runtime work;
  preserve the existing architecture and package boundaries.

### 2026-08-16 - Codex - T231 Align CI Toolchain Baseline

Summary:
- Updated GitHub Actions to activate Melos `8.3.0`, matching the root
  workspace dependency and lockfile.
- Updated `docs/ai/REPO_BRIEF.md` to report the current Melos baseline.
- No package boundary, runtime, or architecture behavior changed.

Verification:
- Windows native-host smoke passed all required storage, capture, transport,
  discovery, and secure-key checkpoints.
- Local analyze, boundary, source-text, serialized test, dependency-audit,
  Android debug, Windows debug, and diff gates were green for T230.

Risks:
- CI platform execution still requires GitHub-hosted runner validation; real
  Android device/network reachability, other-platform hosts, product database
  wiring, release signing, and final UX validation remain open.

Next reviewer:
- Keep CI toolchain pins synchronized with the root lockfile when dependencies
  change; continue only with existing app-owned production seams.

### 2026-08-12 - Codex - T221 Bound Transport Result Warnings

Summary:
- Mirrored native frame-drain, transport-source, and transport-provision result
  models now scrub unsafe warning text at construction.
- Warning collections are capped at four entries with stable truncation markers;
  source-level markers preserve the existing diagnostic contract across the
  lower-level frame boundary.
- Added mirrored direct-constructor regressions for bounds, scrubbing, and
  immutable outputs.

Verification:
- Mirrored mobile and desktop transport-focused suites passed.
- Full repository analyze, boundary, source-text, dependency, and test gates
  passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, durable product state, other-platform hosts, and release
  signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T222 Bound Native Session Factory Warnings

Summary:
- Mirrored `NativeTransportSessionLoadResult` and unavailable sender models now
  scrub unsafe warning text at construction.
- Warning collections are capped at four entries with stable truncation markers
  before results reach the app transport provisioner or source.
- Added mirrored direct-load-result regressions while preserving the generic
  native bridge contract and existing fail-closed behavior.

Verification:
- Mirrored mobile and desktop transport suites passed.
- Full repository analyze, boundary, source-text, dependency, and test gates
  passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, durable product state, other-platform hosts, and release
  signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T223 Bound Native Readiness Warnings

Summary:
- Mirrored `AppNativeReadinessSnapshot` constructors now scrub control-bearing,
  padded, and oversized warning text at the app-shell aggregate boundary.
- Direct readiness snapshots cap warnings at four entries with a stable
  truncation marker; loader-produced capability warnings remain unchanged.
- Added mirrored direct-snapshot regression coverage.

Verification:
- Mirrored mobile and desktop native-readiness suites passed.
- Full repository analyze, boundary, source-text, dependency, and test gates
  passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, durable product state, other-platform hosts, and release
  signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T224 Bound Local Identity Warnings

Summary:
- Mirrored local identity load and provision result constructors now scrub
  control-bearing, padded, and oversized warning text.
- Both result types cap direct warning collections at four entries with stable
  labels and truncation markers while preserving existing success/missing
  semantics.
- Added mirrored direct-result regression coverage alongside existing
  cancellation, single-flight, revision, and persistence read-back tests.

Verification:
- Mirrored mobile and desktop local-identity suites passed.
- Full repository analyze, boundary, source-text, dependency, and test gates
  passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, cross-process/device persistence, durable product state,
  other-platform hosts, and release signing remain external or
  integration-owned.

---

### 2026-08-12 - Codex - T225 Bound Receipt Key-Ring Warnings

Summary:
- Mirrored receipt key-ring load and provision result constructors now scrub
  control-bearing, padded, and oversized warning text.
- Direct warning collections are capped at four entries with stable
  lower-layer fallback and truncation markers before receipt verification or
  provisioning surfaces receive them.
- The receipt artifact verifier translates lower-layer markers into its stable
  public diagnostics without changing the generic native secure-key contract or
  fail-closed signing/encryption behavior.

Files changed:
- Mirrored mobile and desktop receipt key-ring loaders, provisioners, verifier
  adapters, and focused tests.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile receipt loader, provisioner, and verifier suite passed (37
  tests).
- Focused desktop receipt loader, provisioner, and verifier suite passed (37
  tests).
- Full `melos run test`, analyze, boundary-check, source-text, and dependency
  audit gates passed; actionable upgrades: 0.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Native secure-key storage still needs real-device/platform validation;
  cross-device reachability, other-platform hosts, durable product state and
  database wiring, and release signing remain external or integration-owned.

Next reviewer:
- Continue with the next documented production gap after the committed green
  T225 change; keep receipt semantics in the app and receipt packages.

---

### 2026-08-16 - Codex - T226 Bound Production Configuration Warnings

Summary:
- Mirrored `AppHoldemProductionSessionConfigurationLoadResult` constructors
  now scrub control-bearing, padded, and oversized warning text.
- Direct configuration warning collections are capped at four entries with a
  stable fallback and truncation marker before route loading receives them.
- The existing Melos dev dependency is aligned from 8.2.2 to the newest
  resolvable 8.3.0 release; no package boundary or runtime architecture
  changed.

Files changed:
- Mirrored mobile and desktop production-session configuration factories and
  focused tests.
- Root `pubspec.yaml` and `pubspec.lock`.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile production-session configuration suite passed (11 tests).
- Focused desktop production-session configuration suite passed (11 tests).
- Full `melos run test`, analyze, boundary-check, and source-text gates passed.
- Dependency audit passed with 0 actionable upgrades and 11 newer versions
  below the current toolchain ceiling.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Concrete product state/database source wiring, native runtime/device
  validation, cross-device reachability, other-platform hosts, and release
  signing remain external or product-owned boundaries.

Next reviewer:
- Continue with the next production gap without inventing product state or
  moving session truth out of the established app/core boundaries.

---

### 2026-08-16 - Codex - T227 Bound Projection Publish Warnings

Summary:
- Mirrored `AppHoldemProjectionPublishResult` constructors now pass direct
  warning input through the existing publisher sanitizer before exposing it.
- Control-bearing, padded, oversized, and excess warning values are bounded at
  the app-owned projection transport result boundary; output remains immutable.
- Projection events, native transport contracts, variant rules, and session
  truth ownership are unchanged.

Files changed:
- Mirrored mobile and desktop projection publisher implementations and runtime
  regression suites.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile projection/runtime suite passed (12 tests).
- Focused desktop projection/runtime suite passed (12 tests).
- Full `melos run test`, analyze, boundary-check, source-text, and dependency
  audit gates passed; actionable upgrades: 0.
- Android debug APK and Windows debug artifacts built successfully.
- `git diff --check` passed.

Risks:
- Concrete product state/database source wiring, native runtime/device
  validation, cross-device reachability, other-platform hosts, and release
  signing remain external or product-owned boundaries.

Next reviewer:
- Continue toward the concrete app-owned product session source and durable
  event/snapshot integration without adding a new package or moving state truth
  into UI, native bridges, or generic recovery storage.

---

### 2026-08-16 - Codex - T228 Bound App Session Result Warnings

Summary:
- Mirrored `AppTableSessionEventResult` and
  `AppTableSessionEventBatchResult` constructors now scrub unsafe warning text,
  cap direct warning collections at four entries, and preserve a stable
  truncation marker.
- Mirrored `AppHoldemInboundEventResult` constructors now apply the same
  bounded, immutable diagnostic policy at the variant inbound boundary.
- Core state projection, event identity, variant rules, and transport
  contracts are unchanged.

Files changed:
- Mirrored mobile and desktop app table-session and Hold'em runtime models.
- Mirrored runtime regression suites.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile table-session and Hold'em runtime suites passed (22 tests).
- Focused desktop table-session and Hold'em runtime suites passed (22 tests).
- Full `melos run test`, analyze, boundary-check, source-text, and dependency
  audit gates passed; actionable upgrades: 0.
- Android debug APK and Windows debug artifacts built successfully.
- `git diff --check` passed.

Risks:
- Concrete product state/database source wiring, native runtime/device
  validation, cross-device reachability, other-platform hosts, and release
  signing remain external or product-owned boundaries.

Next reviewer:
- Continue toward concrete product-owned session/state and durable event-log
  integration without inventing a database or moving game truth across the
  established package boundaries.

---

### 2026-08-16 - Codex - T229 Bound Setup and Recovery Diagnostics

Summary:
- Mirrored `SetupFlowOutcome` constructors now apply the existing four-entry
  setup token policy to direct error and warning collections, preserving stable
  fallback and truncation markers with immutable output.
- Mirrored `AppRecoveryPersistenceStoreLoadResult` constructors now scrub
  control-bearing, padded, and oversized warning text and cap direct warning
  collections at four entries.
- Setup orchestration, recovery storage, route ownership, and package
  boundaries are unchanged.

Files changed:
- Mirrored mobile and desktop setup-flow models and recovery-store factories.
- Mirrored setup model-ownership and recovery-factory regression suites.
- `docs/PRODUCTION_READINESS.md` and this handoff log.

Verification:
- Focused mobile setup/recovery suites passed (16 tests).
- Focused desktop setup/recovery suites passed (16 tests).
- Full `melos run test`, analyze, boundary-check, source-text, and dependency
  audit gates passed; actionable upgrades: 0.
- Android debug APK and Windows debug artifacts built successfully.
- `git diff --check` passed.

Risks:
- Concrete product state/database source wiring, native runtime/device
  validation, cross-device reachability, other-platform hosts, and release
  signing remain external or product-owned boundaries.

Next reviewer:
- Move to the concrete product-owned session/state source and durable event-log
  integration; do not invent a database or move game truth across the existing
  package boundaries.

---

### 2026-08-12 - Codex - T218 Unify Demo Bootstrap Endpoint Handling

Summary:
- Removed the duplicated mobile and desktop demo endpoint parser and metadata
  projector.
- Mirrored `NativeBootstrapCandidateLoader` implementations now use the shared
  bounded `peerdeal_network` parser and projector with the native 64-entry
  discovery budget, preserving provider-owned host/port metadata.
- Bounded direct interface-hint traversal and added mirrored oversized-input
  regressions.

Verification:
- Mirrored mobile and desktop demo bootstrap suites passed.
- Mirrored app analyzers reported no issues.
- Full repository analyze, boundary, source-text, dependency, and test gates
  passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, durable product state, other-platform hosts, and release
  signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T219 Harden Demo Bootstrap Scope Inputs

Summary:
- Mirrored demo bootstrap loaders now apply the shared safe UTF-8 transport
  identity boundary to session and table scope before native capability lookup
  or provider resolution.
- Added mirrored control-bearing scope regressions; padded and empty scope
  behavior remains fail-closed.

Verification:
- Mirrored mobile and desktop demo bootstrap suites passed.
- App analyzers and full repository gates passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, durable product state, other-platform hosts, and release
  signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T220 Bound Demo Table Result Models

Summary:
- Mirrored `NativeBootstrapCandidateLoadResult` constructors now cap candidate
  and warning collections and retain stable truncation markers.
- Mirrored `DemoRecoveryPersistenceLoadResult` constructors now cap warnings,
  normalize negative counts, and cap persisted-event display counts with an
  explicit truncation marker.
- Screen-level warning scrubbing remains the final presentation boundary.

Verification:
- Mirrored mobile and desktop bootstrap/table focused suites passed.
- Full repository analyze, boundary, source-text, dependency, and test gates
  passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, durable product state, other-platform hosts, and release
  signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T217 Bound Endpoint Parser Traversal

Summary:
- Bounded direct traversal of caller-provided discovery values in
  `DiscoveredPeerEndpointParser.parseAll`.
- Bounded both endpoint and candidate traversal in
  `DiscoveredPeerEndpointParser.projectCandidates`, preserving immutable
  output and existing provider metadata precedence.
- Added regressions for values and endpoint metadata after the inspection
  boundary.

Verification:
- Focused network parser and bootstrap-provider tests passed.
- Full repository analyze, boundary, source-text, dependency, and test gates
  passed.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, durable product state, other-platform hosts, and release
  signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T216 Preserve Bootstrap Endpoint Handoff

Summary:
- Added the network-owned `DiscoveredPeerEndpoint` parser for the existing
  `peer-id` and `peer-id@host[:port]` discovery values, with bounded validation
  and provider-metadata preservation.
- Mirrored mobile and desktop native join coordinators now retain the selected
  `BootstrapCandidate` instead of reducing it to a peer-ID-only plan.
- `BootstrapPlan`, `JoinFlowSessionContext`, and the safe route boundary now
  carry and validate optional selected host/port metadata while preserving the
  existing peer-ID and relay fallback contracts.

Files changed:
- `packages/peerdeal_network/lib/src/models/discovered_peer_endpoint.dart`
- `packages/peerdeal_network/lib/src/services/discovered_peer_endpoint_parser.dart`
- `packages/peerdeal_network/test/discovered_peer_endpoint_parser_test.dart`
- mirrored mobile and desktop `join_flow_models.dart`,
  `native_join_bootstrap_coordinator.dart`, `join_flow_orchestrator.dart`,
  `join_flow_route.dart`, `fakes.dart`, and focused tests

Verification:
- Network parser/provider tests passed.
- Mirrored mobile and desktop native-bootstrap and join-orchestrator suites
  passed.
- Full repository gates and app/native artifact validation remain required.

Risks:
- Native discovery advertisement, real endpoint provisioning, device/network
  reachability, durable product state, other-platform hosts, and release
  signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T215 Verified Snapshot Replay Hydration

Summary:
- `BasicReplayEngine` now recomputes the canonical snapshot payload hash and
  rejects negative snapshot base sequences before selection or projection.
- Snapshot replay requires the optional `ReplaySnapshotStateProjector` contract
  and applies the ordered suffix to typed hydrated snapshot state instead of
  silently rebuilding from a fresh base state.
- Existing no-snapshot replay remains compatible; projector absence and tampered
  snapshot payloads return stable fail-closed mismatch codes.

Files changed:
- `packages/peerdeal_replay/lib/src/contracts/replay_state_projector.dart`
- `packages/peerdeal_replay/lib/src/engine/basic_replay_engine.dart`
- `packages/peerdeal_replay/test/fakes/fake_table_projector.dart`
- `packages/peerdeal_replay/test/basic_replay_engine_test.dart`
- `packages/peerdeal_replay/README.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused `peerdeal_replay` suite: 39 tests passed.
- Full repository gates and app/native artifact validation remain required.

Risks:
- Product-owned snapshot payload projectors, durable database persistence,
  device/network validation, other-platform hosts, provider-specific proof
  semantics, and release signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T214 Fail-Closed Verification Input Boundary

Summary:
- `DefaultVerificationEngine` now validates request identity, anchors, hand
  scope shape, and positive ordered event windows before projecting evidence
  layers.
- Directly constructed proof bundles now receive the same bounded canonical
  JSON and provider metadata checks as normalized bundles through configurable
  `DealProofLimits`.
- The normalizer now applies safe text checks to provider ID, version, and
  proof reference while preserving bounded arbitrary JSON text in proof fields.
- Malformed verifier inputs return scrubbed `errVerificationDataIncomplete`
  failures without echoing untrusted values; provider-specific proof semantics
  remain intentionally outside this generic package boundary.

Files changed:
- `packages/peerdeal_crypto/lib/src/services/default_verification_engine.dart`
- `packages/peerdeal_crypto/lib/src/services/default_provider_proof_normalizer.dart`
- `packages/peerdeal_crypto/test/default_verification_engine_test.dart`
- `packages/peerdeal_crypto/test/default_provider_proof_normalizer_test.dart`
- `packages/peerdeal_crypto/README.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused `peerdeal_crypto` suite: 18 tests passed after the metadata alignment.
- Full repository gates, app builds, and Windows native-host smoke remain
  required for this change.

Risks:
- Provider-specific proof cryptography, product verification wiring, real
  device/network validation, durable database persistence, other-platform
  hosts, and release signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T213 Persistence Snapshot Integrity

Summary:
- Shared in-memory and JSON-file recovery stores now validate snapshot
  canonical JSON and payload hashes before record mutation or durable hydration.
- Tampered or unencodable snapshots fail closed through the same sync-owned
  persistence boundary instead of relying only on later recovery application.
- App tests that intentionally inject a tampered snapshot now use a read-only
  fixture store so they continue to exercise the app source integrity guard.

Files changed:
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- Mirrored mobile and desktop persisted-source focused tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Sync recovery persistence suite: 32 tests passed.
- Mobile and desktop persisted-source suites: 27 tests passed each.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Product-owned database persistence, native/device and cross-device
  validation, other-platform hosts, and release signing remain external or
  integration-owned.

---

### 2026-08-12 - Codex - T212 Persisted Snapshot Read Boundary

Summary:
- Mirrored mobile and desktop production session sources now validate stored
  snapshot IDs, types, and versions before hydration, replay, or identity
  provisioning.
- The read path reuses the bounded writer metadata rule and fails closed for
  unsafe legacy or externally supplied recovery metadata.

Files changed:
- Mirrored `app_persisted_holdem_production_session_source.dart` files.
- Mirrored persisted-source focused tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Mobile and desktop persisted-source suites: 26 tests passed each.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Durable database choice, product state hydration, native/device and
  cross-device validation, other-platform hosts, and release signing remain
  external or integration-owned.

---

### 2026-08-12 - Codex - T211 Exact Recovery Window Budget

Summary:
- Mirrored mobile and desktop snapshot coordinators now measure the exact
  canonical persisted recovery window, including snapshot envelope metadata
  and event JSON, before retaining failed checkpoints.
- Configured snapshot type and version now flow from the configuration factory
  through coordinator measurement and persistence.
- Unsafe configured metadata fails closed before store access or queueing.

Files changed:
- Mirrored snapshot coordinators and configuration factories.
- Mirrored coordinator regression tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Mobile and desktop coordinator suites: 17 tests passed each.
- Mobile and desktop configuration-factory suites: 11 tests passed each.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Durable database choice, product state hydration, native/device and
  cross-device validation, other-platform hosts, and release signing remain
  external or integration-owned.

---

### 2026-08-12 - Codex - T210 Snapshot Coordinator Pre-Queue Boundary

Summary:
- Mirrored mobile and desktop snapshot coordinators now validate factory-
  produced snapshot IDs before checkpoint measurement, persistence, or pending
  queue insertion.
- Unsafe C1 and oversized IDs fail closed without a store attempt or retained
  retry checkpoint.

Files changed:
- Mirrored snapshot writers, coordinators, and coordinator regression tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Mobile and desktop snapshot coordinator suites: 14 tests passed each.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Durable database choice, product state hydration, native/device and
  cross-device validation, other-platform hosts, and release signing remain
  external or integration-owned.

---

### 2026-08-12 - Codex - T209 Snapshot Metadata Text Boundary

Summary:
- Mirrored mobile and desktop Hold'em snapshot writers now enforce the
  protocol canonical-JSON 4,096-byte UTF-8 text bound on snapshot IDs, types,
  and versions.
- C0/C1/DEL controls fail closed before snapshot persistence.

Files changed:
- Mirrored `app_holdem_production_session_snapshot_writer.dart` files.
- Mirrored snapshot-writer focused tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Mobile snapshot-writer suite: 6 tests passed.
- Desktop snapshot-writer suite: 6 tests passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Durable database choice, product state hydration, native/device and
  cross-device validation, other-platform hosts, and release signing remain
  external or integration-owned.

---

### 2026-08-12 - Codex - T208 Hydrated Session Identity Boundary

Summary:
- Mirrored mobile and desktop production-session factories now validate
  hydrated table, session, and protocol identities against the shared native
  transport UTF-8, control-character, and byte-size bound.
- Unsafe or oversized product state fails before app runtime, persistence, or
  native transport composition.

Files changed:
- Mirrored `app_holdem_production_session_factory.dart` implementations.
- Mirrored production-factory focused tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Mobile production-factory suite: 3 tests passed.
- Desktop production-factory suite: 3 tests passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Product-owned state hydration, durable database choice, native/device and
  cross-device validation, other-platform hosts, and release signing remain
  external or integration-owned.

---

### 2026-08-12 - Codex - T207 Bootstrap Scope Validation

Summary:
- Mirrored mobile and desktop join bootstrap coordinators now validate direct
  session/table scope inputs with the shared native transport identity bound.
- Blank, padded, control-bearing, and oversized UTF-8 scope values preserve
  relay fallback before native capability lookup, local discovery, or provider
  resolution.

Files changed:
- Mirrored `native_join_bootstrap_coordinator.dart` implementations.
- Mirrored native-join focused tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Mobile bootstrap-coordinator suite: 12 tests passed.
- Desktop bootstrap-coordinator suite: 12 tests passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Native/device behavior, cross-device reachability, product state/database
  wiring, other-platform hosts, and release signing remain external or
  integration-owned.

---

### 2026-08-12 - Codex - T206 Native Readiness Cancellation Short-Circuit

Summary:
- Mirrored mobile and desktop native-readiness loaders now check route/startup
  cancellation before and between capability lookups.
- Cancellation returns the existing stable all-unavailable readiness warning
  projection and prevents later legacy non-cancellable bridge calls.
- Already-dispatched host calls remain host-owned; current method-channel
  bridges continue to receive the cancellation signal directly.

Files changed:
- Mirrored `app_native_readiness_loader.dart` implementations.
- Mirrored native-readiness focused tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Mobile native-readiness suite: 10 tests passed.
- Desktop native-readiness suite: 10 tests passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Non-cancellable work already in flight cannot be interrupted by the app
  shell. Device/runtime capability truth, cross-device reachability,
  production database/state wiring, other-platform hosts, and release signing
  remain external or integration-owned.

---

### 2026-08-12 - Codex - T205 Production Session Load Cancellation

Summary:
- Mirrored mobile and desktop typed production-session configuration loaders
  now accept optional route cancellation.
- App-shell replacement, disposal, fallback, and successful handoff complete
  the active cancellation signal, while configuration and persisted local
  identity construction honor it before returning a route configuration.
- Stale production loads remain ignored and now stop their cancellable
  app-owned work instead of only losing the route token.

Files changed:
- Mirrored app-shell main lifecycle, configuration loader/factory,
  configuration, and persisted session source files.
- Mirrored app-shell and configuration-factory focused tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused mobile app-shell and configuration-factory suites passed.
- Focused desktop app-shell and configuration-factory suites passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifact builds passed.

Risks:
- Cancellation cannot undo a native operation that has already completed, and
  the mounted bootstrap route remains the owner of downstream native identity
  cancellation. External loaders may ignore the optional signal. Product
  database/state wiring, native/device validation, cross-device reachability,
  other-platform hosts, and release signing remain external or
  integration-owned.

---

### 2026-08-12 - Codex - T204 Demo Recovery Read Fail-Closed

Summary:
- Mirrored mobile and desktop demo table routes now consume
  `RecoveryPersistenceLoadResultStore` when available.
- Corrupt, locked, oversized, or otherwise unavailable recovery windows now
  render as unavailable in the demo surface instead of appearing as zero
  persisted events.
- Compatibility remains for legacy stores that only implement `loadWindow`.

Files changed:
- Mirrored `demo_table_screen.dart` implementations and focused tests.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Mobile demo-table suite: 7 tests passed.
- Desktop demo-table suite: 7 tests passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- The compatibility fallback remains for externally supplied legacy stores.
  Product database/state wiring, native/device validation, cross-device
  reachability, other-platform hosts, and release signing remain external or
  integration-owned.

---

### 2026-08-12 - Codex - T203 Durable Recovery Load Fail-Closed

Summary:
- Added an additive `RecoveryPersistenceLoadResultStore` contract and immutable
  `RecoveryPersistenceLoadResult` model for stores that can report read failure.
- The JSON file store now surfaces invalid scope, lock, corruption, size, and
  generic load failures instead of exposing them as an empty production window;
  the legacy `loadWindow` projection remains compatible.
- Mirrored mobile and desktop persisted Hold'em sources reject unsuccessful
  recovery loads before initial snapshot loading or local identity provisioning.

Files changed:
- `packages/peerdeal_sync/lib/src/models/recovery_persistence_load_result.dart`
- `packages/peerdeal_sync/lib/src/contracts/recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- Mirrored persisted Hold'em sources and focused tests in both app shells.
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused sync persistence suite: 29 tests passed.
- Mirrored mobile and desktop persisted-session suites: 26 tests passed each.
- Full analyze, boundary-check, source-text, serialized test, dependency-audit,
  and `git diff --check` gates passed.
- Android debug APK and Windows debug artifacts built successfully.
- Dependency audit reports 0 actionable upgrades and 11 newer toolchain-blocked
  versions.

Risks:
- Legacy callers that only use `loadWindow` retain the compatibility empty
  projection; production persisted Hold'em sources now use the explicit result
  seam. Product database persistence, native/device validation, cross-device
  reachability, other-platform hosts, and release signing remain external or
  integration-owned.

---

### 2026-08-12 - Codex - T202 Diagnostic Payload Ownership

Summary:
- `ProtocolDiagnostic` and `ReplayMismatch` now deep-freeze nested
  `expected`/`actual` payload trees at construction.
- Diagnostic serialization exposes immutable snapshots rather than caller-owned
  maps or lists.
- The protocol package now declares its existing `meta` dependency explicitly;
  app const call sites were updated to preserve analyzer correctness.

Files changed:
- `packages/peerdeal_protocol/lib/src/models/protocol_diagnostic.dart`
- `packages/peerdeal_protocol/pubspec.yaml`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `packages/peerdeal_replay/lib/src/models/replay_mismatch.dart`
- `packages/peerdeal_replay/test/replay_model_ownership_test.dart`
- `packages/peerdeal_privacy/lib/src/services/default_diagnostics_scrubber.dart`
- `packages/peerdeal_privacy/test/default_diagnostics_scrubber_test.dart`
- `apps/peerdeal_mobile/lib/join_flow/join_flow_orchestrator.dart`
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_model_ownership_test.dart`
- `apps/peerdeal_mobile/test/safe_surface/safe_result_projection_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_orchestrator.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_model_ownership_test.dart`
- `apps/peerdeal_desktop/test/safe_surface/safe_result_projection_test.dart`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused protocol, privacy, replay, mobile, and desktop suites passed.
- Full analyze, boundary-check, source-text, dependency-audit, and repository
  test gates passed.
- Android debug APK and Windows debug artifacts built successfully.
- `git diff --check` passed.

Risks:
- Product state/database wiring, native/device validation, other-platform
  hosts, and release signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T201 Hold'em Settlement Draft Ownership

Summary:
- Hold'em projected, blocked, and completed settlement event drafts now
  deep-freeze payload trees at construction.
- Projected award maps are independently owned, preventing post-construction
  mutation from changing event draft state before emission.
- The existing protocol collection-ownership helper is now available through
  the public protocol barrel for variant consumers.

Files changed:
- `packages/peerdeal_protocol/lib/peerdeal_protocol.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_settlement_projected_event_builder.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_settlement_blocked_event_builder.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_hand_settled_event_builder.dart`
- `packages/peerdeal_variants/test/variant_model_ownership_test.dart`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused variant ownership and settlement-builder suites passed.
- Full analyze, boundary-check, source-text, dependency-audit, and repository
  test gates passed.
- Android debug APK and Windows debug artifacts built successfully.

Risks:
- Product state/database wiring, native/device validation, other-platform
  hosts, and release signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T200 Secure-Key Snapshot Integrity

Summary:
- The shared secure-key method-channel decoder now fails closed when a native
  snapshot contains malformed records or duplicate key IDs.
- Invalid records are no longer silently discarded, preventing partial key-ring
  state from reaching receipt provisioning or verification.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused native bridge channel-contract suite passed.
- Full analyze, boundary-check, source-text, dependency-audit, and repository
  test gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke validation
  passed, including secure-key CAS/read-back/delete markers.

Risks:
- Real-device/native host behavior on other platforms, product state/database
  wiring, and release signing remain external or integration-owned.

---

### 2026-08-12 - Codex - T199 Android Secure-Key Atomic Replacement

Summary:
- Android generic secure-key storage now replaces an existing encrypted
  envelope with an API-compatible same-filesystem POSIX rename.
- This closes the concrete update/rotation failure caused by relying on
  `File.renameTo`, which is not required to replace an existing destination.
- The generic method-channel contract and receipt-owned key semantics are
  unchanged.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused mobile receipt/key-ring suites passed.
- Android debug APK build passed.

Remaining:
- Real-device Android secure-key/capture validation, cross-device transport
  reachability, release signing, other-platform hosts, and product-owned
  session/database wiring remain separate.

---

### 2026-08-12 - Codex - T198 Context-Aware Initial Hold'em Snapshot Loading

Summary:
- Mirrored mobile and desktop persisted Hold'em sources now accept an optional
  context-aware initial snapshot loader for new accepted sessions.
- The loader receives the exact `JoinFlowSessionContext`; the existing
  invite-only loader remains the compatibility fallback.
- Configuration factories forward the seam without moving product state or
  session policy into shared packages.

Files changed:
- Mirrored app session source and configuration plumbing/tests.
- `docs/PRODUCTION_READINESS.md` and stable AI contract/handoff docs.

Tests run:
- Focused mobile and desktop persisted Hold'em source suites passed.

Remaining:
- Product-owned state/database wiring, device/network validation, other-platform
  native hosts, release signing, and final UX remain separate.

---

### 2026-08-12 - Codex - T197 Harden Android Transport Teardown Boundaries

Summary:
- Android native transport now validates receive scope identities before
  initializing its multicast receiver, avoiding resource allocation for
  malformed method calls.
- Android send emission now rechecks the closed state while holding the
  lifecycle lock, preventing a late multicast send after engine teardown.
- Focused Android contract coverage and the debug APK build passed.

Remaining:
- Real-device transport behavior, cross-device reachability, release signing,
  and product session/database wiring remain external or integration-owned.

### 2026-08-12 - Codex - T196 Bound Pending Checkpoint Resources

Summary:
- Mirrored mobile and desktop Hold'em snapshot coordinators now bound pending
  failed checkpoints by both count and serialized typed-state/event bytes.
- Invalid or oversized checkpoint byte budgets fail closed before durable
  persistence; successful retry and terminal discard release tracked bytes.
- Configuration factories expose the byte budget while preserving app-owned
  state, event identity, snapshot identity, and database boundaries.

Files changed:
- Mirrored Hold'em snapshot coordinators, configuration factories, and tests.

Validation:
- Focused mobile session tests passed.
- Focused desktop session tests passed.

Risks:
- Real-device transport behavior, other platform hosts, release signing,
  product-owned session/database wiring, and final navigation/UX remain open.

Next reviewer:
- Run the full repository gates, then continue with the next documented
  production gap without inventing platform endpoint semantics.

### 2026-08-12 - Codex - T195 Android Receive Queue Serialization

Summary:
- Android native transport receive drain/requeue now shares the lifecycle lock
  used by the receiver thread.
- Concurrent arrivals cannot reorder the drained queue or bypass the bounded
  512-frame queue invariant.
- Closed receivers return the existing unavailable receive fact; generic channel
  payloads and package boundaries are unchanged.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Android debug APK build: passed.

Risks:
- Real-device transport behavior and cross-device multicast reachability remain
  external validation; product state provisioning, durable database replacement,
  other-platform hosts, release signing, and final navigation/UX remain
  separate.

Next reviewer:
- Continue with the next documented production gap without inventing platform
  endpoint semantics.

### 2026-08-12 - Codex - T194 Android Multicast Readiness

Summary:
- Android native transport receiver startup now requires a created and held
  `WifiManager.MulticastLock` before publishing availability.
- Missing Wi-Fi service, missing lock creation, failed acquisition, or an
  unheld lock closes the candidate socket and returns the existing unavailable
  capability/receive facts.
- The generic method-channel payload and package boundaries are unchanged.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `packages/peerdeal_native_bridges/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Android debug APK build: passed.

Risks:
- Real-device lock behavior and cross-device multicast reachability remain
  external validation; product state provisioning, durable database replacement,
  other-platform hosts, release signing, and final navigation/UX remain
  separate.

Next reviewer:
- Continue with the next documented production gap without inventing platform
  endpoint semantics.

### 2026-08-12 - Codex - T193 Android Transport Teardown Delivery

Summary:
- Android native transport result delivery now re-checks handler closure on
  the main looper before returning a worker result.
- Late capability, send, and receive results return their existing
  operation-specific unavailable payloads instead of stale success data.
- The generic method-channel payload and package boundaries are unchanged.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Android debug APK build: passed.
- `git diff --check`: passed.

Risks:
- Real-device engine teardown/runtime behavior and cross-device multicast
  reachability remain external validation; product state provisioning, durable
  database replacement, other-platform hosts, release signing, and final
  navigation/UX remain separate.

Next reviewer:
- Continue with the next documented production gap without inventing platform
  endpoint semantics.

### 2026-08-12 - Codex - T192 Android Multicast Permissions

Summary:
- The mobile Android manifest now declares `ACCESS_WIFI_STATE` and
  `CHANGE_WIFI_MULTICAST_STATE` for the existing native multicast transport;
  `INTERNET` remains declared for socket traffic.
- No transport or protocol behavior changed; the patch aligns deployment
  permissions with the locked Android host implementation.

Validation:
- Android debug APK built successfully after the manifest change.
- Real-device permission behavior and cross-device multicast reachability still
  require operator/device validation.

Remaining:
- Product state provisioning, durable database replacement, other-platform
  hosts, release signing, and final navigation/UX validation remain separate.

### 2026-08-12 - Codex - T191 Immutable Table Warning Results

Summary:
- Mirrored `DemoRecoveryPersistenceLoadResult` constructors now snapshot both
  available and unavailable recovery warning lists before table rendering.
- Mirrored unavailable native transport senders now own their fallback warning
  lists before reusing them for rejected sends.
- Const demo fixtures were migrated without changing displayed warning behavior.

Validation:
- Focused mobile and desktop demo-table plus native-transport suites passed 23
  tests each, including recovery warning ownership regressions.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product state provisioning, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final navigation/UX
  validation remain external or integration-owned.

### 2026-08-12 - Codex - T190 Immutable Route And Home Policy

Summary:
- Mirrored `JoinFlowRoute` and `SetupFlowRoute` now snapshot enabled mode sets
  before route state can observe them.
- `DemoHomeScreen` snapshots demo and production navigation action lists at
  construction, keeping home policy stable across caller mutation.
- Const fixtures were migrated without changing route behavior or navigation
  labels.

Validation:
- Focused mirrored route suites passed 36 tests each, including three
  ownership regressions per platform.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Full repository gates, Android/Windows host builds, and Windows native-host
  smoke validation remain to be run for this change. Product state provisioning,
  durable database replacement, device/network validation, other-platform
  hosts, release signing, and final navigation/UX validation remain external or
  integration-owned.

### 2026-08-12 - Codex - T189 Immutable App Output Models

Summary:
- Mirrored `SetupFlowOutcome` models now deep-freeze compiled Game File maps
  and snapshot setup errors and warnings at construction.
- `SafeReceiptScanVm` deep-freezes nested shareable receipt fields, while
  `SafeRecoveryVm` snapshots protocol diagnostics before safe-surface use.
- Const fixtures were migrated without changing setup result codes, receipt
  presentation, or safe-surface behavior.

Validation:
- Focused mirrored setup, safe-projection, and receipt-screen suites passed
  30 tests each; both app packages analyzed cleanly.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product state provisioning, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final navigation/UX
  validation remain external or integration-owned.

### 2026-08-12 - Codex - T188 Immutable App Runtime Configuration

Summary:
- Mirrored mobile and desktop runtime objects now snapshot join/setup mode
  gates, enabled demo paths, production route maps, production navigation,
  and native-readiness route gates at construction.
- `withOverrides` re-enters the same ownership boundary, so caller mutation
  cannot change mounted route or readiness policy after runtime composition.
- Only app-shell runtime construction and its mirrored tests changed; package
  boundaries and native bridge contracts are unchanged.

Validation:
- Focused mobile and desktop runtime ownership suites passed two tests each.
- Full mobile and desktop app-shell suites passed 83 tests each.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product state provisioning, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final navigation/UX
  validation remain external or integration-owned.

### 2026-08-12 - Codex - T187 Immutable Join Handoff Collections

Summary:
- Mirrored mobile and desktop `RoleGrant` models now snapshot authorization
  permissions before exposing accepted role state.
- `BootstrapPlan` snapshots peer candidates, and `JoinFlowOutcome` snapshots
  protocol diagnostics, protecting accepted handoff and fail-closed UI state
  from caller-owned list mutation.
- Const fixtures were migrated without changing join result codes, governance
  flow, cancellation behavior, or native bridge contracts.

Validation:
- Focused mobile join-flow suite: passed 46 tests, including two ownership
  regressions; focused desktop suite: passed 46 tests.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product state provisioning, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final navigation/UX
  validation remain external or integration-owned.

### 2026-08-12 - Codex - T186 Immutable Shared UI Collections

Summary:
- `SafeSurfaceRenderModel` snapshots warning and native-note lists before
  exposing render state.
- `PeerDealAppScaffold` snapshots action-widget lists at construction; the four
  mirrored no-action const callsites were migrated without UI behavior changes.
- The change stays inside the shared UI boundary and preserves app-owned capture
  policy, navigation, and session orchestration.

Validation:
- Focused `peerdeal_ui_kit` suite: passed 11 tests, including two ownership
  regressions; the shared kit and both app shells analyzed cleanly.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product visual/accessibility/navigation validation, product state provisioning,
  device/network validation, other-platform hosts, release signing, and durable
  database replacement remain external or integration-owned.

### 2026-08-12 - Codex - T185 Immutable Mode Policy Collections

Summary:
- `GovernanceContext` snapshots participant, seat, and waitlist inputs at
  construction, preventing caller mutation from changing policy traversal.
- `GovernanceDecision` owns next-waitlist and note collections, while
  `ValidationResult` owns warning and error collections.
- The change stays inside `peerdeal_modes` and preserves governance bounds,
  result codes, and package ownership.

Validation:
- Focused `peerdeal_modes` suite: passed 28 tests, including two collection
  ownership regressions; package analyzer passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product state provisioning, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T184 Immutable Protocol Wire Models

Summary:
- Command, event, and snapshot envelope payloads now recursively freeze
  caller-owned maps/lists/sets at construction.
- `ProtocolCatalog()` retains the immutable default catalog;
  `ProtocolCatalog.withEntries(...)` snapshots custom entry collections, and
  `ProtocolCatalogLockReport` owns its error list.
- Existing const envelope fixtures were migrated without changing protocol
  identities or package boundaries.

Validation:
- Focused `peerdeal_protocol` suite: passed 56 tests, including two ownership
  regressions; affected package analysis passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product state provisioning, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T183 Immutable Reducer Guard Configuration

Summary:
- `CoreReducer()` now owns the immutable baseline guard set without accepting
  a mutable collection through the default constructor.
- `CoreReducer.withInvariantGuards(...)` snapshots caller-supplied guards into
  an unmodifiable list before deterministic projection.
- Existing app and variant default construction remains `const CoreReducer()`;
  no package boundary or reducer behavior moved.

Validation:
- Focused `peerdeal_core` suite: passed 57 tests, including the reducer guard
  ownership regression; package analyzer passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product state provisioning, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T182 Immutable Core Collections

Summary:
- `TableState` now recursively freezes caller-owned metadata before exposing
  deterministic state.
- `PotSlice` owns its contested-seat collection, and `SettlementResult` owns
  slices, awards, ledger deltas, and warning collections at construction.
- The change stays inside `peerdeal_core`; no reducer, variant-rule, receipt,
  native, or app policy boundaries were moved.

Validation:
- Focused `peerdeal_core` suite: passed 56 tests, including the new ownership
  regression; package and affected-package analysis passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Product state provisioning, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T181 Immutable Receipt Collections

Summary:
- Receipt scan results, export artifacts, and export inspection results now
  defensively copy and recursively freeze public maps/lists before exposing
  receipt data to decoders, presenters, or app shells.
- `ReceiptKeyRingSnapshot` and `StaticReceiptSigningKeyProvider` now own and
  freeze retained signing/encryption key collections while preserving their
  existing bounded lookup behavior.
- Mirrored app consumers and shared receipt test fixtures were migrated from
  stale const construction without changing receipt policy or package
  boundaries.

Validation:
- Focused `peerdeal_receipts` suite: passed 54 tests, including the new
  collection-ownership regression; package analyzer passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Platform-secure storage validation, provider-specific proof semantics,
  product verification wiring, durable database replacement, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T180 Immutable Crypto Verification Collections

Summary:
- `DealProofBundle` now defensively copies and recursively freezes normalized
  and raw proof maps at the crypto boundary while preserving the normalizer's
  shared immutable view for identical inputs.
- `VerificationPayload` owns evidence/warning lists and `VerificationResult`
  owns its layer collection; no crypto verification result exposes caller-owned
  mutable collections.

Validation:
- Focused `peerdeal_crypto` suite: passed 14 tests, including the new ownership
  regression; package analyzer passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Provider-specific proof semantics, product verification wiring, durable
  database replacement, device/network validation, other-platform hosts,
  release signing, and final UX remain external or integration-owned.

### 2026-08-12 - Codex - T179 Immutable Wizard Collections

Summary:
- Wizard setup intents, helper suggestions, resolved drafts, preset
  layers/results, validation plans, and Game File compile results now own and
  recursively freeze public maps/lists/sets at construction boundaries.
- Mirrored mobile and desktop setup-flow callsites and wizard fixtures were
  migrated from invalid const construction without changing wizard policy or
  package boundaries.

Validation:
- Focused `peerdeal_wizard` suite: passed 27 tests, including the new ownership
  regression.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed; dependency audit reports zero actionable upgrades.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T178 Immutable Variant Collections

Summary:
- Variant validation/hand-plan, showdown, Hold'em state, evaluation,
  transition, reducer, projection, settlement-emission, and diagnostic models
  now defensively copy and freeze public collections, including nested showdown
  winner maps.
- Variant library, app, and test fixtures were migrated from invalid const
  construction without changing package boundaries or poker rule behavior.

Validation:
- Dedicated variant ownership regression: passed 2 tests.
- Full `peerdeal_variants` suite: passed 154 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed. Dependency audit reported 0 actionable upgrades
  and 11 newer toolchain-blocked versions.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T177 Immutable Replay Collections

Summary:
- Replay requests, snapshot suffix plans, and replay results now defensively
  copy and freeze event windows, warning diagnostics, and replay mismatches.

Validation:
- Focused replay ownership, engine, mismatch, suffix, and anchor suites: passed
  34 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed. Dependency audit reported 0 actionable upgrades
  and 11 newer toolchain-blocked versions.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T176 Immutable Sync/Recovery Collections

Summary:
- Sync and recovery models now defensively copy and freeze recovery event
  requests/windows, conflict results, warning diagnostics, snapshot results,
  persistence results, and reconciliation notes.
- Sync and app/test call sites were migrated from invalid const construction
  without changing package boundaries or runtime behavior.

Validation:
- Focused sync ownership, conflict, snapshot, and coordinator suites: passed
  45 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed. Dependency audit reported 0 actionable upgrades
  and 11 newer toolchain-blocked versions.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T175 Immutable Network Collections

Summary:
- Generic network models now defensively copy and freeze bootstrap peer/candidate
  lists, LAN discovery lists, transport payload bytes, warning diagnostics, and
  peer-election rankings.
- Network and app transport call sites were migrated from invalid const
  construction without changing package boundaries or runtime behavior.

Validation:
- Focused network ownership and transport suites: passed 22 tests.
- Affected mobile transport suites: passed 44 tests.
- Affected desktop transport suites: passed 44 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed. Dependency audit reported 0 actionable upgrades
  and 11 newer toolchain-blocked versions.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all 16 native-host smoke markers passed.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T174 Immutable Native-Bridge Collections

Summary:
- Generic native bridge models now defensively copy and freeze local-network
  discovery lists, secure-key record lists, native receive frame lists, and
  transport frame payload bytes.
- Shared test fixtures were migrated from invalid const construction without
  changing package boundaries or runtime behavior.

Validation:
- Focused native bridge contract and method-channel suites: passed 68 tests.
- Affected mobile Flutter suites: passed 227 tests.
- Affected desktop Flutter suites: passed 227 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed. Dependency audit reported 0 actionable upgrades
  and 11 newer toolchain-blocked versions.
- Android debug APK, Windows debug, and dedicated Windows native-host smoke
  artifacts built successfully; all native-host smoke markers passed.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T173 Immutable App-Boundary Collections

Summary:
- Mirrored native bootstrap candidate, native transport session/drain, and
  receipt key-ring result constructors now defensively copy and freeze exposed
  collection diagnostics.
- Focused mobile and desktop transport, bootstrap, and receipt Flutter suites
  prove source-list isolation and mutation rejection.

Validation:
- Mobile focused suites: passed 73 tests.
- Desktop focused suites: passed 73 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed.
- Mobile debug APK and desktop Windows debug artifacts built successfully.
- Windows native-host smoke passed app storage, capture, local-network,
  transport, secure-key CAS/tombstone, and capture-release markers.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T172 Immutable Readiness/Transport Diagnostics

Summary:
- Mirrored readiness snapshots and transport poll/start results now defensively
  copy and freeze warning lists.
- Focused mobile and desktop readiness and transport-source Flutter suites prove
  source-list isolation and mutation rejection.

Validation:
- Mobile readiness/transport suite: passed 20 tests.
- Desktop readiness/transport suite: passed 20 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed.
- Mobile debug APK and desktop Windows debug artifacts built successfully.
- Windows native-host smoke passed app storage, capture, local-network,
  transport, secure-key CAS/tombstone, and capture-release markers.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T171 Immutable Local-Identity Diagnostics

Summary:
- Mirrored local-identity loader and provisioner results now defensively copy
  and freeze warning lists.
- Focused mobile and desktop local-identity Flutter suites prove source-list
  isolation and mutation rejection.

Validation:
- Mobile local-identity suite: passed 15 tests.
- Desktop local-identity suite: passed 15 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed.
- Mobile debug APK and desktop Windows debug artifacts built successfully.
- Windows native-host smoke passed app storage, capture, local-network,
  transport, secure-key CAS/tombstone, and capture-release markers.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T170 Immutable Startup Diagnostics

Summary:
- Mirrored recovery-store and production-session configuration load results now
  defensively copy and freeze warning lists.
- Focused mobile and desktop configuration, recovery, and app-shell Flutter
  suites prove source-list isolation and mutation rejection.

Validation:
- Mobile configuration/recovery suite: passed 23 tests.
- Desktop configuration/recovery suite: passed 23 tests.
- Mobile app-shell suite: passed 82 tests.
- Desktop app-shell suite: passed 82 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed.
- Mobile debug APK and desktop Windows debug artifacts built successfully.
- Windows native-host smoke passed app storage, capture, local-network,
  transport, secure-key CAS/tombstone, and capture-release markers.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T169 Immutable App-Session Diagnostics

Summary:
- Mirrored app session and Hold'em inbound result constructors now defensively
  copy and freeze warning lists.
- Focused mobile and desktop Flutter runtime suites prove source-list isolation
  and mutation rejection on projected diagnostics.

Validation:
- Focused mobile suite: passed 18 tests.
- Focused desktop suite: passed 18 tests.
- Full analyze, boundary-check, source-text, dependency-audit, and serialized
  repository test gates passed.
- Mobile debug APK and desktop Windows debug artifacts built successfully.
- Windows native-host smoke passed app storage, capture, local-network,
  transport, secure-key CAS/tombstone, and capture-release markers.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T168 Inbound Event Checkpoint Identity

Summary:
- Mirrored app session results now carry the exact accepted `EventEnvelope`.
- Mirrored Hold'em table routes checkpoint that callback-owned event instead of
  rereading mutable `lastAcceptedEvent` runtime state after inbound transport.

Files changed:
- Mirrored app session runtimes and Hold'em table routes.
- Mirrored runtime and transport-handler focused tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop runtime and transport-handler suites passed.
- Full repository gates and Android/Windows artifact validation remain
  required for this slice.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T167 Shared Sync Snapshot Hash Verification

Summary:
- `peerdeal_sync` conflict planning and snapshot application now verify the
  canonical snapshot payload hash before recovery planning or projection.
- Tampered envelopes fail with `ERR_SNAPSHOT_PAYLOAD_HASH_MISMATCH`; valid
  canonical snapshots continue through the existing path.

Files changed:
- `packages/peerdeal_sync/lib/src/engine/basic_conflict_detector.dart`
- `packages/peerdeal_sync/lib/src/engine/basic_snapshot_applier.dart`
- Shared sync detector, applier, and coordinator tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Full `peerdeal_sync` package suite passed (72 tests), including tampered
  detector/applier cases.
- Full repository analyze, boundary, source-text, dependency-audit, and
  serialized test gates passed.
- Android and Windows debug artifacts built successfully; Windows native-host
  smoke passed all bridge checkpoints.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T166 Persisted Snapshot Hash Verification

Summary:
- Mirrored persisted Hold'em sources now recompute the canonical snapshot
  payload hash and reject mismatches before typed hydration.
- Tampered or malformed snapshot payloads fail closed before identity or route
  work; canonical snapshots continue to load.

Files changed:
- Mirrored persisted Hold'em source implementations and focused source tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop source/configuration suites passed (32 tests
  each), including tampered-hash rejection.
- Full repository analyze, boundary, source-text, dependency-audit, and
  serialized test gates passed.
- Android and Windows debug artifacts built successfully; Windows native-host
  smoke passed all bridge checkpoints.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T165 Orphaned Recovery Event Guard

Summary:
- Mirrored persisted Hold'em sources now reject recovery event suffixes that
  have no typed snapshot anchor, preventing new initial state from masking
  orphaned durable events.
- The guard runs before product state loading, identity provisioning, or
  checkpoint work.

Files changed:
- Mirrored persisted Hold'em source implementations and focused source tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop source/configuration suites passed, including the
  orphaned-event rejection and no-mutation assertions.
- Full repository analyze, boundary, source-text, dependency-audit, and
  serialized test gates passed.
- Android and Windows debug artifacts built successfully; Windows native-host
  smoke passed all bridge checkpoints.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T164 First-Join Typed State Checkpoint

Summary:
- Mirrored persisted Hold'em sources and configuration factories now accept an
  optional product-owned initial typed snapshot loader for empty recovery.
- Invite scope, sequence zero, cursor sequence one, and protocol genesis are
  validated before identity provisioning; the initial state is checkpointed
  through the existing snapshot coordinator before app input is returned.

Files changed:
- Mirrored app Hold'em persisted source/configuration/factory files and focused
  source tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop source/configuration suites passed (30 tests
  each), followed by full analyze, boundary, source-text, dependency-audit,
  and serialized test gates.
- Android debug APK and Windows debug artifacts built successfully; Windows
  native-host smoke passed all bridge checkpoints.

Remaining:
- Durable database replacement, real product state selection, device/network
  validation, other-platform hosts, release signing, and final UX remain
  external or integration-owned.

### 2026-08-12 - Codex - T163 Receipt Key-Ring Native Text Bound

Summary:
- Mirrored receipt key-ring loaders and writers now reuse the locked native
  secure-key UTF-8/C1 and byte limits for namespaces, key IDs, and secrets.
- C1-bearing or byte-oversized namespaces fail closed before native load,
  save, or delete; invalid key metadata cannot become a receipt key-ring entry.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- Mirrored receipt loader/writer tests and readiness/handoff records.

Validation:
- Focused mobile and desktop receipt loader/writer suites passed.
- Mobile and desktop package analysis passed.
- Full repository gates and platform artifact validation remain required.

Remaining:
- Android/Windows runtime key-store validation, cross-device networking,
  other-platform hosts, product state/database provisioning, and release
  signing remain external or integration-owned.

### 2026-08-11 - Codex - T139 Android Secure-Key UTF-8 Boundary Hardening

Summary:
- Android secure-key host validation now enforces UTF-8 byte limits for
  namespaces and record fields, matching the Dart contract and Windows host.
- Shared channel-contract tests cover oversized multibyte key material.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- Readiness and handoff records.

Validation:
- Focused Flutter secure-key channel-contract test passed.
- Android `:app:assembleDebug` passed.
- Full repository analyze, boundary, source-text, test, dependency-audit, and
  diff-check gates passed before commit and push.

### 2026-08-11 - Codex - T141 Dart Secure-Key Text Validation Hardening

Summary:
- Shared native-bridge validation now applies UTF-8 byte and control-character
  rules consistently to secure-key namespaces, IDs, purposes, algorithms, and
  secrets.
- Oversized or control-bearing save/delete requests fail before native dispatch.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/native_bridge_payload_limits.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_bridge_models.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/method_channel_secure_key_storage_bridge.dart`
- `packages/peerdeal_native_bridges/test/method_channel_secure_key_storage_bridge_test.dart`
- Readiness and handoff records.

Validation:
- Focused method-channel and channel-contract Flutter tests passed.
- Full repository analyze, boundary, source-text, test, dependency-audit, and
  diff-check gates passed before commit and push.

### 2026-08-11 - Codex - T144 Production Join-Context Propagation

Summary:
- Mirrored production configuration factories now accept optional accepted join
  context and context-aware route-policy factories.
- Generated loader adapters forward the exact `JoinFlowSessionContext` before
  route/source composition while preserving no-context callers.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_configuration_factory.dart`
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_configuration_loader_factory.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_configuration_factory.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_configuration_loader_factory.dart`
- Mirrored focused configuration tests and readiness records.

Validation:
- Focused mobile and desktop configuration Flutter suites passed.

### 2026-08-11 - Codex - T145 Production Configuration Warning Preservation

Summary:
- Mirrored configuration factories now retain recovery-store warnings when
  route-policy or persisted-source composition fails after store creation.
- Stable unavailable messaging and exception suppression remain unchanged.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_configuration_factory.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_configuration_factory.dart`
- Mirrored focused configuration tests and readiness records.

Validation:
- Focused mobile and desktop configuration Flutter suites cover the fail-closed
  composition path; full repository gates remain required before commit.

### 2026-08-11 - Codex - T146 CI Branch Gate Coverage

Summary:
- CI now runs on direct pushes to `retrofit/**` and `hardening/**`, alongside
  `main` and `master`.
- Manual `workflow_dispatch` execution is enabled without changing existing
  repository, host-build, signing-guard, or native-smoke jobs.

Files changed:
- `.github/workflows/ci.yml`
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`

Validation:
- Workflow-only change; local repository gates and YAML/source-text checks are
  required before push. GitHub-hosted execution remains external.

### 2026-08-11 - Codex - T147 Production Table Lifecycle Invalidation

Summary:
- Mirrored production Hold'em surfaces reset pending projection state when the
  runtime, snapshot coordinator, peer, or local seat identity changes.
- Generation guards ignore late persistence, transport, retry, and disposal
  completions after replacement.

Files changed:
- Mirrored production table surfaces and route regression tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop production route suites passed.
- Full analyze, boundary-check, source-text, test, dependency-audit, Android
  debug build, Windows debug build, Windows native-host smoke, and diff-check
  gates passed.

Risks:
- Product state/database provisioning, device/runtime validation, other-platform
  hosts, cross-device networking, and release signing remain external or
  caller-owned boundaries.

### 2026-08-11 - Codex - T149 Cancelled Native Receive Suppression

Summary:
- Mirrored native frame drains now race native receive and frame-handler work
  against source cancellation and fail closed before late frame delivery.
- Native sessions forward route cancellation into the drain, preventing old
  runtimes from mutating after route replacement or disposal.

Files changed:
- Mirrored native frame adapters, native session factories, and transport/route
  regression tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop transport/route suites passed.
- Full analyze, boundary-check, source-text, test, dependency-audit, Android
  debug build, Windows debug build, Windows native-host smoke, and diff-check
  gates passed.

Risks:
- Already-dispatched native host work remains host-owned; product state/database
  provisioning, device/runtime validation, other-platform hosts,
  cross-device networking, and release signing remain external boundaries.

### 2026-08-11 - Codex - T162 Production Session Peer Identity Bound

Summary:
- Mirrored local identity loaders and writers, persisted Hold'em route policies,
  and production-session factories now reuse the shared 256-byte safe
  UTF-8/control-free native transport identity validator.
- C1-bearing and UTF-8-byte oversized peer identities fail closed before native
  save or route construction.

Files changed:
- Mirrored mobile and desktop local identity, persisted route-policy, and
  production-session factory implementations and tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop identity, route-policy, and factory suites passed.
- Mobile and desktop package analysis passed.

Risks:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  external or operator-owned boundaries.

### 2026-08-11 - Codex - T161 Hold'em Projection Publisher Peer Bound

Summary:
- Mirrored app Hold'em projection publishers now reuse the shared 256-byte
  safe UTF-8/control-free transport identity validator.
- Invalid C1-bearing and oversized peer identities fail closed before sender
  calls.

Files changed:
- Mirrored mobile and desktop Hold'em projection publishers and runtime tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop Hold'em runtime suites passed.
- Mobile and desktop package analysis passed.

Risks:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  external or operator-owned boundaries.

### 2026-08-11 - Codex - T160 Native Readiness Secure-Key Namespace Bound

Summary:
- Mirrored app-native readiness loaders now reuse the shared 128-byte
  UTF-8/control-free secure-key namespace validator before bridge lookup.
- Invalid C1-bearing and oversized namespaces fail closed before native
  storage invocation.

Files changed:
- Mirrored mobile and desktop readiness loaders and tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop readiness suites passed, 7 tests each.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed.

Risks:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  external or operator-owned boundaries.

### 2026-08-11 - Codex - T159 Native Transport Source Scope Bound

Summary:
- Mirrored app transport sources and provisioners now reuse the shared native
  bridge safe UTF-8/control-free identity validator before lifecycle start,
  polling, or capability lookup.
- Invalid C0/C1-bearing and oversized session/peer scopes fail closed before
  source scheduling or native provisioning.

Files changed:
- Mirrored mobile and desktop transport source/provisioner implementations and
  tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop source/provisioner suites passed, 18 tests each.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed.

Risks:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  external or operator-owned boundaries.

### 2026-08-11 - Codex - T158 Native Transport Send Model Bound

Summary:
- Mirrored app-native transport sinks now validate converted
  `NativeTransportFrame` values before injected bridge calls.
- Outbound native identity, sequence, and payload invariants cannot be
  bypassed by trim-only network validation.

Files changed:
- Mirrored mobile and desktop native transport frame adapters and tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop transport-adapter suites passed, 15 tests each.
- Full repository analyze, boundary, source-text, dependency-audit, and test
  gates passed.

Risks:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  external or operator-owned boundaries.

### 2026-08-11 - Codex - T157 Native Transport Receive Scope Bound

Summary:
- Mirrored app-native transport drains now reuse the shared native bridge
  safe UTF-8/control-free validator for receive session and peer scopes.
- Direct drain callers cannot pass empty, padded, control-bearing, or
  over-256-byte scope identities to an injected native bridge.

Files changed:
- Mirrored mobile and desktop native transport frame adapters and tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop transport-adapter suites passed, 14 tests each.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.

Risks:
- Android/Windows runtime and cross-device network validation, other-platform
  hosts, product state/database provisioning, and release signing remain
  external or operator-owned boundaries.

### 2026-08-11 - Codex - T156 Native Bootstrap Provider Output Bound

Summary:
- Mirrored native join bootstrap coordinators now cap reachable candidates
  returned by the injected provider at the configured peer limit.
- Provider peer IDs are normalized and deduplicated before the bounded list
  reaches `BootstrapPlan` and the accepted join handoff.

Files changed:
- Mirrored native join bootstrap coordinators and focused tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop native-bootstrap suites passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds
  passed; the smoke run passed all bridge checks.

Risks:
- Product state/database provisioning, device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  external boundaries.

### 2026-08-11 - Codex - T155 Snapshot Checkpoint Queue Bound

Summary:
- Mirrored snapshot coordinators now cap retained failed checkpoints at 64 by
  default, with a positive caller-owned pending-checkpoint limit.
- A full queue fails closed with a stable warning instead of retaining another
  checkpoint during a persistent recovery-store outage.
- Configuration factories pass the same pending-checkpoint limit into the
  coordinator.

Files changed:
- Mirrored snapshot coordinators, configuration factories, and focused tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop coordinator and configuration suites passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds
  passed; the smoke run passed all bridge checks.

Risks:
- Product state/database provisioning, device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  external boundaries.

### 2026-08-11 - Codex - T154 Snapshot Coordinator Recovery Bound

Summary:
- Mirrored snapshot coordinators now enforce the configured recovery-event
  limit before copying event suffixes or entering persistence.
- Configuration factories pass one validated limit into both persistence writer
  and snapshot coordinator, preventing default drift.

Files changed:
- Mirrored snapshot coordinators, configuration factories, and focused tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop coordinator and configuration suites passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all checks.

Risks:
- Product state/database provisioning, device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  external boundaries.

### 2026-08-11 - Codex - T153 Snapshot Serialization Preflight Hardening

Summary:
- Mirrored snapshot writers now canonical-encode typed snapshots during
  validation before appending event suffixes.
- Serialization and hashing failures return stable persistence results and do
  not leave durable event state without a snapshot checkpoint.

Files changed:
- Mirrored snapshot writers and persistence/snapshot writer regression tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop persistence-writer and snapshot-writer suites
  passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all checks.

Risks:
- Product state/database provisioning, device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  external boundaries.

### 2026-08-11 - Codex - T152 Snapshot ID Factory Failure Hardening

Summary:
- Mirrored production snapshot coordinators now invoke snapshot-ID factories
  inside the serialized checkpoint queue.
- Factory exceptions fail closed with a stable persistence warning, update the
  last result, and do not create pending or durable state.

Files changed:
- Mirrored snapshot coordinators and focused coordinator regression tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop snapshot coordinator suites passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all checks.

Risks:
- Product state/database provisioning, device/runtime validation,
  cross-device networking, other-platform hosts, and release signing remain
  external boundaries.

### 2026-08-11 - Codex - T151 Transport Provisioning Cancellation Recheck

Summary:
- Mirrored transport provisioners now recheck route cancellation after native
  session creation and before returning an available session/source.
- Cancellation during session creation fails closed instead of exposing a
  source to a replaced route.

Files changed:
- Mirrored transport provisioners and focused provisioner regression tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and readiness records.

Validation:
- Focused mobile and desktop provisioner, source, drain, and session-factory
  suites passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all checks.

Risks:
- Already-dispatched native host work remains host-owned; product state/database
  provisioning, device/runtime validation, other-platform hosts,
  cross-device networking, and release signing remain external boundaries.

### 2026-08-11 - Codex - T150 Source-Owned Drain Disposal Cancellation

Summary:
- Mirrored transport sources expose an additive cancellable drain callback and
  complete its signal on disposal or external route cancellation.
- Native session factories use the seam so standalone source mounts cannot leave
  in-flight native receives active after disposal.

Files changed:
- Mirrored transport sources, native session factories, and source/drain
  regression tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop source, drain, and session-factory suites passed.
- Full repository analyze, boundary, source-text, dependency-audit, test, and
  diff gates passed.
- Android debug APK, Windows debug, and Windows native-host smoke builds passed;
  the native-host smoke run passed all checks.

Risks:
- Already-dispatched native host work remains host-owned; product state/database
  provisioning, device/runtime validation, other-platform hosts,
  cross-device networking, and release signing remain external boundaries.

### 2026-08-11 - Codex - T148 Inbound Checkpoint Lifecycle Invalidation

Summary:
- Mirrored table routes capture accepted inbound events with the owning
  runtime, snapshot coordinator, and lifecycle generation.
- Late callbacks from replaced or disposed transports cannot checkpoint a
  replacement route or refresh its UI state.

Files changed:
- Mirrored table session routes and route regression tests.
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop route suites passed, including delayed inbound
  completion after runtime replacement.
- Full analyze, boundary-check, source-text, test, dependency-audit, Android
  debug build, Windows debug build, Windows native-host smoke, and diff-check
  gates passed.

Risks:
- Product state/database provisioning, device/runtime validation, other-platform
  hosts, cross-device networking, and release signing remain external or
  caller-owned boundaries.

### 2026-08-11 - Codex - T143 Native App-Storage Path Boundary Hardening

Summary:
- Android no-backup and Windows `LocalAppData` host results now reject invalid,
  padded, C0/C1-control-bearing, or over-4096-byte UTF-8 paths.
- The Windows native-host smoke target asserts the returned path contract.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/AppStorageDirectoryHandler.kt`
- `apps/peerdeal_desktop/windows/runner/windows_app_storage.cpp`
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart`
- Readiness and handoff records.

Validation:
- Android debug APK and Windows debug host builds passed.
- Windows native-host smoke passed all required checkpoints.

### 2026-08-11 - Codex - T142 Generic Native Bridge Text Boundary Hardening

Summary:
- Shared Dart bridge validation now rejects padded or C0/C1-control-bearing
  transport identities and receive scopes, local-network values, capture
  diagnostics, and app-storage paths/warnings.
- The generic contract now matches the existing Android and Windows host text
  rules without adding platform policy to the native bridge package.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_bridge_models.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_channel_contract.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/method_channel_native_transport_bridge.dart`
- `packages/peerdeal_native_bridges/lib/src/local_network/local_network_channel_contract.dart`
- `packages/peerdeal_native_bridges/lib/src/capture_protection/capture_protection_channel_contract.dart`
- `packages/peerdeal_native_bridges/lib/src/app_storage/app_storage_directory_channel_contract.dart`
- Native bridge contract and transport tests.

Validation:
- Focused native bridge contract and transport preflight Flutter tests passed.
- Full native bridge Flutter package tests passed.
- Full repository analyze, boundary, source-text, test, dependency-audit, and
  diff-check gates passed before commit and push.

### 2026-08-11 - Codex - T140 Dart Secure-Key Namespace Boundary Hardening

Summary:
- The shared native-bridge contract now defines a 128-byte UTF-8 secure-key
  namespace limit.
- Dart secure-key method-channel requests reject oversized multibyte namespaces
  before platform dispatch, matching Android and Windows host validation.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/native_bridge_payload_limits.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/method_channel_secure_key_storage_bridge.dart`
- `packages/peerdeal_native_bridges/test/method_channel_secure_key_storage_bridge_test.dart`
- Readiness and handoff records.

Validation:
- Focused secure-key method-channel Flutter tests passed.
- Full repository analyze, boundary, source-text, test, dependency-audit, and
  diff-check gates passed before commit and push.

### 2026-08-11 - Codex - T138 Production Configuration Lifecycle Hardening

Summary:
- Mirrored mobile and desktop app shells invalidate the active loaded-session
  generation when the optional configuration factory is removed or replaced.
- A delayed loader result from the previous runtime/widget contract cannot push
  a stale route after rebuild.

Files changed:
- Mirrored app `main.dart` shells and app-shell widget tests.
- `HANDOFF.md`, `PROJECT_STATE.md`, `HANDOFF_QUEUE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop app-shell Flutter suites pass, including delayed
  stale completion after factory removal.
- Full repository gates remain to be run before commit and push.

### 2026-08-11 - Codex - T137 Production Handoff Staleness Hardening

Summary:
- Mirrored mobile and desktop shells assign a private generation token to each
  asynchronous loaded production-session handoff.
- Late success or failure from an older join/load is ignored after a newer
  handoff; disposal and higher-precedence route configuration invalidate the
  token before navigation.

Files changed:
- Mirrored app `main.dart` shells and app-shell widget tests.
- `HANDOFF.md`, `PROJECT_STATE.md`, `HANDOFF_QUEUE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop app-shell Flutter suites pass, including delayed
  stale loader completion.
- Full repository gates are required before commit and push.

Remaining:
- Product source/state invocation, production database persistence, real device
  and cross-device validation, other-platform hosts, and release signing remain
  external or product-owned.

### 2026-08-11 - Codex - T136 Production Snapshot Retry Ordering Hardening

Summary:
- Mirrored mobile and desktop snapshot coordinators retain newer accepted
  checkpoints FIFO behind repeatedly failing older checkpoints.
- Retry calls resolve the live pending queue after serialization, preventing a
  concurrent stale retry from writing older state after a newer checkpoint.
- Durable event suffix markers remain preserved so snapshot retries do not
  append the same event sequence twice.

Files changed:
- Mirrored production snapshot coordinators and focused coordinator tests.
- `HANDOFF.md`, `PROJECT_STATE.md`, `HANDOFF_QUEUE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Validation:
- Focused mobile and desktop coordinator Flutter suites pass.
- Full repository gates are required before commit and push.

Remaining:
- Product source/state invocation, production database persistence, real device
  and cross-device validation, other-platform hosts, and release signing remain
  external or product-owned.

### 2026-08-11 - Codex - T135 Production Snapshot Checkpoint Wiring

Summary:
- Mirrored production session factories now share one typed snapshot writer,
  event-plus-snapshot persistence writer, and serialized route coordinator.
- Accepted local projection suffixes and accepted remote events append through
  the existing event-log policy before typed snapshot checkpointing. Failed
  checkpoints remain ordered and retryable; accepted close/wipe retention
  clears pending checkpoint state.
- The default production surface exposes persistence-pending status and a
  retry action, while sync retry remains gated until durable checkpointing
  succeeds.

Files changed:
- Mirrored app production session configuration/factory, route registration,
  route, surface, source, persistence writer, and coordinator files.
- Mirrored coordinator tests.
- `HANDOFF.md`, `PROJECT_STATE.md`, `HANDOFF_QUEUE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable `docs/ai/` records.

Tests and gates:
- Focused mobile and desktop coordinator, persistence-writer, route,
  bootstrap, factory, and app-shell Flutter suites pass.
- Full repository gates are required before commit and push.

Risks and remaining boundaries:
- Product-owned concrete session/state source invocation, database persistence,
  real-device and cross-device validation, other-platform hosts, and release
  signing remain open.

Next reviewer:
- Continue with the next external/native or product-source boundary in
  `docs/PRODUCTION_READINESS.md` after full gates pass.

### 2026-08-11 - Codex - T134 Production Session Factory Loader Wiring

Summary:
- Mirrored app shells now accept a configured
  `AppHoldemProductionSessionConfigurationFactory` directly.
- A stable app-owned adapter invokes that factory for typed join/rejoin
  handoffs when no explicit loader is supplied; explicit route and handler
  precedence remains unchanged.
- The accepted session context still reaches the existing bootstrap route,
  while product state, route policy, and persistence remain caller-owned.

Tests and gates:
- Focused mobile and desktop app-shell Flutter suites pass, including the
  factory fallback and missing-snapshot fail-closed path.

Remaining:
- Concrete product source/state wiring, database persistence, native/device
  validation, other-platform hosts, and release signing remain external or
  owner-controlled.

Next reviewer:
- Review the mirrored runtime API and publish the green T134 commit.

---

### 2026-08-11 - Codex - T133 Native Host Build and Smoke Validation

Summary:
- Android debug APK and Windows debug host builds pass.
- The dedicated Windows smoke target passes app-storage, capture,
  local-network, transport, and secure-key mutation checkpoints through the
  default RTK-safe wrapper.
- The wrapper now resolves its default executable path when `PSScriptRoot` is
  empty under RTK PowerShell invocation.

Tests and gates:
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and diff-check gates pass; actionable upgrades: 0.

Remaining:
- Real device and cross-device network validation, other-platform hosts,
  product state/database wiring, and release signing remain external or
  owner-controlled.

Next reviewer:
- Review the bounded wrapper change and publish the green T133 commit.

---

### 2026-08-11 - Codex - T132 Typed Production Session Handoff Loader

Summary:
- Mirrored mobile and desktop shells now accept an optional
  `AppHoldemProductionSessionConfigurationLoader` from successful typed first
  join or rejoin context into the existing configuration-factory result.
- Dynamic routes reuse route validation, the bootstrap adapter, and native
  readiness gating; explicit handlers and prebuilt routes retain precedence.
- Unavailable, malformed, unsafe, colliding, or throwing loader results fail
  closed without exposing diagnostics.

Tests and gates:
- Focused mobile and desktop app-shell suites passed (80 each).
- Focused mobile and desktop Flutter analysis passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and diff-check gates passed; actionable upgrades: 0.

Remaining:
- Product source/state/route-policy wiring, platform/device validation,
  database persistence, and release signing remain separate owner work.

Next reviewer:
- Commit and publish the green T132 change after reviewing the mirrored diff.

---

### 2026-08-11 - Codex - T131 Production Recovery-Limit Propagation

Summary:
- Mirrored production bootstrap, route-registration, configuration, and
  session-factory seams now carry one validated `maxRecoveryEvents` value into
  the app session runtime.
- Persisted configuration reuses the value for source hydration and the app
  persistence writer, preventing default-limit drift across recovery paths.

Tests run:
- Focused mobile and desktop production-session suites passed (15 each).
- Focused mobile and desktop Flutter analysis passed.

Risks:
- This closes configuration drift in the app-owned recovery boundary; concrete
  product state wiring, native/device validation, database replacement, and
  release signing remain separate.

Next reviewer:
- Run the full local gate set and commit if green.

---

### 2026-08-11 - Codex - T130 App Session Event-Batch Bound

Summary:
- Mirrored `AppTableSessionRuntime` owners now enforce the shared
  `RecoveryEventWindowLimits.defaultMaxEvents` bound before copying or reducing
  caller-supplied non-retention event batches; callers can provide a smaller
  positive limit.
- Oversized batches fail closed with `ERR_APP_SESSION_EVENT_BATCH_TOO_LARGE`
  without changing runtime state.

Tests run:
- Focused mobile and desktop session-runtime suites passed (8 each).
- Focused mobile and desktop Flutter analysis passed.

Risks:
- This hardens the app inbound runtime boundary; concrete product session/state
  wiring, native runtime validation, other-platform implementations, and
  release signing remain separate.

Next reviewer:
- Run the full local gate set and commit if green.

---

### 2026-08-11 - Codex - T129 Persisted Session Writer Event Bound

Summary:
- Mirrored app production persistence writers now enforce the shared
  `RecoveryEventWindowLimits.defaultMaxEvents` bound before traversing or
  appending caller-supplied event suffixes; callers can provide a smaller
  positive limit.
- Oversized suffixes fail closed before snapshot validation and cannot create
  durable event or snapshot data.

Tests run:
- Focused mobile and desktop persistence-writer suites passed (8 each).
- Focused mobile and desktop Flutter analysis passed.

Risks:
- This hardens the app persistence boundary; concrete product session/state
  wiring, native runtime validation, other-platform implementations, and
  release signing remain separate.

Next reviewer:
- Run the full local gate set and commit if green.

---

### 2026-08-11 - Codex - T128 Persisted Session Recovery Window Bound

Summary:
- Mirrored app persisted Hold'em session sources now enforce the shared
  `RecoveryEventWindowLimits.defaultMaxEvents` bound immediately after a store
  returns a recovery window; callers can provide a smaller positive limit.
- Oversized windows fail closed before snapshot decoding, suffix allocation,
  lazy identity provisioning, or deterministic replay.

Tests run:
- Focused mobile and desktop persisted-session source suites passed (16 each).
- Focused mobile and desktop Flutter analysis passed.

Risks:
- This hardens the app adapter boundary; concrete product session/state wiring,
  native runtime validation, other-platform implementations, and release
  signing remain separate.

Next reviewer:
- Run the full local gate set and commit if green.

---

### 2026-08-11 - Codex - T127 Receipt Key-Ring Collection Bounds

Summary:
- Receipt-owned key-ring providers now bound retained verification and
  decryption collections to 128 entries by default before lookup traversal.
- Oversized retained collections fail closed while active usable keys remain
  available; the generic native bridge contract is unchanged.

Tests run:
- Focused receipt provider tests passed.
- Full repository analysis, boundary, source-text, dependency, and test gates
  passed.

Risks:
- Native secure-key runtime validation, other-platform implementations,
  product persistence/source wiring, and release inputs remain separate.

---

### 2026-08-11 - Codex - T126 Wizard Input and Compilation Bounds

Summary:
- `DefaultPresetResolver` now bounds preset/setup collections and validates
  nested values through bounded protocol canonical JSON before resolution.
- Direct drafts and `DefaultGameFileCompiler` plans repeat the boundary for
  resolved fields, policy profiles, and validation messages with stable
  `ERR_WIZARD_*` failures.

Tests run:
- Focused `peerdeal_wizard` resolver suite passed.
- Focused `peerdeal_wizard` compiler suite passed.
- Focused `peerdeal_wizard` analysis passed.

Risks:
- This hardens setup materialization and compilation while product source
  wiring, native reachability, durable database policy, and release inputs
  remain separate.

---

### 2026-08-11 - Codex - T125 Mode Governance Collection Bounds

Summary:
- `DefaultGovernanceEngine` now bounds participant, seat, and waitlist
  collections before lookup/traversal, with defaults of 256, 64, and 256.
- Oversized context inputs and waitlist growth at capacity return stable denial
  codes without changing mode ownership or policy semantics.

Tests run:
- Focused `peerdeal_modes` governance suite: 17 tests passed.
- Focused `peerdeal_modes` analysis passed.

Risks:
- This hardens the mode-policy boundary while product source wiring, native
  reachability, durable database policy, and release inputs remain separate.

---

### 2026-08-11 - Codex - T124 Core Pot Settlement Bounds

Summary:
- `peerdeal_core` now bounds direct commitments to 64, winning slice-map
  entries to 64, and winners per slice to 64 before pot or award traversal.
- `SidePotBuilder` and `PotEngine` fail closed with explicit core settlement
  warnings; Hold'em retains its tighter nine-entry upstream bound.

Tests run:
- Focused `peerdeal_core` pot suite: 10 tests passed.
- Focused `peerdeal_core` analysis passed.

Risks:
- This hardens the variant-agnostic core boundary while product source wiring,
  native reachability, durable database policy, and release inputs remain
  separate.

---

### 2026-08-11 - Codex - T123 Hold'em Showdown Projection Bounds

Summary:
- `ShowdownEvaluationResult` now bounds direct result collections, pot-slice
  maps, and per-slice contested seat-ID lists before projection materialization.
- Overflow carries explicit warnings through `ShowdownSliceWinnerProjection`
  and blocked settlement results without changing malformed-evaluation slice
  reporting.

Tests run:
- Focused `peerdeal_variants` projection suite: 52 tests passed.
- Focused `peerdeal_variants` analysis passed.

Risks:
- This protects direct variant projection callers while product source wiring,
  native reachability, durable database policy, and release inputs remain
  separate.

---

### 2026-08-11 - Codex - T122 Hold'em Settlement Commitment Bound

Summary:
- `ShowdownSettlementProjector` now bounds direct commitment collections to
  the shared nine-seat Hold'em launch limit before core side-pot construction.
- Both contested and uncontested settlement paths fail closed with
  `ERR_HOLDEM_SETTLEMENT_PROJECT_COMMITMENT_COUNT` on overflow.

Tests run:
- Focused settlement, coordinator, and evaluator suite: 48 tests passed.
- Focused `peerdeal_variants` analysis passed.

Risks:
- This protects the variant-to-core settlement boundary while direct core
  pot-builder callers, product source wiring, native reachability, durable
  database policy, and release inputs remain separate.

---

### 2026-08-11 - Codex - T121 Hold'em Showdown Seat Bound

Summary:
- `peerdeal_variants` now bounds direct Hold'em showdown seat collections to
  the shared nine-seat launch invariant before sorting, card expansion, or
  hand evaluation.
- Oversized input fails closed with `ERR_HOLDEM_SHOWDOWN_SEAT_COUNT`; adapter
  identity and configuration validation reuse the same limit.

Tests run:
- Focused `peerdeal_variants` suite: 147 tests passed.
- Focused `peerdeal_variants` analysis passed.

Risks:
- This hardens direct variant callers while product source wiring, native
  reachability, durable database policy, and release inputs remain separate.

---

### 2026-08-11 - Codex - T120 Network Collection Bounds

Summary:
- `peerdeal_network` now bounds direct peer-id, candidate, and peer-metric
  collections before routing or confidence materialization.
- Shared defaults are 32 peer IDs, 32 candidates, and 64 peer metrics;
  overflow returns empty, unresolved, or unsafe fail-closed results.

Tests run:
- Focused `peerdeal_network` suite: 42 tests passed.
- Focused `peerdeal_network` analysis passed.

Risks:
- This hardens package-level direct callers while native reachability,
  platform runtime, product source, and database policy remain separate.

---

### 2026-08-11 - Codex - T119 Direct Sync Request Scope Validation

Summary:
- Direct `RecoveryRequest` and `SnapshotApplyRequest` processing now validates
  table, session, and protocol identities through shared
  `RecoveryPersistenceScope` rules before event, snapshot, or projector work.
- Invalid direct scopes return `ERR_RECOVERY_SCOPE_INVALID` or
  `ERR_SNAPSHOT_APPLY_SCOPE_INVALID`.

Tests run:
- Focused `peerdeal_sync` suite: 70 tests passed.
- Focused `peerdeal_sync` analysis passed.

Risks:
- This hardens direct Dart sync ingress but does not define product identity,
  database persistence, platform runtime, or device validation policy.

---

### 2026-08-11 - Codex - T118 Recovery Scope Storage-Key Bound

Summary:
- `RecoveryPersistenceScope` now bounds the complete UTF-8 storage key to 180
  bytes before in-memory indexing or base64url filename generation.
- In-memory and JSON recovery stores reject oversized scopes with
  `ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID` before mutation or file creation.

Tests run:
- Focused `peerdeal_sync` suite: 68 tests passed.
- Focused `peerdeal_sync` analysis passed.

Risks:
- The bound hardens the existing JSON fallback and does not replace the
  product database or define product identity policy.

---

### 2026-08-11 - Codex - T117 Direct Sync Snapshot Bounds

Summary:
- `BasicConflictDetector` and `BasicSnapshotApplier` now validate supplied
  snapshots through bounded canonical JSON before protocol, scope, or
  snapshot/suffix projection work.
- The shared default is 4 MiB with protocol structure limits; failures return
  `ERR_RECOVERY_SNAPSHOT_TOO_LARGE` or `ERR_RECOVERY_SNAPSHOT_INVALID`.
- The JSON recovery store's default file limit now shares the same snapshot
  limit constant.

Tests run:
- Focused `peerdeal_sync` suite: 66 tests passed.
- Focused `peerdeal_sync` analysis passed.

Risks:
- This bounds direct Dart sync processors only. Product database persistence,
  platform/runtime validation, other-platform hosts, and release signing
  remain separate.

Next reviewer:
- Preserve event-count, event-codec, and snapshot canonical validation before
  adding transport or product session callers around recovery.

---

### 2026-08-11 - Codex - T116 Direct Sync Event Codec Bounds

Summary:
- `BasicConflictDetector` and `BasicSnapshotApplier` now validate each direct
  caller-provided event through the existing `EventEnvelopeCodec` before
  protocol, scope, sequence, or projector work.
- The shared default is 64 KiB per event with protocol canonical structure
  limits; failures return `ERR_RECOVERY_EVENT_TOO_LARGE` or
  `ERR_RECOVERY_EVENT_INVALID`.

Tests run:
- Focused `peerdeal_sync` suite: 64 tests passed.
- Focused `peerdeal_sync` analysis passed.

Risks:
- This bounds direct Dart sync processors only. Product database persistence,
  platform/runtime validation, other-platform hosts, and release signing
  remain separate.

Next reviewer:
- Preserve event-count and codec validation before adding transport or product
  session callers around conflict detection and snapshot application.

---

### 2026-08-11 - Codex - T115 Direct Sync Event Window Bounds

Summary:
- `BasicConflictDetector` and `BasicSnapshotApplier` now reject direct
  caller-provided recovery event lists above the shared configurable default of
  4,096 events before protocol, scope, sequence, or projector traversal.
- Oversized input returns the fatal `ERR_RECOVERY_EVENT_COUNT_TOO_LARGE` code;
  durable stores retain their existing persistence-specific limits and codes.

Tests run:
- Focused `peerdeal_sync` suite: 61 tests passed.
- Focused `peerdeal_sync` analysis passed.

Risks:
- This bounds direct Dart sync processors only. Product database persistence,
  platform/runtime validation, other-platform hosts, and release signing
  remain separate.

Next reviewer:
- Preserve the shared sync event bound before adding transport or product
  session callers around conflict detection and snapshot application.

---

### 2026-08-11 - Codex - T114 Replay Anchor And Selection Bounds

Summary:
- Oversized replay requests now return before any secondary protocol, scope,
  range, or event traversal.
- Anchor hashing and snapshot-suffix planning enforce the shared default bound
  of 4,096 events; anchor hashing supplies canonical list/node limits for that
  window.
- `BasicReplayEngine` converts helper failures into
  `ERR_REPLAY_SELECTION_FAILURE` or
  `ERR_REPLAY_ANCHOR_CALCULATION_FAILURE` mismatches.

Tests run:
- Focused replay suite: 33 tests passed.
- Focused protocol envelope/hash suite: 53 tests passed.
- Focused replay and protocol analysis passed.

Risks:
- This hardens replay and protocol hashing boundaries only. Product persistence,
  platform/runtime validation, other-platform hosts, and release signing remain
  separate.

Next reviewer:
- Preserve the shared replay bound and structured helper-failure mapping when
  adding replay transports or product session sources.

---

### 2026-08-11 - Codex - T113 Replay Event Window Bounds

Summary:
- `EventWindowValidator` now enforces a configurable positive event-count
  limit, defaulting to 4,096 events.
- `BasicReplayEngine` checks the raw request list before protocol, scope, range,
  selection, or projector traversal and returns
  `ERR_REPLAY_EVENT_WINDOW_TOO_LARGE` when the limit is exceeded.

Tests run:
- Focused replay engine and snapshot suffix suite: 24 tests passed.
- Focused `peerdeal_replay` analysis passed.

Risks:
- This hardens the Dart replay request boundary only. Product persistence,
  platform/runtime validation, other-platform hosts, and release signing remain
  separate.

Next reviewer:
- Preserve the event-count bound when adding replay transports or product
  session sources; do not move replay policy into protocol or native bridges.

---

## Format

### YYYY-MM-DD - Agent - Task

Summary:
Files changed:
Tests run:
Risks:
Next reviewer:

### 2026-08-11 - Codex - T108 Provider-Proof Normalization Bounds

Summary:
- Added public `DealProofLimits` defaults for provider identity/reference text,
  maps, lists, nesting, node count, and canonical UTF-8 proof bytes.
- `DefaultProviderProofNormalizer` now rejects unsupported/non-finite values,
  non-string keys, and overflow before bundle construction, while normalized and
  raw views share one immutable bounded payload.

Files changed:
- Crypto limits model, normalizer, barrel, README, and focused regression tests.
- Readiness ledger, handoff queue, project state, and stable AI context docs.

Tests run:
- Focused provider-proof normalization suite: 6 tests passed.
- Focused `peerdeal_crypto` analysis passed.

Risks:
- Provider-specific proof semantics, product verification wiring,
  platform/runtime validation, other-platform hosts, production persistence,
  and release signing remain separate.

Next reviewer:
- Preserve `DealProofLimits` when adding provider adapters; do not move proof
  semantics into protocol, app orchestration, or generic native bridges.

---

### 2026-08-11 - Codex - T112 Protocol Envelope Hydration Bounds

Summary:
- `EventEnvelope.fromJson` and `SnapshotEnvelope.fromJson` now validate full
  materialized JSON trees through bounded canonical protocol serialization
  before typed field access.
- File-backed recovery fails closed on structurally oversized persisted
  snapshot payloads before importing them into in-memory recovery state.

Tests run:
- Focused protocol envelope/fixture suite: 54 tests passed.
- Focused file-backed recovery suite: 26 tests passed.
- Focused protocol and sync analysis passed.

Risks:
- This hardens Dart protocol and recovery hydration only. Product database
  selection, source wiring, platform/runtime validation, other-platform hosts,
  and release signing remain separate.

Next reviewer:
- Preserve bounded canonical validation for any new direct protocol model
  hydration path and keep sync persistence policy outside protocol models.

---

### 2026-08-11 - Codex - T111 Typed State Hydration Bounds

Summary:
- `TableState`, `HoldemSeatState`, `HoldemHandState`, `HoldemEventCursor`, and
  `HoldemStateSnapshot` now validate materialized JSON through bounded canonical
  protocol serialization before typed field or collection materialization.
- Oversized maps/lists and unsupported nested values fail closed without moving
  core truth, variant rules, or product persistence ownership.

Tests run:
- Focused core hydration/invariant suite: 13 tests passed.
- Focused Hold'em hydration/snapshot suites: 9 tests passed.
- Focused core and variant analysis passed.

Risks:
- This bounds Dart-side typed hydration only. Product persistence/source wiring,
  platform/runtime validation, other-platform hosts, and release signing remain
  separate.

Next reviewer:
- Preserve protocol canonical limits at new typed hydration entry points and
  keep product persistence and platform validation outside package models.

---

### 2026-08-11 - Codex - T110 Receipt JSON Structure Bounds

Summary:
- `OpaqueExportDecoder` now validates decoded artifact-body and plaintext-payload
  JSON through bounded canonical protocol serialization before receipt shape
  inspection, using receipt-owned decoded-body and payload byte limits.
- Structurally oversized maps, deep values, unsupported values, and invalid
  object keys fail closed without changing receipt signature, cipher, opacity,
  or authorization semantics.

Files changed:
- Receipt decoder, README, and focused regression tests.
- Readiness ledger, handoff queue, project state, and stable AI context docs.

Tests run:
- Focused receipt artifact decoder suite: 13 tests passed.
- Focused `peerdeal_receipts` analysis passed.

Risks:
- This bounds receipt JSON decode structure in Dart. Platform key storage,
  runtime/device validation, product persistence, other-platform hosts, and
  release signing remain separate.

Next reviewer:
- Preserve receipt-owned byte limits when adding new artifact fields and keep
  cryptographic/key-storage semantics outside the generic protocol serializer.

---

### 2026-08-11 - Codex - T109 Canonical JSON Materialization Bounds

Summary:
- Added bounded deterministic canonical JSON writing in `peerdeal_protocol`
  with map/list, nesting, UTF-8 text, node, and encoded-byte limits.
- Event wire encode and decode validation now share the configured wire-byte
  cap and fail closed on unsupported values or non-string object keys.

Files changed:
- Canonical JSON limits/writer, event codec, protocol barrel, README, and tests.
- Readiness ledger, handoff queue, project state, and stable AI context docs.

Tests run:
- Focused protocol canonical JSON and event codec suites passed.
- Focused `peerdeal_protocol` analysis passed.

Risks:
- This bounds protocol serialization and event wire validation. Protocol schema
  semantics, product persistence, platform/runtime validation, other-platform
  hosts, and release signing remain separate.

Next reviewer:
- Preserve the canonical limits when adding protocol payload families and keep
  product/database selection outside `peerdeal_protocol`.

---

### 2026-08-11 - Codex - T107 Privacy Diagnostics Bounds

Summary:
- `DefaultDiagnosticsScrubber` now bounds recursive maps and lists at 64
  entries, nested depth at 8, text at 512 UTF-8 bytes, and protocol
  diagnostics at 64 items.
- Overflow emits stable `<truncated>` markers or
  `ERR_DIAGNOSTICS_TRUNCATED` while sensitive-field redaction remains intact.

Files changed:
- Privacy scrubber, focused regression tests, and privacy README.
- Readiness ledger, handoff queue, project state, and stable AI context docs.

Tests run:
- Focused `peerdeal_privacy` diagnostics suite: 6 tests passed.
- Focused `peerdeal_privacy` analysis passed.

Risks:
- This bounds the shared privacy scrubbing boundary. App rendering,
  production database replacement, platform/runtime validation,
  other-platform hosts, product startup integration, and release signing
  remain separate.

Next reviewer:
- Preserve these limits when adding new diagnostics-producing adapters or
  widening shareable-field payloads.

---

### 2026-08-11 - Codex - T106 Recovery Event-Window Bounds

Summary:
- `peerdeal_sync` in-memory and JSON recovery stores now enforce configurable
  event-count and per-event byte limits, defaulting to 4,096 events and the
  protocol codec's 64 KiB event bound.
- Oversized append batches, hydrated JSON windows, and individual events fail
  closed before recovery state mutation with stable fatal conflicts.

Files changed:
- Sync recovery stores, focused persistence tests, and sync README.
- Readiness ledger, handoff queue, project state, and stable AI context docs.

Tests run:
- Focused `peerdeal_sync` recovery persistence suite: 25 tests passed.
- Focused `peerdeal_sync` analysis passed.

Risks:
- This bounds the in-memory and JSON recovery seam only. Production database
  replacement, platform/runtime persistence validation, product startup
  integration, other-platform hosts, and release signing remain separate.

Next reviewer:
- Preserve the event-count and canonical protocol byte limits when a concrete
  product persistence source replaces or supplements the JSON fallback.

---

### 2026-08-11 - Codex - Production Rejoin Metadata Gate

Summary:
- Mirrored persisted Hold'em route policies now validate dynamic remote-peer
  and local-seat overrides inside `buildInput(...)`.
- Direct source consumers cannot bypass the bootstrap's first-join/rejoin
  metadata validation before production input construction.

Files changed:
- Mirrored persisted production-session source implementations and focused
  regression tests.
- Readiness ledgers and stable AI context docs.

Tests run:
- Mobile and desktop persisted-source suites: 14 tests each passed.
- Focused mirrored app analysis passed.
- Full analyzer, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Dependency audit reports zero actionable upgrades and 11 newer versions below
  the current toolchain ceiling.

Risks:
- This hardens metadata validation only. Product state selection, startup,
  database persistence, native/device validation, and release signing remain
  separate boundaries.

Next reviewer:
- Preserve the dynamic peer/seat validation when connecting a real product
  source to first-join and rejoin route handoffs.

---

### 2026-08-11 - Codex - Hold'em Event-Log Checkpoint Writer

Summary:
- Added mirrored `AppHoldemProductionSessionPersistenceWriter` app boundaries.
- The writer validates a caller-supplied non-retention event suffix, appends it
  to recovery, and then persists the resulting canonical typed snapshot.
- Configuration-factory results expose this writer alongside `snapshotWriter`.

Files changed:
- Mirrored app persistence-writer files and focused tests.
- Mirrored configuration factories and focused tests.
- Readiness ledgers and stable AI context docs.

Tests run:
- Mobile and desktop focused factory plus persistence-writer suites: 8 tests
  each passed.
- Focused mirrored app analysis passed.
- Full analyzer, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Dependency audit reports zero actionable upgrades and 11 newer versions below
  the current toolchain ceiling.

Risks:
- Product startup still owns authoritative state, event identity, snapshot IDs,
  route/retention policy, database replacement, and native/device validation.

Next reviewer:
- Invoke `persistenceWriter` only after the product state owner has accepted
  the event batch and close-retention policy has been handled separately.

---

### 2026-08-11 - Codex - Recovery Store Process Serialization

Summary:
- Hardened `JsonFileRecoveryPersistenceStore` with a stable per-scope OS file
  lock around hydrate-modify-write transactions, reads, and wipes.
- Lock handles close on all paths so process termination releases the advisory
  lock; lock acquisition failures return a fatal persistence result.
- The public `RecoveryPersistenceStore` contract and package boundaries remain
  unchanged.

Files changed:
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- Readiness ledgers and stable AI context docs.

Tests run:
- Focused `peerdeal_sync` recovery persistence suite: 16 tests passed.
- Full analyzer, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Dependency audit reports zero actionable upgrades and 11 newer versions below
  the current toolchain ceiling.

Risks:
- This hardens the JSON recovery fallback but does not replace a production
  database or prove platform filesystem, device, or cross-device behavior.

Next reviewer:
- Preserve the per-scope lock when replacing the fallback with a database or
  adding additional recovery-store implementations.

---

### 2026-08-11 - Codex - Typed Hold'em Snapshot Persistence

Summary:
- Added mirrored `AppHoldemProductionSessionSnapshotWriter` app boundaries.
- The writer validates snapshot identity, recovery scope, cursor sequence, and
  last-event hash consistency, creates a canonical-hashed typed
  `HoldemStateSnapshot` envelope, delegates the recovery store, and fails closed.
- T93 configuration-factory results expose the writer over the same validated
  store.

Files changed:
- Mirrored snapshot writer files and focused tests.
- Mirrored configuration factories and focused tests.
- Readiness ledgers, demo-slice READMEs, and stable AI context docs.

Tests run:
- Combined mobile and desktop factory plus snapshot-writer suites: 7 tests each
  passed.
- Focused mirrored app analysis passed.
- Full analyzer, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Dependency audit reports zero actionable upgrades and 11 newer versions below
  the current toolchain ceiling.

Risks:
- Product state selection, event-log append policy, database persistence,
  startup invocation, native reachability, device validation, and release
  signing remain integration or operator work.

Next reviewer:
- Use `snapshotWriter` only after the real product state owner has canonical
  state and event-cursor inputs.

---

### 2026-08-11 - Codex - App-Owned Persisted Session Configuration Factory

Summary:
- Added mirrored `AppHoldemProductionSessionConfigurationFactory` boundaries
  for the app startup edge.
- The factory composes the existing recovery-store factory, lazy native local
  identity provisioner, persisted Hold'em source, caller-owned route policy,
  and deterministic event/replay/session dependencies.
- It returns an explicit available/unavailable result, preserves recovery
  warnings, validates route policy before identity work, and fails closed on
  invalid composition.

Files changed:
- Mirrored app session configuration factory files and focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, both demo-slice READMEs, and stable AI
  context docs.

Tests run:
- Focused mobile and desktop Flutter factory suites: 3 tests each passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Dependency audit reports zero actionable upgrades and 11 newer versions
  below the current toolchain ceiling.

Risks:
- Product snapshot selection/writing, startup invocation, route/retention
  policy, native reachability, Android device validation, other-platform
  implementations, and release signing remain integration or operator work.

Next reviewer:
- Invoke the factory from the real product session owner once authoritative
  snapshot persistence and route policy are available.

---

### 2026-08-10 - Codex - Local Identity Post-Save Verification

Summary:
- Added mirrored read-after-write verification for generated local peer IDs.
- Provisioning now fails closed when native storage returns a different,
  missing, ambiguous, malformed, or unavailable identity after save.

Files changed:
- `apps/peerdeal_mobile/lib/session/native_local_peer_identity_provisioner.dart`
- `apps/peerdeal_desktop/lib/session/native_local_peer_identity_provisioner.dart`
- Matching focused identity tests and durable handoff/readiness docs.

Tests run:
- Focused mobile and desktop identity suites: 7 passed each.
- Contention coverage asserts a mismatched native read-back cannot produce a
  successful provision result.

Risks:
- Read-back detects persistence contention but does not provide cross-process
  compare-and-swap. Real-device keystore/Credential Manager validation remains
  external.

Next reviewer:
- Preserve the verification step when connecting the provisioner to a concrete
  production source lifecycle.

---

### 2026-08-10 - Codex - Single-Flight Local Identity Provisioning

Summary:
- Hardened mirrored app-owned local identity provisioners against concurrent
  first-use calls.
- One in-flight load/generate/save operation is shared; failed operations clear
  the guard and remain retryable.

Files changed:
- `apps/peerdeal_mobile/lib/session/native_local_peer_identity_provisioner.dart`
- `apps/peerdeal_desktop/lib/session/native_local_peer_identity_provisioner.dart`
- Matching focused identity tests and durable handoff/readiness docs.

Tests run:
- Focused mobile and desktop identity suites: 6 passed each.
- The new overlapping-call case asserts one load, one generated ID, and one
  persisted save.

Risks:
- The guard is per app-process provisioner instance; cross-process locking and
  real-device persistence remain external validation.

Next reviewer:
- Preserve the single-flight boundary when wiring the provisioner into a real
  production source lifecycle.

---

### 2026-08-10 - Codex - Provisioned Identity Persisted-Source Composition

Summary:
- Added mirrored app-owned composition factories for the existing typed
  persisted Hold'em production source.
- The factory provisions or reuses the local secure identity, maps it to
  `localPeerId`, and accepts caller-owned route, remote-peer, local-seat, and
  close-event policy.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_persisted_holdem_production_session_source.dart`
- `apps/peerdeal_desktop/lib/session/app_persisted_holdem_production_session_source.dart`
- Matching focused source tests and durable handoff/readiness docs.

Tests run:
- Focused mobile and desktop source tests: 6 passed each.
- Focused mobile and desktop analyzers: passed.

Risks:
- Database selection, remote-peer discovery, native runtime validation, and
  release credentials remain caller/operator-owned.

Next reviewer:
- Wire this factory at a real product route only when the product persistence
  store and remote-peer policy are available.

---

### 2026-08-10 - Codex - App-Owned Local Peer Identity Persistence

Summary:
- Added mirrored secure-key-backed local peer identity loaders, writers, and
  provisioners in the app shells.
- The adapters reuse exactly one active valid identity, provision a secure
  random ID only when storage is empty, and fail closed on unavailable,
  malformed, inactive, or ambiguous records.

Files changed:
- Mirrored app `session/native_local_peer_identity_loader.dart`,
  `native_local_peer_identity_writer.dart`, and
  `native_local_peer_identity_provisioner.dart`.
- Mirrored focused local identity tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Tests run:
- Focused mobile local identity suite: passed, 5 tests.
- Focused desktop local identity suite: passed, 5 tests.
- Focused mobile and desktop analyzers: passed.

Risks:
- Concrete production source/route composition, database wiring, native/device
  runtime validation, and release signing remain integration or operator-owned.

Next reviewer:
- Compose the provisioned identity with the real product session source and
  route policy when those product-owned inputs are available.

---

### 2026-08-10 - Codex - Deterministic Persisted Recovery-Suffix Replay

Summary:
- Added atomic `HoldemCoreProjectionAdapter.replay(...)` composition across
  cursor acceptance, `CoreReducer`, and `HoldemEventReducer`.
- Mirrored persisted production sources now replay valid recovery suffixes and
  fail closed on tampered or unsupported events without partial state.

Files changed:
- `packages/peerdeal_variants/lib/src/holdem/holdem_core_projection_adapter.dart`
  and focused replay tests.
- Mirrored app persisted-session sources and focused source tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Tests run:
- Focused variants replay/projection tests: passed, 7 tests total.
- Focused mobile persisted-source suite: passed, 5 tests.
- Focused desktop persisted-source suite: passed, 5 tests.
- Focused variants and app analyzers: passed.

Risks:
- Product database wiring, local identity, native/device validation, and
  release signing remain integration or operator-owned.

Next reviewer:
- Supply the real product source and identity mapping, or continue with the
  documented native/device runtime validation gates.

---

### 2026-08-10 - Codex - Typed Persisted Hold'em Production Source

Summary:
- Added `HoldemStateSnapshot` to compose strict table, Hold'em hand, and event
  cursor hydration with exact scope and snapshot sequence checks.
- Added mirrored mobile and desktop persisted-session source adapters over the
  existing recovery store. They invoke a caller-owned input factory and fail
  closed on missing, unsupported, mismatched, or unreplayed snapshot data.

Files changed:
- `packages/peerdeal_variants/lib/src/holdem/holdem_state_snapshot.dart` and
  its public export/test.
- Mirrored app `session/` source adapters and focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Tests run:
- Focused mobile persisted-source suite: passed, 4 tests.
- Focused desktop persisted-source suite: passed, 4 tests.
- Package and mirrored app analyzers: passed.

Risks:
- Product database wiring, local identity, recovery suffix replay,
  native/device validation, and release signing remain integration or
  operator-owned.

Next reviewer:
- Supply the real product source and identity mapping, or continue with the
  documented native/device runtime validation gates.

---

### 2026-08-10 - Codex - Hold'em Event-Cursor Persistence Parser

Summary:
- Added strict `HoldemEventCursor.toJson/fromJson` coverage for scope,
  sequence, hash-chain predecessor, actor, and last-event state.
- Hydration requires caller-owned event-id and timestamp factories and accepts
  an optional caller-owned hash factory; no runtime policy is invented.

Files changed:
- `packages/peerdeal_variants/lib/src/holdem/holdem_core_projection_adapter.dart`.
- `packages/peerdeal_variants/test/holdem_event_cursor_persistence_test.dart`.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused cursor persistence suite: passed, 3 tests.
- Real JSON encode/decode round-trip: passed.
- Package analyzer: passed.

Risks:
- Product persistence wiring, local identity, native/device validation, and
  release signing remain integration or operator-owned.

Next reviewer:
- Compose this cursor with the typed table and Hold'em state parsers from the
  product-owned session source.

---

### 2026-08-10 - Codex - Hold'em State Persistence Parser

Summary:
- Added strict `HoldemHandState` and `HoldemSeatState` JSON serialization and
  hydration in the variant package.
- Enum names, nested seat objects, collections, nullable fields, and primitive
  types fail closed when malformed.

Files changed:
- `packages/peerdeal_variants/lib/src/holdem/holdem_hand_state.dart`.
- `packages/peerdeal_variants/test/holdem_hand_state_persistence_test.dart`.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused variant persistence suite: passed, 3 tests.
- Real JSON encode/decode round-trip: passed.
- Package analyzer: passed.

Risks:
- Product source provisioning, durable database wiring, local identity, and
  native/device runtime validation remain integration or operator-owned.

Next reviewer:
- Use the typed variant parser from a product-owned source once its persistence
  and identity contracts are supplied.

---

### 2026-08-10 - Codex - Core Table-State Hydration Parser

Summary:
- Added strict `TableState.fromJson(...)` hydration matching the existing
  `TableState.toJson()` shape.
- Malformed primitive fields, unknown phases, and non-string metadata keys fail
  closed before state hydration.

Files changed:
- `packages/peerdeal_core/lib/src/models/table_state.dart`.
- `packages/peerdeal_core/test/invariant_guards_test.dart`.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused core invariant/model suite: passed, 13 tests.
- Real JSON encode/decode round-trip: passed.

Risks:
- Full product source, durable database wiring, and local identity provisioning
  remain integration-owned.

Next reviewer:
- Use this typed table-state parser from an authoritative product persistence
  source once its state schema is supplied.

---

### 2026-08-10 - Codex - Production Table Local-Seat Action Routing

Summary:
- Mirrored production Hold'em table surfaces now use the configured local seat
  for Fold, Call/Check, and All-in actions instead of hard-coded seat zero.
- Focused route tests decode the canonical outbound event and assert local seat
  1 attribution in both app shells.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_table_surface.dart`.
- `apps/peerdeal_desktop/lib/session/app_holdem_production_table_surface.dart`.
- Mirrored `app_holdem_table_session_route_test.dart` files.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused mobile and desktop production-table route suites: passed, 8 tests
  each.
- Full repository analyzer and test gate: passed.

Risks:
- Device/network transport validation and final production UX validation remain
  external.

Next reviewer:
- Continue with the next codable production gap while preserving app-owned
  local-seat identity and canonical event attribution.

---

### 2026-08-10 - Codex - Shared Action Hit Target Hardening

Summary:
- Shared action controls now enforce a 48 logical-pixel minimum interactive
  height while preserving the existing focus behavior and public API.

Files changed:
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_action_button.dart`.
- `packages/peerdeal_ui_kit/test/app_shell_widgets_test.dart`.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused UI-kit widget suite: passed, 4 tests.
- Shared UI-kit analyzer: passed.

Risks:
- Device, text-scale, screen-reader, and final visual validation remain
  external.

Next reviewer:
- Validate action targets and text scaling on production Android and Windows
  profiles.

---

### 2026-08-10 - Codex - Shared Action Keyboard Focus Hardening

Summary:
- Shared action controls now own a focus node, expose focusable semantics,
  request focus on pointer activation, and bind Enter, numpad Enter, and Space
  to the same action callback.
- The focus outline uses a stable border width so keyboard navigation does not
  shift surrounding layout.

Files changed:
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_action_button.dart`.
- `packages/peerdeal_ui_kit/test/app_shell_widgets_test.dart`.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused UI-kit widget suite: passed, 4 tests.
- Shared UI-kit analyzer: passed.

Risks:
- Device keyboard, screen-reader, text-scale, and final visual validation
  remain external.

Next reviewer:
- Validate keyboard and assistive-technology behavior on production Android
  and Windows profiles.

---

### 2026-08-10 - Codex - Production Hold'em UI Hardening

Summary:
- Shared action controls now expose explicit labels and tap actions through
  semantics; shared fact rows combine label/value semantics and stack below
  360px to avoid narrow-layout overflow.
- Mirrored production Hold'em surfaces now use human-readable phase and
  betting-round labels, render no idle `Seat 0`, and expose the seats section
  as a semantic header.

Files changed:
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_action_button.dart`.
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_info_row.dart` and its
  focused widget test.
- Mirrored `apps/peerdeal_mobile/` and `apps/peerdeal_desktop/` Hold'em surface
  and session-route tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused UI-kit widget suite: passed, 3 tests.
- Focused mobile and desktop production table/session suites: passed, 8 tests
  each.
- Android debug APK and Windows debug host builds passed.

Risks:
- Final visual design review, text-scale/device validation, native runtime
  validation, product source provisioning, and durable persistence remain open.

Next reviewer:
- Validate the mirrored surfaces at production device sizes and accessibility
  text scales, then continue with the real product source/state integration.

---

### 2026-08-10 - Codex - Fail-Closed Android Release Signing

Summary:
- Android Gradle release tasks now fail before artifact assembly unless all four
  operator-owned signing values are present, unpadded, control-free, and backed
  by an existing keystore file.
- Release output cannot silently use debug signing or remain unsigned; debug
  builds remain the explicit unsigned validation path.

Files changed:
- `apps/peerdeal_mobile/android/app/build.gradle.kts`.
- `apps/peerdeal_mobile/README.md`, `docs/PRODUCTION_READINESS.md`,
  `docs/ai/API_CONTRACTS.md`.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, and `PROJECT_STATE.md`.

Tests run:
- Android release build without signing values: failed closed at Gradle
  configuration with the expected stable signing error.
- Android debug APK build: passed.

Risks:
- Operator-owned signing credentials, Android device/profile validation, and
  release distribution verification remain external.

Next reviewer:
- Supply signing values only through the operator-controlled release pipeline
  and validate the signed artifact on a real Android profile.

---

### 2026-08-10 - Codex - Runtime Production Session Configuration

Summary:
- Added mirrored `AppHoldemProductionSessionConfiguration.fromSource(...)`
  runtime configuration objects.
- Each app runtime derives one stable source-backed route registration and
  reuses it for production route merging, native-readiness gating, and default
  join handoff.
- Supplying both the explicit registration and runtime configuration fails
  closed with `StateError`; no product state, identity, persistence, or native
  transport ownership moved into the shell.

Files changed:
- Mirrored app runtime, configuration, and app-shell test files.
- Mirrored app READMEs, `docs/PRODUCTION_READINESS.md`, and stable AI context.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, and `PROJECT_STATE.md`.

Tests run:
- Focused mobile and desktop app-shell suites: 78 tests each, passed.
- Android debug APK and Windows debug host builds: passed.
- Full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit`: passed.
- Dependency audit: 0 actionable upgrades; 11 newer versions below the
  current toolchain ceiling.
- Dart format and `git diff --check`: passed.

Risks:
- The concrete product source, authoritative state persistence/serialization,
  local identity provisioning, device/network validation, other-platform
  hosts, release signing, and final UX remain open.

Next reviewer:
- Supply the source-backed configuration from the real product session owner
  once its persistence and identity contracts exist; keep the app and generic
  native package boundaries intact.

---

### 2026-08-10 - Codex - Source-Backed Bootstrap Route Assembly

Summary:
- Added mirrored `AppHoldemProductionSessionBootstrapRouteRegistration.fromSource(...)`
  factories.
- The app boundary now assembles a product-owned source with the existing
  bootstrap, optional session factory, and positive load timeout before the
  default join-ready route handoff.
- The factory does not create product state, local identity, persistence, or
  native transport; those remain caller-owned.

Files changed:
- Mirrored app session registration files and app-shell tests.
- Both app READMEs, `docs/PRODUCTION_READINESS.md`, `docs/ai/REPO_BRIEF.md`,
  `docs/ai/ARCHITECTURE_MAP.md`, `docs/ai/API_CONTRACTS.md`.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, and `PROJECT_STATE.md`.

Tests run:
- Focused mobile and desktop app-shell suites passed, 77 tests each.
- Android `flutter build apk --debug --no-pub` passed.
- Windows `flutter build windows --debug --no-pub` passed.
- Full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- Dart format and `git diff --check` passed.

Risks:
- The concrete product source, durable persistence, local identity, native
  device validation, release signing, other-platform hosts, and final UX remain
  open.

Next reviewer:
- Run the full repository gates and supply a real product-owned source when its
  persistence and identity contracts are available.

---

### 2026-08-10 - Codex - App-Shell Bootstrap Route Registration

Summary:
- Added mirrored app-owned `AppHoldemProductionSessionBootstrapRouteRegistration`
  descriptors.
- Both app runtimes can now merge the existing bootstrap route into the
  production route map and native-readiness gate. Accepted joined/rejoined
  outcomes use a cached default handler to push the registered path when no
  explicit `JoinFlowReadyHandler` is supplied; explicit handlers still win.
- The registration remains route plumbing and does not create product source,
  session state, local identity, or persistence.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_bootstrap_route_registration.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- Mirrored desktop app-shell files.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`.
- `docs/PRODUCTION_READINESS.md`, `docs/ai/API_CONTRACTS.md`,
  `docs/ai/ARCHITECTURE_MAP.md`, and both app READMEs.

Tests run:
- Focused mobile and desktop app-shell suites passed, 77 tests each.
- Full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- Dart format and `git diff --check` passed.

Risks:
- Concrete product source hydration, local identity, durable persistence,
  Android/Windows device validation, release signing, other-platform hosts,
  and final UX remain open.

Next reviewer:
- Run the full local gate set, then wire a real product source and local identity
  through the registered handoff without using demo or fixture state.

---

### 2026-08-10 - Codex - Cancellable Production Session Hydration

Summary:
- Added an optional `Future<void>? cancellation` signal to mirrored
  `AppHoldemProductionSessionSource` and bootstrap contracts.
- Route replacement and disposal now cancel stale source waits. Bootstrap
  cleanup cancels its timeout timer on source completion, cancellation, timeout,
  or failure.

Files changed:
- Mirrored app session bootstrap, route, and focused test files.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`.
- `docs/PRODUCTION_READINESS.md`, `docs/ai/API_CONTRACTS.md`,
  `docs/ai/ARCHITECTURE_MAP.md`, and this handoff log.

Tests run:
- Focused mobile bootstrap and bootstrap-route tests: passed, 13 tests.
- Focused desktop bootstrap and bootstrap-route tests: passed, 13 tests.
- Full `melos run analyze`, `boundary-check`, `source-text`, serialized
  `test`, and `dependency-audit` gates: passed.
- Dependency audit: 0 actionable upgrades; 11 newer versions remain blocked by
  the current Dart/Flutter toolchain.
- `git diff --check`: passed.

Risks:
- The signal stops app waiting and deadline timers but does not cancel
  underlying product persistence or network work by itself. Concrete source
  integration, local identity, native/device validation, durable database
  persistence, and final UX remain open.

Next reviewer:
- Wire the signal into the concrete product source's cancellation mechanism;
  preserve the app-owned handoff and generic native package boundaries.

---

### 2026-08-10 - Codex - Bounded Production Session Hydration

Summary:
- Mirrored `AppHoldemProductionSessionBootstrap` owners now enforce a positive
  configurable source-load timeout with a five-second default.
- Mounted bootstrap routes render a loading surface while product state is
  pending and fail closed after timeout or source failure.

Files changed:
- `apps/peerdeal_mobile/lib/session/`
- `apps/peerdeal_mobile/test/session/`
- `apps/peerdeal_desktop/lib/session/`
- `apps/peerdeal_desktop/test/session/`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused mobile bootstrap and bootstrap-route tests: passed, 10 tests.
- Focused desktop bootstrap and bootstrap-route tests: passed, 10 tests.

Risks:
- The timeout bounds the bootstrap future but cannot cancel product-owned work
  beneath it. Durable state hydration, local identity, native/device runtime
  validation, durable database persistence, and final UX remain open.

Next reviewer:
- Keep cancellation in the concrete product source when its persistence or
  network implementation supports it; do not use fixture or demo state as a
  production source.

---

### 2026-08-10 - Codex - App-Shell Route-Argument Handoff

Summary:
- Added an optional opaque `arguments` payload to mirrored
  `PeerDealAppNavigationEntry` values.
- Default app-home production navigation now forwards that payload through
  `RouteSettings.arguments`, enabling a product caller to launch the T41
  bootstrap-route adapter with a resolved invite while keeping session policy
  and validation in the destination route.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused mobile app-shell tests: passed, 74 tests.
- Focused desktop app-shell tests: passed, 74 tests.

Risks:
- Concrete product state hydration, local identity, native/device runtime
  validation, durable persistence, other-platform hosts, and final product UX
  remain open. This handoff only transports an opaque route payload.

Next reviewer:
- Use the new payload from the real product join/session flow once its source
  and local identity providers exist; do not use demo or fixture state.

---

### 2026-08-10 - Codex - Join-to-Production Session Handoff

Summary:
- Preserved only identity-safe `ResolvedInvite` values through the mounted join
  route for authoritative joined/rejoined outcomes.
- Added mirrored post-frame `JoinFlowReadyHandler` wiring through both app
  runtimes. Product callers can now push the T41 bootstrap route with the
  resolved invite; rejected, stale, malformed, and callback-failure paths do
  not trigger handoff.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/README.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused mobile join-flow/app-shell suites: passed, 92 tests.
- Focused desktop join-flow/app-shell suites: passed, 92 tests.

Risks:
- The callback only transports the validated invite. Concrete durable state
  hydration, local identity, native/device runtime validation, and final UX
  remain product or operator-owned.

Next reviewer:
- Supply the real product source and local identity to the existing bootstrap;
  use this callback only after join governance acceptance.

---

### 2026-08-10 - Codex - Windows Native Channel Teardown

Summary:
- Hardened the Windows secure-key and capture method-channel owners so their
  handlers are explicitly unregistered during destruction.
- This matches the existing app-storage and native-transport teardown pattern;
  generic channel payloads and package boundaries are unchanged.

Files changed:
- `apps/peerdeal_desktop/windows/runner/windows_secure_key_storage.cpp`
- `apps/peerdeal_desktop/windows/runner/windows_capture_protection.cpp`
- `docs/PRODUCTION_READINESS.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`

Tests run:
- Focused desktop receipt, secure-key loader, and capture coordinator tests:
  passed, 21 tests.
- `flutter build windows --debug --no-pub`: passed.
- Full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- `git diff --check`: passed.

Risks:
- Windows runtime/profile persistence and capture behavior, Android device and
  release-signing validation, and other-platform implementations remain open.

Next reviewer:
- Continue with the next codable gap in `docs/PRODUCTION_READINESS.md`.

---

### 2026-08-10 - Codex - Production Session Bootstrap Route Mounting

Summary:
- Added mirrored app-owned `AppHoldemProductionSessionBootstrapRoute` adapters.
- Product route maps can pass a real `ResolvedInvite` through route arguments,
  invoke the existing validated bootstrap, and mount its route without deriving
  state or local identity from demo data.
- Missing arguments, source/bootstrap failures, and route-path mismatches fail
  closed through the existing safe route fallback.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_bootstrap_route.dart`
- `apps/peerdeal_mobile/test/session/app_holdem_production_session_bootstrap_route_test.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_bootstrap_route.dart`
- `apps/peerdeal_desktop/test/session/app_holdem_production_session_bootstrap_route_test.dart`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused mobile bootstrap-route tests: passed, four tests.
- Focused desktop bootstrap-route tests: passed, four tests.
- Full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- Dart format and `git diff --check`: passed.

Risks:
- The concrete product session source, durable state hydration, local identity,
  Android device validation, runtime capture/key validation, release signing,
  and other-platform hosts remain open.

Next reviewer:
- Wire this adapter from the real product join/session flow once the product
  source and local identity providers exist; do not use demo or fixture data.

---

### 2026-08-10 - Codex - Android Secure-Key Teardown Lifecycle

Summary:
- Hardened the Android secure-key method-channel worker around Flutter engine
  teardown.
- Queued storage work now fails closed after handler closure, and late results
  on the main looper return unavailable payloads instead of native key material.
- The generic channel payload and package boundaries are unchanged.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- `docs/PRODUCTION_READINESS.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`

Tests run:
- Focused mobile secure-key/receipt and Android manifest tests: passed, 40
  tests.
- `flutter build apk --debug --no-pub`: passed.
- Full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- `git diff --check`: passed.

Risks:
- Android device persistence/capture behavior, release signing, and
  other-platform native hosts remain external readiness checks.

Next reviewer:
- Continue with the next documented production gap without inventing platform
  endpoint semantics.

---

### 2026-08-10 - Codex - Windows Native Transport Socket Lifecycle

Summary:
- Hardened the Windows native multicast transport host against concurrent
  socket access during Flutter method calls, receiver startup, and teardown.
- Shutdown now invalidates the shared socket before closing and joining the
  receive thread, and clears queued frames after the thread exits.
- The generic channel payload and package boundaries are unchanged.

Files changed:
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.h`
- `docs/PRODUCTION_READINESS.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`

Tests run:
- `flutter test --no-pub test/transport` in `apps/peerdeal_desktop`: passed,
  45 tests.
- `flutter build windows --debug --no-pub`: passed.
- Windows host smoke launch: stayed alive for five seconds and stopped
  cleanly.
- Full `analyze`, `boundary-check`, `source-text`, serialized `test`, and
  `dependency-audit` gates: passed; dependency audit reported 0 actionable
  upgrades and 11 newer versions remain blocked by the current toolchain.
- `git diff --check`: passed.

Risks:
- Windows profile/network reachability, Android device validation, runtime
  persistence/capture, release signing, and other-platform native hosts remain
  external readiness checks.

Next reviewer:
- Continue with the next documented production gap without inventing transport
  endpoint semantics.

---

### 2026-08-10 - Codex - Native Transport Method-Channel Deadline

Summary:
- Added a bounded five-second default deadline to the generic native transport
  method-channel bridge for capability, send, and receive operations.
- Added caller cancellation so app-owned table route replacement and disposal
  cancel in-flight default transport calls and their local deadline timers.
- Timeout and cancellation results are stable and fail closed; transport and
  routing policy remain in the app and network layers.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/transport/method_channel_native_transport_bridge.dart`
- `packages/peerdeal_native_bridges/test/method_channel_native_transport_bridge_test.dart`
- `packages/peerdeal_native_bridges/README.md`
- `docs/PRODUCTION_READINESS.md`, `docs/ai/API_CONTRACTS.md`,
  `docs/ai/ARCHITECTURE_MAP.md`
- `PROJECT_STATE.md`, `HANDOFF.md`, and `HANDOFF_QUEUE.md`

Tests run:
- Focused native transport method-channel suite: passed, 13 tests.
- Mobile and desktop full Flutter suites: passed.
- Final analyze, boundary-check, source-text, serialized test, dependency-audit,
  and diff-check gates: passed; dependency audit reported zero actionable
  upgrades.

Risks:
- Runtime device, firewall, cross-device reachability, and other-platform
  transport validation remain external readiness checks.

Next reviewer:
Run the full repository gates, then continue with the next actionable gap in
`docs/PRODUCTION_READINESS.md` without inventing transport endpoint semantics.

---

### 2026-08-10 - Codex - Android Native Transport Teardown Race

Summary:
- Hardened the Android native multicast transport host against teardown racing
  with receiver setup.
- Socket and multicast-lock resources are published only while the handler is
  live; partial setup resources are released on failure, and queued transport
  frames are cleared during close.
- The generic method-channel payload and package boundaries are unchanged.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `docs/PRODUCTION_READINESS.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`

Tests run:
- `rtk flutter build apk --debug --no-pub`: passed.

Risks:
- Android device/network reachability, firewall behavior, runtime persistence,
  release signing, and other-platform native hosts remain external readiness
  checks.

Next reviewer:
- Run the full repository gates, then continue with runtime Android/Windows
  validation or the next documented other-platform implementation gap.

---

### 2026-08-10 - Codex - Local-Network Method-Channel Deadline

Summary:
- Added a bounded five-second default deadline to generic local-network
  capability and discovery method-channel calls.
- Added stable fail-closed timeout and cancellation facts. Default app bootstrap
  loaders carry caller cancellation, and table routes cancel in-flight loaders
  during replacement or disposal.
- Kept discovery, endpoint, routing, and receipt policy outside the native
  bridge package.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/local_network/method_channel_local_network_bridge.dart`
- `packages/peerdeal_native_bridges/test/method_channel_local_network_bridge_test.dart`
- Mirrored mobile and desktop bootstrap loaders, table routes, and route tests
- `packages/peerdeal_native_bridges/README.md` and mirrored demo-slice READMEs
- `docs/PRODUCTION_READINESS.md`, `docs/ai/API_CONTRACTS.md`, and
  `docs/ai/ARCHITECTURE_MAP.md`
- `PROJECT_STATE.md`, `HANDOFF.md`, and `HANDOFF_QUEUE.md`

Tests run:
- Focused local-network method-channel suite: passed, 10 tests.
- Mirrored mobile and desktop bootstrap-loader/table-route suites: passed, 17
  tests each.
- Full analyzer, boundary-check, source-text, serialized test, and
  dependency-audit gates: passed; dependency audit reported zero actionable
  upgrades.

Risks:
- Real platform discovery, permission behavior, device/network reachability,
  and other-platform local-network implementations remain external readiness
  checks.

Next reviewer:
Continue with the next actionable production gap in
`docs/PRODUCTION_READINESS.md` after runtime Android/Windows validation; do not
invent local-network service or endpoint semantics.

---

### 2026-08-10 - Codex - Secure-Key Method-Channel Deadline

Summary:
- Added a bounded five-second default deadline to the generic secure-key
  method-channel bridge for load, save, and delete operations.
- Mirrored receipt routes now reject unavailable export artifacts before native
  key verification, avoiding unnecessary pending secure-storage calls.
- Timeout results are stable and fail closed; receipt semantics remain in the
  app-owned key-ring and artifact layers.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/secure_storage/method_channel_secure_key_storage_bridge.dart`
- `packages/peerdeal_native_bridges/test/method_channel_secure_key_storage_bridge_test.dart`
- `packages/peerdeal_native_bridges/README.md`
- Mirrored `apps/peerdeal_mobile/` and `apps/peerdeal_desktop/` receipt routes
  and focused screen tests
- `PROJECT_STATE.md`, `HANDOFF.md`, `HANDOFF_QUEUE.md`,
  `docs/PRODUCTION_READINESS.md`, `docs/ai/API_CONTRACTS.md`, and
  `docs/ai/ARCHITECTURE_MAP.md`

Tests run:
- Focused secure-key method-channel suite: passed, 12 tests.
- Mirrored mobile and desktop receipt-screen suites: passed, 12 tests each.
- Mobile and desktop full Flutter test suites: passed.
- Final analyze, boundary-check, source-text, serialized test, and diff-check
  gates: passed; dependency audit reported zero actionable upgrades.

Risks:
- Native key-store persistence, Android device behavior, release signing, and
  receipt runtime validation remain external readiness checks.

Next reviewer:
- Run the full repository gates and preserve the generic native/app boundary.

---

### 2026-08-10 - Codex - Native Transport Lifecycle Hardening

Summary:
- Hardened Android native transport executor submission and teardown so calls
  after close or rejected queued work resolve with bounded fail-closed payloads.
- Hardened Windows native transport initialization cleanup for socket,
  multicast membership, TTL, and Winsock failures.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `PROJECT_STATE.md`, `HANDOFF.md`, `HANDOFF_QUEUE.md`,
  `docs/PRODUCTION_READINESS.md`, and `docs/ai/ARCHITECTURE_MAP.md`

Tests run:
- Focused native transport bridge suite: passed, 7 tests.
- `flutter build windows --debug --no-pub`: passed.
- `flutter build apk --debug --no-pub`: passed.

Risks:
- Android device behavior, Windows profile behavior, firewall/multicast
  reachability, and product endpoint/session provisioning remain open.

Next reviewer:
- Run the existing host builds and validate the transport across real devices
  or network profiles when available; keep the generic channel boundary.

---

### 2026-08-10 - Codex - Production Hold'em Surface and Resumable Publication

Summary:
- Added mirrored `AppHoldemProductionTableSurface` owners that render bounded
  runtime state and expose local-seat actions only during transport-backed
  betting turns.
- Added `withDefaultSurface(...)` route-registration factories.
- Added publisher event offsets so partial sends resume from the first unsent
  event instead of replaying delivered frames.

Files changed:
- Mirrored app production surface, route registration, publisher, and focused
  runtime/route tests.
- `PROJECT_STATE.md`, `HANDOFF.md`, `HANDOFF_QUEUE.md`,
  `docs/PRODUCTION_READINESS.md`, `docs/ARCHITECTURE.md`, and `docs/ai/` docs.

Tests run:
- Mobile and desktop focused route suites: passed, 7 tests each.
- Mobile and desktop runtime/publisher suites: passed, 9 tests each.
- Mobile and desktop static analysis: passed.
- Full `melos run analyze`, `boundary-check`, `source-text`, serialized
  `test`, and `dependency-audit` gates: passed.
- Dependency audit: 0 actionable upgrades; 11 newer versions remain blocked by
  the current Dart/Flutter toolchain.

Risks:
- Product session/state provisioning, native peer transport, durable database
  persistence, device validation, and final product UX validation remain open.

Next reviewer:
- Supply the default registration from the real validated product runtime and
  local identity; keep native transport behind the existing generic contract.

---

### 2026-08-10 - Codex - Production Hold'em Session Composition

Summary:
- Added mirrored `AppHoldemProductionSessionFactory` owners that compose the
  existing table-session runtime, Hold'em runtime, and default production
  surface from injected canonical table/hand state, event cursor,
  close-retention adapter, and local/remote peer identity.
- Added fail-closed checks for route metadata, peer identity reuse, local seat,
  transport polling bounds, and runtime cursor/session composition.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_holdem_production_session_factory.dart`
- `apps/peerdeal_mobile/test/session/app_holdem_production_session_factory_test.dart`
- `apps/peerdeal_desktop/lib/session/app_holdem_production_session_factory.dart`
- `apps/peerdeal_desktop/test/session/app_holdem_production_session_factory_test.dart`
- Readiness, architecture, README, project state, queue, and handoff records.

Tests run:
- Focused mobile factory tests: passed, 2 tests.
- Focused desktop factory tests: passed, 2 tests.
- Full `melos run analyze`, `boundary-check`, `source-text`, serialized `test`,
  and `dependency-audit` gates: passed.
- Dependency audit: 0 actionable upgrades; 11 newer versions remain blocked by
  the current Dart/Flutter toolchain.
- `git diff --check`: passed.

Risks:
- The factory does not create product session/state truth; a real product
  source, device/network validation, and final UX validation remain open.

Next reviewer:
- Supply the factory inputs from the actual validated product session source;
  preserve the generic native transport and package boundaries.

---

### 2026-08-10 - Codex - Production Session Source Handoff

Summary:
- Added mirrored `AppHoldemProductionSessionSource` and
  `AppHoldemProductionSessionBootstrap` contracts.
- Successful first-join and rejoin outcomes now carry `ResolvedInvite` for
  product session handoff.
- Bootstrap validation rejects invite/table/cursor scope drift before route or
  native transport composition and never derives identity from demo/Game File
  data.

Files changed:
- Mirrored app session bootstrap source and focused tests.
- Mirrored join outcome/orchestrator files and focused tests.
- Readiness, queue, project-state, architecture, API, and AI handoff records.

Tests run:
- Focused mobile bootstrap and join orchestrator tests: passed, 14 tests.
- Focused desktop bootstrap and join orchestrator tests: passed, 14 tests.

Open integration work:
- A concrete product source still owns durable state hydration, local identity,
  and native/device/network provisioning. No demo or compiled Game File fallback
  was added.

---

### 2026-08-10 - Codex - Native Android and Windows Peer Transport

Summary:
- Added bounded UDP multicast host implementations behind the existing generic
  `peerdeal/native_bridges/transport` channel.
- Android and Windows hosts validate frame fields, encode the same host-private
  envelope, filter receive queues by session/recipient, and close socket state
  with the Flutter host lifecycle.
- Repaired the malformed pinned Android NDK after verifying the exact cache and
  compiled both native hosts through their new transport handlers.

Files changed:
- Android `NativeTransportHandler` and `MainActivity` registration.
- Windows `WindowsNativeTransport`, `FlutterWindow` registration, CMake, and
  Winsock linkage.
- Existing Android `SecureKeyStorageHandler` nullability fixes exposed by the
  first real Kotlin compilation.
- Architecture, readiness, AI context, package README, project state, queue,
  and handoff records.

Tests run:
- Windows `flutter build windows --debug --no-pub`: passed.
- Windows host smoke launch: stayed alive for five seconds and was stopped
  cleanly.
- Android `flutter build apk --debug --no-pub`: passed.
- `adb devices`: no Android device or emulator attached; device persistence,
  capture, and cross-device transport behavior remain unverified.
- Full `melos run analyze`, `boundary-check`, `source-text`, serialized
  `test`, and `dependency-audit` gates: passed; dependency audit reported
  0 actionable upgrades and 11 toolchain-blocked newer versions.
- `git diff --check`: passed.

Risks:
- Multicast/firewall/device reachability, endpoint provisioning, other-platform
  transport, durable database persistence, and product session/state wiring
  remain open. Host socket availability is not network-connectivity proof.

Next reviewer:
- Validate transport across real Android/Windows devices and supply the native
  source/product session identity from the actual join flow.

---

### 2026-08-10 - Codex - Typed Hold'em Production Route Registration

Summary:
- Added mirrored `AppHoldemProductionRouteRegistration` owners that bind the
  validated runtime, peer identity, surface builder, and optional native
  transport factory into one typed app-shell registration.
- Both app shells now merge the registration into validated production routes,
  auto-register navigation, and require native readiness before mounting.

Files changed:
- Mirrored app `main.dart`, registration files, and focused route tests.
- `PROJECT_STATE.md`, `HANDOFF.md`, `HANDOFF_QUEUE.md`,
  `docs/PRODUCTION_READINESS.md`, `docs/ARCHITECTURE.md`, and `docs/ai/` docs.

Tests run:
- Focused mobile and desktop route-registration suites: passed, 6 tests each.

Risks:
- Product session/state provisioning, final surface/UI, live native peer
  transport, durable database persistence, and device validation remain open.

Next reviewer:
- Supply the registration from the real product session/state source and keep
  native transport implementation behind the existing generic contract.

---

### 2026-08-10 - Codex - App Hold'em Route Orchestration

Summary:
- Added mirrored `AppHoldemTableSessionRoute` composition around the validated
  Hold'em runtime, transport provisioner, bounded source lifecycle, and
  accepted-event surface refresh.
- Added `AppHoldemProjectionTransportPublisher` for canonical outbound event
  frames with explicit complete, rejected, and partial-send results.

Files changed:
- `apps/peerdeal_mobile/` and `apps/peerdeal_desktop/` session and transport
  orchestration plus focused tests.
- `PROJECT_STATE.md`, `HANDOFF.md`, `HANDOFF_QUEUE.md`,
  `docs/PRODUCTION_READINESS.md`, and `docs/ai/` context docs.

Tests run:
- Focused mobile and desktop Hold'em runtime/publisher tests: passed.
- Focused mobile and desktop route tests: passed.

Risks:
- Native live peer transport, platform source provisioning, actual product
  route/state wiring, durable database persistence, and device validation remain
  open. Partial outbound sends are reported for retry; variant rules are not
  replayed by the publisher.

Next reviewer:
- Run the full repository gates, then connect the route to the real product
  route map and validated session-state source without moving policy into
  package boundaries.

---

### 2026-08-10 - Codex - Remote Hold'em Event Reconstruction

Summary:
- Added `HoldemEventCursor.accept` with exact scope, sequence, hash-chain,
  catalog, identity, and canonical event-hash validation.
- Added public `HoldemEventReducer` in `peerdeal_variants` for adapter-produced
  action/street events and public showdown/settlement lifecycle events.
- Added atomic `applyRemoteEvent` to both app Hold'em runtimes and optional
  `holdemRuntime` wiring through mirrored transport handlers/provisioners.
- Added action board-deal breadcrumbs needed for deterministic street
  reconstruction. Existing settlement payload contracts remain unchanged;
  inbound lifecycle phases are derived from the validated event order. Private
  showdown cards remain local.

Files changed:
- `packages/peerdeal_variants/lib/src/holdem/holdem_core_projection_adapter.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_event_reducer.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_*_event_builder.dart`
- Mirrored mobile/desktop Hold'em runtime, transport boundary, and tests
- `HANDOFF_QUEUE.md`, `HANDOFF.md`, `PROJECT_STATE.md`,
  `docs/ARCHITECTURE.md`, `docs/PRODUCTION_READINESS.md`, and `docs/ai/*`

Tests run:
- Focused `peerdeal_variants` reducer and adapter tests: passed.
- Focused mobile and desktop Hold'em runtime tests: passed.
- Focused mobile and desktop transport-handler tests: passed.
- Full `melos run analyze`, `boundary-check`, `source-text`, and serialized
  `test` gates: passed.
- `melos run dependency-audit`: passed with 0 actionable upgrades; 10 newer
  versions remain toolchain-blocked.
- `git diff --check`: passed.

Risks:
- Native live transport/platform source provisioning, Android/Windows runtime
  validation, production persistence, and non-demo route orchestration remain
  open. Public events do not contain private hole cards by design.

Next reviewer:
- Validate external native/runtime prerequisites when available; the remaining
  software gaps are listed in the readiness documents.

---

### 2026-08-10 - Codex - App Hold'em Session Adoption

Summary:
- Added mirrored app-owned `AppHoldemTableSessionRuntime` owners in both app
  shells and added `peerdeal_variants` as an explicit app dependency.
- Local start/action/showdown/settlement projections now commit through the
  existing app session runtime. New atomic non-retention batch preflight keeps
  core state, Hold'em state, and cursor advancement synchronized.

Validation:
- Mobile and desktop focused app-session suites passed.
- Existing app runtime retention tests passed.

Remaining:
- Production non-demo routes still need to provide validated Hold'em hand state
  and event sinks. Generic inbound transport does not yet reconstruct variant
  state because no variant event-reducer contract exists.

---

### 2026-08-10 - Codex - Hold'em Core Projection Bridge

Summary:
- Added `HoldemEventCursor` and `HoldemCoreProjectionAdapter` to
  `packages/peerdeal_variants`.
- The adapter runs existing Hold'em action/street, showdown, and settlement
  coordinators, emits catalog-approved protocol envelopes, and applies them
  through `peerdeal_core.CoreReducer` as a transactional batch.
- Core remains variant-agnostic. App/session callers can adopt the adapter
  without importing package internals or constructing ad hoc event shapes.

Validation:
- Focused adapter suite passed, including action projection, automatic
  showdown-start emission, successful settlement, invalid-action rejection, and
  rollback when core rejects a valid variant transition.
- No native or app code changed in this slice.

Remaining:
- Production app/session routes still need to construct and retain a
  `HoldemHandState` and invoke this adapter for live table actions.

---

### 2026-08-10 - Codex - Core Protocol Envelope Migration

Summary:
Closed the documented core migration gap. Removed the unused starter local
`CoreCommand`/`CoreEvent` models and duplicate reducer, action-validator,
orchestrator, and application-result contracts and tests. The public
`peerdeal_core` barrel now exposes only the protocol-native command/event path,
keeping deterministic state projection and invariant guards as the sole core
truth.

Files changed:
- `packages/peerdeal_core/lib/peerdeal_core.dart`
- `packages/peerdeal_core/lib/src/contracts/action_validator.dart`
- `packages/peerdeal_core/lib/src/contracts/core_reducer.dart`
- `packages/peerdeal_core/lib/src/contracts/table_orchestrator.dart`
- `packages/peerdeal_core/lib/src/models/command_application_result.dart`
- `packages/peerdeal_core/lib/src/models/command_validation_result.dart`
- `packages/peerdeal_core/lib/src/models/core_command.dart`
- `packages/peerdeal_core/lib/src/models/core_event.dart`
- `packages/peerdeal_core/lib/src/models/reducer_context.dart`
- `packages/peerdeal_core/lib/src/reducer/default_core_reducer.dart`
- `packages/peerdeal_core/lib/src/validation/basic_action_validator.dart`
- `packages/peerdeal_core/test/basic_action_validator_test.dart`
- `packages/peerdeal_core/test/default_core_reducer_test.dart`
- `packages/peerdeal_core/README.md`
- `HANDOFF_QUEUE.md`
- `HANDOFF.md`
- `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`

Tests run:
- Focused protocol-native `peerdeal_core` suite: passed.

Risks:
This removes unused scaffold exports from the private, non-publishable core
package. No app or package production source referenced the removed symbols.
The Hold'em lifecycle-to-core event integration and native runtime gaps remain
open.

Next reviewer:
Run the full repository gates, then continue with the documented Hold'em/core
integration work.

---

### 2026-08-10 - Codex - Core Command Catalog and Identity Validation

Summary:
Closed the documented legacy core command-validation gap. `CoreCommandValidator`
now checks command type/version/protocol compatibility through the shared
`ProtocolCatalog`, rejects unsupported command artifacts and protocol versions,
and rejects padded or ASCII control-character command and scope identities.
Existing blank-field error ordering and accepted fixture behavior remain intact.

Files changed:
- `packages/peerdeal_core/lib/src/validation/core_command_validator.dart`
- `packages/peerdeal_core/test/peerdeal_core_test.dart`
- `packages/peerdeal_core/README.md`
- `HANDOFF_QUEUE.md`
- `HANDOFF.md`
- `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`

Tests run:
- Focused `peerdeal_core` test suite: passed.

Risks:
The validator hardens the existing protocol-native command seam; it does not
create a command dispatcher or claim that live transport, discovery, database
persistence, native runtime validation, or production UI is complete.

Next reviewer:
Run the full repository gates, then continue with the next actionable gap in
`docs/PRODUCTION_READINESS.md` without inventing transport endpoint semantics.

---

### 2026-08-10 - Codex - Android Secure-Key Envelope Bound

Summary:
Fixed a concrete Android host bound defect. The secure-key handler previously
checked `JSONObject.length()` against `MAX_ENCODED_BYTES`, which measures the
number of JSON fields rather than the persisted envelope size. Reads and writes
now enforce the actual UTF-8 encoded byte count. The release manifest also
declares `INTERNET` for the existing native-network boundary.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- `apps/peerdeal_mobile/android/app/src/main/AndroidManifest.xml`
- `apps/peerdeal_mobile/test/native/android_manifest_contract_test.dart`
- `apps/peerdeal_mobile/README.md`
- `HANDOFF_QUEUE.md`
- `HANDOFF.md`
- `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`

Tests run:
- Android manifest contract test: passed.
- `melos run analyze`: passed.
- `melos run boundary-check`: passed.
- `melos run source-text`: passed.
- `melos run test`: passed.
- `melos run dependency-audit`: passed; 0 actionable upgrades.
- `flutter build windows --no-pub`: passed.
- `flutter build apk --no-pub`: not completed; Gradle stopped before source
  compilation because the configured NDK lacks `source.properties`.
- `git diff --check`: passed before documentation edits; rerun before commit.

Risks:
The Android source and device runtime remain unverified until the local NDK is
repaired. The manifest permission does not implement local-network discovery or
live peer transport.

Next reviewer:
Review the staged T21 patch, then preserve the existing generic native-network
contract until endpoint/open/listener semantics are explicitly defined.

---

### 2026-08-10 - Codex - Native Bootstrap Endpoint Projection

Summary:
Closed the app-owned discovery metadata loss. Mirrored mobile and desktop
bootstrap loaders now parse the documented `peer@host[:port]` shape, validate
bounded host/port syntax, preserve bare peer IDs, and project safe metadata onto
existing `BootstrapCandidate` fields. Malformed and sensitive locations are
dropped before network routing.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- mirrored `native_bootstrap_candidate_loader_test.dart` files
- `HANDOFF_QUEUE.md`
- `HANDOFF.md`
- `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`

Tests run:
- Mobile focused bootstrap endpoint suite: passed, 12 tests.
- Desktop focused bootstrap endpoint suite: passed, 12 tests.

Risks:
This retains endpoint metadata for future platform transport provisioning; it
does not implement live native peer transport, mDNS/service discovery, or
runtime device validation.

Next reviewer:
Verify the full repository gates and preserve the generic native transport
contract until endpoint/open/listener semantics are explicitly added.

---

### 2026-08-10 - Codex - Production Entrypoint Native Readiness

Summary:
Both production app entrypoints now install the existing app-owned
`AppNativeReadinessLoader.methodChannel()` boundary. Generic host capability
failures reach the default home as scrubbed unavailable readiness instead of
silently leaving entrypoint readiness inactive.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- mirrored production-entrypoint focused tests
- `HANDOFF_QUEUE.md`
- `HANDOFF.md`
- `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`

Tests run:
- Mobile production-entrypoint focused test: passed.
- Desktop production-entrypoint focused test: passed.
- Full `melos run analyze`, `boundary-check`, `source-text`, `test`, and
  `dependency-audit`: passed; dependency audit reports 0 actionable upgrades.
- `git diff --check`: passed.

Risks:
Native transport, other-platform host implementations, runtime/device validation,
production database persistence, and Android NDK repair remain open.

Next reviewer:
Verify full repository gates and confirm the host-specific readiness contracts
remain unchanged.

---

### 2026-08-10 - Codex - Native App-Support Recovery Persistence

Summary:
Added a generic app-support directory method-channel contract and wired both app
shells to use it as the default recovery-root source after the explicit
`PEERDEAL_RECOVERY_ROOT` override. Android returns private no-backup app storage;
Windows returns `LocalAppData`. Recovery and retention policy remain app-owned,
and malformed, unavailable, or failed native results return no default factory.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/app_storage/`
- `packages/peerdeal_native_bridges/fixtures/app_storage_directory_bridge_contract.json`
- `packages/peerdeal_native_bridges/test/method_channel_app_storage_directory_bridge_test.dart`
- Android app-storage handler and `MainActivity` registration
- Windows app-storage host, Flutter-window ownership, and CMake wiring
- Both app-shell recovery factories and entrypoints
- readiness and handoff records

Tests run:
- Native bridge focused Flutter suite: passed, 49 tests.
- Mobile recovery factory focused suite: passed, 11 tests.
- Desktop recovery factory focused suite: passed, 12 tests.
- `melos run analyze`, `boundary-check`, `source-text`, `test`, and
  `dependency-audit`: passed; dependency audit reports 0 actionable upgrades.
- `git diff --check`: passed.
- `flutter build windows --debug --no-pub`: passed.
- Android `app:compileDebugKotlin` was attempted twice and stopped during
  Gradle configuration because the configured NDK lacks `source.properties`;
  no Android host compile or APK result is claimed.

Risks:
- This provides app-private JSON recovery persistence roots on Android and
  Windows; it does not provide a production database, other-platform storage,
  live peer transport, or runtime/device validation. Android host validation
  also needs a repaired NDK installation.

Next reviewer:
- Commit and push after reviewing the staged file list. Android APK/runtime
  validation, release signing, device/profile validation, and NDK repair remain
  external.

---

### 2026-08-10 - Codex - App Transport Provisioning

Summary:
Added mirrored `AppTableSessionTransportProvisioner` factories. App callers can
now compose an existing table-session runtime, its protocol handler, a validated
native transport session, and a route-ready source through one fail-closed
boundary. Invalid peer identities and native capability failures become bounded
unavailable results without exposing raw diagnostics.

Files changed:
- `apps/peerdeal_mobile/lib/transport/app_table_session_transport_provisioner.dart`
- `apps/peerdeal_mobile/test/transport/app_table_session_transport_provisioner_test.dart`
- `apps/peerdeal_desktop/lib/transport/app_table_session_transport_provisioner.dart`
- `apps/peerdeal_desktop/test/transport/app_table_session_transport_provisioner_test.dart`
- readiness, handoff, project-state, README, and AI context records

Tests run:
- Mobile and desktop provisioner plus native-session-factory focused tests
- Mobile and desktop app analysis

Risks:
- A real platform peer transport and platform source provisioning are still
  required before the provisioner can drive production sessions.

Next reviewer:
Provide a platform-backed native transport implementation and pass the
provisioned source into the production session route without moving app policy
into `peerdeal_native_bridges`.

---

### 2026-08-10 - Codex - Route Transport Source Mounting

Summary:
Added mirrored `AppTableSessionTransportSourceMount` lifecycle owners and
optional source injection through both app runtime objects into
`DemoTableRoute`. A mounted route starts its injected source, disposes the old
source on replacement, and disposes the active source on route exit.

Files changed:
- `apps/peerdeal_mobile/lib/transport/app_table_session_transport_source_mount.dart`
- `apps/peerdeal_mobile/test/transport/app_table_session_transport_source_mount_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_table_screen_test.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_desktop/lib/transport/app_table_session_transport_source_mount.dart`
- `apps/peerdeal_desktop/test/transport/app_table_session_transport_source_mount_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_table_screen_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- readiness and handoff records

Tests run:
- Mobile and desktop mount lifecycle focused tests
- Mobile and desktop table-route focused tests
- Mobile and desktop app analysis
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit` (0 actionable upgrades)
- `git diff --check`

Risks:
- Production callers still need a loaded native session, handler, and actual
  platform peer transport before injecting a source.

Next reviewer:
Provision the source from a real production session bootstrap and keep the
generic native bridge free of app route policy.

---

### 2026-08-10 - Codex - App Transport Source Lifecycle

Summary:
Added mirrored app-owned `AppTableSessionTransportSource` controllers and
`NativeTransportSession.createSource` composition. Loaded native sessions can
now poll through their already validated drains with exact scope, bounded
intervals, serialized in-flight work, explicit lifecycle state, and scrubbed
bounded warnings.

Files changed:
- `apps/peerdeal_mobile/lib/transport/app_table_session_transport_source.dart`
- `apps/peerdeal_mobile/test/transport/app_table_session_transport_source_test.dart`
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_desktop/lib/transport/app_table_session_transport_source.dart`
- `apps/peerdeal_desktop/test/transport/app_table_session_transport_source_test.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_session_factory_test.dart`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Mobile and desktop source lifecycle focused tests
- Mobile and desktop native session factory focused tests
- Mobile and desktop app analysis
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit` (0 actionable upgrades)
- `git diff --check`

Risks:
- Native peer transport implementation and production source provisioning are
  still open; the mount only owns an injected source's app route lifecycle.

Next reviewer:
Mount a source from a real production session route once the platform peer
transport implementation supplies an actual receive source.

---

### 2026-08-10 - Codex - Protocol Event Transport Ingress

Summary:
Added the protocol-owned bounded `EventEnvelopeCodec` for canonical JSON wire
bytes and mirrored app `AppTableSessionTransportHandler`s. The handlers run
behind `peerdeal_network` validating receivers, enforce frame/event session
identity agreement, delegate to `AppTableSessionRuntime`, and fail the receive
when projection or retention rejects the event.

Files changed:
- `packages/peerdeal_protocol/lib/src/serialization/event_envelope_codec.dart`
- `packages/peerdeal_protocol/lib/peerdeal_protocol.dart`
- `packages/peerdeal_protocol/test/event_envelope_codec_test.dart`
- `apps/peerdeal_mobile/lib/transport/app_table_session_transport_handler.dart`
- `apps/peerdeal_mobile/test/transport/app_table_session_transport_handler_test.dart`
- `apps/peerdeal_desktop/lib/transport/app_table_session_transport_handler.dart`
- `apps/peerdeal_desktop/test/transport/app_table_session_transport_handler_test.dart`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/event_envelope_codec_test.dart` in `packages/peerdeal_protocol`
- `flutter test --no-pub test/transport/app_table_session_transport_handler_test.dart`
  in both app shells
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit` (0 actionable upgrades)
- `git diff --check`

Risks:
- Native peer transport implementation, source scheduling, platform runtime
  validation, durable database/platform persistence, and final production UI
  remain open readiness work.

Next reviewer:
Compose the handler with a real native transport source when that platform
implementation exists; keep frame routing in app orchestration and generic
transport facts in the native bridge package.

---

### 2026-08-09 - Codex - App Table Session Runtime

Summary:
Added mirrored `AppTableSessionRuntime` owners in the mobile and desktop app
shells. Each runtime pins table/session/protocol identity, delegates ordered
`EventEnvelope` projection to `peerdeal_core.CoreReducer`, preserves state on
rejected events, and commits `SessionClosed` only after the existing app
retention adapter succeeds. Failed retention leaves the runtime in its prior
state and exposes scrub-safe reason codes/warnings.

Files changed:
- `apps/peerdeal_mobile/lib/session/app_table_session_runtime.dart`
- `apps/peerdeal_mobile/test/session/app_table_session_runtime_test.dart`
- `apps/peerdeal_mobile/pubspec.yaml`
- `apps/peerdeal_desktop/lib/session/app_table_session_runtime.dart`
- `apps/peerdeal_desktop/test/session/app_table_session_runtime_test.dart`
- `apps/peerdeal_desktop/pubspec.yaml`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/session/app_table_session_runtime_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test/session/app_table_session_runtime_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- Live transport/event-source mounting, durable database/platform persistence,
  Android/Windows runtime validation, other-platform native implementations,
  and final production UI remain open readiness work.

Next reviewer:
Mount the runtime behind a real validated transport/event source once the
platform transport implementation exists; keep protocol serialization outside
the app runtime and retain `peerdeal_core` as the state authority.

---

### 2026-08-09 - Codex - Windows Desktop Secure-Key Host

Summary:
Added the generated Windows host for `peerdeal_desktop` and registered the
existing generic secure-key method channel. The host validates key records,
stores a bounded versioned binary envelope in Windows Credential Manager under
a namespace-derived target, and returns only the locked snapshot/mutation
payloads. Receipt semantics remain in app and receipt packages.

Files changed:
- `apps/peerdeal_desktop/windows/`
- `apps/peerdeal_desktop/.gitignore`
- `apps/peerdeal_desktop/.metadata`
- `apps/peerdeal_desktop/README.md`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `DECISIONS.log`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter build windows --debug --no-pub`: passed.
- `flutter test --no-pub` in `apps/peerdeal_desktop`: passed.
- Windows host smoke launch: stayed alive for five seconds and stopped cleanly.
- Repository source-text and boundary checks: passed.
- `melos run analyze`, `melos run test`, and `melos run dependency-audit`:
  passed; dependency audit reports zero actionable upgrades.

Risks:
- Credential Manager persistence was compile-verified but not exercised by a
  packaged runtime receipt provisioning test in this environment.
- Android real-device key persistence, signing, capture, discovery, transport,
  durable platform persistence, and other platform hosts remain open.

Next reviewer:
Run a Windows profile runtime test through the existing receipt key-ring
provisioning and verification path, then validate Android persistence when the
pinned NDK/device environment is available.

---

### 2026-08-09 - Codex - Android and Windows Capture Enforcement

Summary:
Added the generic capture `setBlocking` action and mirrored app coordinator
serialization for apply/release. Android applies `FLAG_SECURE`; Windows applies
`SetWindowDisplayAffinity`. Sensitive receipt routes release native blocking on
disposal, and failed or unconfirmed actions downgrade to visual obscuring with
scrubbed warnings.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/capture_protection/`
- `packages/peerdeal_native_bridges/fixtures/capture_protection_bridge_contract.json`
- `packages/peerdeal_native_bridges/test/`
- `apps/peerdeal_mobile/lib/safe_surface/capture_surface_coordinator.dart`
- `apps/peerdeal_mobile/lib/demo_slice/controllers/demo_receipt_surface_presenter.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/`
- `apps/peerdeal_desktop/lib/safe_surface/capture_surface_coordinator.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/demo_receipt_surface_presenter.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_desktop/windows/runner/windows_capture_protection.*`
- `apps/peerdeal_desktop/windows/runner/CMakeLists.txt`
- `apps/peerdeal_desktop/windows/runner/flutter_window.*`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `DECISIONS.log`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused native bridge tests: passed.
- Mirrored mobile and desktop capture coordinator tests: passed.
- `flutter build windows --debug --no-pub`: passed.
- Full repository gates passed: analyze, boundary-check, source-text,
  dependency-audit, test, and `git diff --check`.
- Windows host smoke launch: stayed alive for five seconds and stopped cleanly.

Risks:
- Android Kotlin/APK and real-device capture behavior remain unverified because
  both NDK `28.2.13676358` installation attempts exhausted local disk capacity.
- Windows capture action runtime was compile-verified but not directly invoked
  against a packaged profile. Other-platform capture, discovery, transport, and
  durable platform persistence remain open.

Next reviewer:
Perform Android device and Windows profile runtime checks for key persistence
and capture enforcement.

---

### 2026-08-09 - Codex - Mobile Android Secure-Key Host

Summary:
Added the generated Android host for `peerdeal_mobile` and registered the
existing generic secure-key method channel. The host validates generic records,
encrypts them with a namespace-bound AES-GCM key held by Android Keystore, and
uses durable preference commits. Receipt semantics remain in the app and
receipt packages. Release signing no longer falls back to debug keys.

Files changed:
- `apps/peerdeal_mobile/android/`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `DECISIONS.log`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter doctor -v`: passed with all Android licenses accepted.
- Android debug APK build: not completed because the local NDK package could
  not be installed with the available disk space.
- Dart package gates remain to be rerun after this host slice.

Risks:
- Android source compilation and real-device Keystore persistence are not yet
  verified. The remaining external environment issue is disk capacity, not a
  known source error.
- Other-platform secure storage, capture, discovery, transport, and durable
  platform persistence remain open.

Next reviewer:
Free enough local disk for the pinned Android NDK, run the APK build and an
Android-device persistence test, then run the full repository gate set.

---

### 2026-08-09 - Codex - Melos 8.2.2 Dependency Baseline

Summary:
Upgraded the workspace and GitHub Actions Melos baseline from 7.8.1 to 8.2.2,
refreshed the lockfile, and raised the compatible `mustache_template` lock to
2.0.5. The dependency audit now reports zero actionable upgrades.

Files changed:
- `.github/workflows/ci.yml`
- `pubspec.yaml`
- `pubspec.lock`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `DECISIONS.log`
- `docs/DEPENDENCY_POLICY.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart run melos run dependency-audit`
- `dart run melos run analyze`
- `dart run melos run test`

Risks:
- `meta` and `test` remain newer on pub.dev but are not resolvable under the
  current Flutter/Dart toolchain.
- Native platform implementations, durable platform persistence, and final
  production UI validation remain separate readiness gaps.

Next reviewer:
Codex should continue with platform-native work only after host-platform
projects are present, or the next codeable app/package hardening slice.

---

### 2026-06-09 - Codex - Validate Native Readiness Transport Payload Limits

Summary:
Hardened mobile and desktop `AppNativeReadinessLoader` transport readiness so
native transport is not reported ready when platform capability exceeds the
app-owned payload limit, and invalid app readiness limits fail before native
transport capability lookup.

Files changed:
- `apps/peerdeal_mobile/lib/native_readiness/app_native_readiness_loader.dart`
- `apps/peerdeal_mobile/test/native_readiness/app_native_readiness_loader_test.dart`
- `apps/peerdeal_desktop/lib/native_readiness/app_native_readiness_loader.dart`
- `apps/peerdeal_desktop/test/native_readiness/app_native_readiness_loader_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/native_readiness/app_native_readiness_loader_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test/native_readiness/app_native_readiness_loader_test.dart` in `apps/peerdeal_desktop`

Risks:
- Live platform transport implementation remains pending; this aligns
  readiness advertising with the already locked app transport session limits.

Next reviewer:
Codex should continue with the next codeable app-boundary or package-hardening
gap from `docs/PRODUCTION_READINESS.md`, or platform native work once platform
folders are added.

---

### 2026-06-09 - Codex - Validate Native Readiness Secure-Key Namespace

Summary:
Hardened mobile and desktop `AppNativeReadinessLoader` secure-key checks so
padded, control-character-bearing, or delimiter-bearing namespaces fail closed
before app readiness aggregation calls native secure storage.

Files changed:
- `apps/peerdeal_mobile/lib/native_readiness/app_native_readiness_loader.dart`
- `apps/peerdeal_mobile/test/native_readiness/app_native_readiness_loader_test.dart`
- `apps/peerdeal_desktop/lib/native_readiness/app_native_readiness_loader.dart`
- `apps/peerdeal_desktop/test/native_readiness/app_native_readiness_loader_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/native_readiness/app_native_readiness_loader_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test/native_readiness/app_native_readiness_loader_test.dart` in `apps/peerdeal_desktop`

Risks:
- Platform-native secure storage implementation remains pending; this locks
  the app readiness input gate before that implementation is attached.

Next reviewer:
Codex should continue with the next codeable app-boundary or package-hardening
gap from `docs/PRODUCTION_READINESS.md`, or platform native work once platform
folders are added.

---

### 2026-06-09 - Codex - Validate Transfer And Fallback Peer IDs

Summary:
Hardened `peerdeal_network` primary-peer transfer and relay fallback planning
so malformed or reserved peer identities cannot become actionable transfer or
transition plans.

Files changed:
- `packages/peerdeal_network/lib/src/services/default_transfer_policy.dart`
- `packages/peerdeal_network/lib/src/services/basic_relay_fallback_service.dart`
- `packages/peerdeal_network/test/default_transfer_policy_test.dart`
- `packages/peerdeal_network/test/basic_relay_fallback_service_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/default_transfer_policy_test.dart test/basic_relay_fallback_service_test.dart`

Risks:
- This locks deterministic package-level plan gates only; real native
  discovery, live transport, platform persistence, and final production UI
  remain separate readiness gaps.

Next reviewer:
Codex should continue with the next codeable network/sync/app-boundary gap from
`docs/PRODUCTION_READINESS.md`, or platform native work once platform folders
are added.

---

### 2026-06-09 - Codex - Validate Primary Peer Election IDs

Summary:
Hardened `peerdeal_network` primary-peer election so malformed peer metric
identities are dropped and malformed current-primary overrides are ignored
before scoring, confidence classification, transfer decisions, or fail-closed
fallback decisions.

Files changed:
- `packages/peerdeal_network/lib/src/services/default_primary_peer_election_service.dart`
- `packages/peerdeal_network/test/default_primary_peer_election_service_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/default_primary_peer_election_service_test.dart`
- `dart test`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks package-level election identity filtering only; real native
  discovery, live transport, platform persistence, and final production UI
  remain separate readiness gaps.

Next reviewer:
Codex should continue with the next codeable network/sync/app-boundary gap from
`docs/PRODUCTION_READINESS.md`, or platform native work once platform folders
are added.

---

### 2026-06-09 - Codex - Validate Session Path Peer IDs

Summary:
Hardened `peerdeal_network` session path selection so malformed reachable
candidate peer ids and malformed elected-primary overrides cannot become
returned path descriptors. The selector now falls back to valid candidates or
the unresolved state.

Files changed:
- `packages/peerdeal_network/lib/src/services/basic_session_path_selector.dart`
- `packages/peerdeal_network/test/basic_session_path_selector_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/basic_session_path_selector_test.dart`
- `dart test`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks package-level path descriptor identity filtering only; real native
  discovery, live transport, platform persistence, and final production UI
  remain separate readiness gaps.

Next reviewer:
Codex should continue with the next codeable network/sync/app-boundary gap from
`docs/PRODUCTION_READINESS.md`, or platform native work once platform folders
are added.

---

### 2026-06-09 - Codex - Validate Bootstrap Peer IDs

Summary:
Hardened `peerdeal_network` bootstrap candidate resolution so malformed or
duplicate peer ids are dropped before candidate route class and priority are
assigned. This keeps raw discovery output from promoting blank, padded,
control-character-bearing, or repeated peer identities into path selection.

Files changed:
- `packages/peerdeal_network/lib/src/services/basic_bootstrap_candidate_provider.dart`
- `packages/peerdeal_network/test/basic_bootstrap_candidate_provider_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/basic_bootstrap_candidate_provider_test.dart`
- `dart test`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks package-level candidate identity filtering only; real native
  discovery, live transport, platform persistence, and final production UI
  remain separate readiness gaps.

Next reviewer:
Codex should continue with the next codeable network/sync/app-boundary gap from
`docs/PRODUCTION_READINESS.md`, or platform native work once platform folders
are added.

---

### 2026-06-09 - Codex - Validate Recovery Persistence Scope Identity

Summary:
Hardened `peerdeal_sync` recovery persistence so invalid recovery scope
identities fail closed before mutating in-memory windows or resolving durable
JSON file paths. Scope identities now reject blank, padded, control-character,
and internal delimiter-bearing protocol/table/session values.

Files changed:
- `packages/peerdeal_sync/lib/src/models/recovery_persistence_scope.dart`
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `packages/peerdeal_sync/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/recovery_persistence_store_test.dart`
- `dart test`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks recovery persistence identity validation only; production
  database/platform persistence, native implementations, production transport,
  and final production UI remain separate readiness gaps.

Next reviewer:
Codex should continue with the next codeable sync/replay/app-boundary gap from
`docs/PRODUCTION_READINESS.md`, or platform native work once platform folders
are added.

---

### 2026-06-09 - Codex - Validate Replay Event Ranges

Summary:
Hardened `peerdeal_replay` so replay requests fail closed when event range
bounds are non-positive or inverted, before event filtering, anchor
calculation, or projector execution.

Files changed:
- `packages/peerdeal_replay/lib/src/engine/basic_replay_engine.dart`
- `packages/peerdeal_replay/test/basic_replay_engine_test.dart`
- `packages/peerdeal_replay/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/basic_replay_engine_test.dart`
- `dart test`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks replay request-shape validation only; platform-native
  implementations, production transport, durable platform persistence, and
  final production UI remain separate readiness gaps.

Next reviewer:
Codex should continue with the next codeable replay/sync/app-boundary gap from
`docs/PRODUCTION_READINESS.md`, or platform native work once platform folders
are added.

---

### 2026-06-09 - Codex - Lock Custom Home Native Navigation Restore

Summary:
Added mirrored mobile and desktop coverage proving custom home builders receive
native-readiness-required production navigation once readiness passes, matching
the default home hidden/visible policy.

Files changed:
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks the ready path for custom home navigation filtering only; platform
  native implementations remain separate readiness gaps.

Next reviewer:
Codex should continue with the next codeable production app-flow or
native-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Filter Custom Home Native Navigation

Summary:
Applied native-readiness production-navigation filtering before invoking
app-owned custom home builders in mobile and desktop shells, so protected
native-backed production routes are not advertised through custom home surfaces
while unavailable.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Custom home builders remain app-owned; this only filters the validated
  navigation entries supplied by the shell.

Next reviewer:
Codex should continue with the next codeable production app-flow or
native-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Render Production Home Unavailable State

Summary:
Added a stable production unavailable row to mobile and desktop default homes
when app-owned production navigation exists but readiness filtering leaves no
launchable production action. The state remains production-oriented and avoids
falling back to demo fixture content.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This is default app-shell status rendering only; real native readiness still
  depends on platform implementations.

Next reviewer:
Codex should continue with the next codeable production app-flow or
native-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Preserve Production Home During Readiness Filtering

Summary:
Kept mobile and desktop production-only default home presentation stable when
native-readiness filtering hides every protected production navigation action.
The home now uses the original validated production navigation intent, not only
the filtered visible actions, to decide whether demo fixture controls should be
suppressed.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks default app-shell presentation only; platform-native readiness
  implementations remain separate production gaps.

Next reviewer:
Codex should continue with the next codeable production app-flow or
native-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Suppress Demo Content On Production Home

Summary:
Updated the default mobile and desktop home so a production-only runtime uses
production-oriented title/subtitle text and suppresses demo fixture scenario
controls while still routing app-owned production navigation normally.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This improves the default app-shell production-only presentation only; final
  product UI still needs device and design validation.

Next reviewer:
Codex should continue with the next codeable production app-flow or
native-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Section Default Home Production Navigation

Summary:
Separated default mobile and desktop home navigation into production and demo
sections so app-owned production routes have a distinct launch surface without
changing the combined validated navigation list passed to custom home builders.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This improves the default demo-oriented home surface only; final production
  UI still needs product/device validation.

Next reviewer:
Codex should continue with the next codeable production app-flow or
native-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Hide Unready Native Production Navigation

Summary:
Filtered default mobile and desktop home navigation so production actions whose
paths require native readiness are hidden until the app-owned readiness snapshot
reports all native capabilities ready. Route-level fail-closed guards remain in
place for direct navigation.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Custom home builders remain app-owned and receive validated navigation
  entries directly; they must apply their own presentation policy.

Next reviewer:
Codex should continue with the next codeable production app-flow or
native-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Gate Production Routes On Native Readiness

Summary:
Added mobile and desktop runtime support for marking app-owned production
routes as native-readiness-required. Protected production route builders now
fail closed to the scrubbed route-unavailable surface until the app-owned
readiness loader reports all native capabilities ready.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This is an app orchestration gate; native platform implementations are still
  required before native-backed production routes can actually become ready.

Next reviewer:
Codex should continue with the next codeable production app-flow or
native-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Wire Native Readiness Home Status

Summary:
Threaded app-owned native readiness loaders through mobile and desktop runtime
objects and default home surfaces. The home now renders stable native
ready/unavailable status from scrubbed readiness snapshots while custom home
builders remain app-owned and synchronous.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This surfaces readiness for app orchestration; it still does not implement
  platform-native capture, local-network, transport, or secure-key handlers.

Next reviewer:
Codex should continue with the next codeable app-flow or native-boundary gap
from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Add App Native Readiness Loaders

Summary:
Added mobile and desktop app-owned native readiness loaders that compose
generic native bridge capability facts for capture protection, local-network
discovery, native transport, and secure-key storage into stable fail-closed
readiness snapshots with scrubbed warnings.

Files changed:
- `apps/peerdeal_mobile/lib/native_readiness/app_native_readiness_loader.dart`
- `apps/peerdeal_mobile/test/native_readiness/app_native_readiness_loader_test.dart`
- `apps/peerdeal_desktop/lib/native_readiness/app_native_readiness_loader.dart`
- `apps/peerdeal_desktop/test/native_readiness/app_native_readiness_loader_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/native_readiness/app_native_readiness_loader_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/native_readiness/app_native_readiness_loader_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This does not replace missing platform-native implementations; it gives app
  orchestration a stable fail-closed readiness boundary for those future
  implementations.

Next reviewer:
Codex should continue with platform implementation work if native app targets
are added, or the next app-flow production-readiness gap that can be coded
inside this repo snapshot.

---

### 2026-06-09 - Codex - Reject Allowed Extra Route Case Collisions

Summary:
Hardened mobile and desktop demo route-map allowed-extra validation so
case-variant production extension paths cannot both be admitted as explicit
route-map aliases.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/demo_slice/demo_slice_routes_test.dart`
  in `apps/peerdeal_mobile`
- `dart test test/demo_slice/demo_slice_routes_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Production non-demo route implementation remains app-owned; this locks the
  demo route-map extension validation boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Reload Mounted Flow Dependencies

Summary:
Hardened mobile and desktop mounted join/setup routes so async outcomes reload
when app-owned factories, initial mode, or enabled mode sets change, preventing
stale production invite/setup decisions after runtime dependency updates.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/join_flow/join_flow_route_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/setup_flow/setup_flow_route_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/join_flow/join_flow_route_test.dart`
  in `apps/peerdeal_desktop`
- `flutter test --no-pub test/setup_flow/setup_flow_route_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Production non-demo UI and native implementations remain pending; this locks
  mounted join/setup async dependency refresh behavior only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Reload Mounted Table Runtime Scope

Summary:
Hardened mobile and desktop mounted table routes so bootstrap and recovery
persistence futures reload when the app-owned runtime scope factory changes,
preventing stale production table/session scope after runtime dependency
updates.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_table_screen_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_table_screen_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/demo_table_screen_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/demo_table_screen_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform-native local-network discovery and production persistence roots
  remain pending; this locks mounted table runtime-scope refresh behavior only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Reject Production Demo Navigation Case Collisions

Summary:
Hardened mobile and desktop app-shell production navigation validation so
production home actions cannot case-collide with enabled demo home action
labels or paths.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart --name "production"`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart --name "production"`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Production UI and platform-native implementations remain pending; this locks
  app-shell production/demo navigation ambiguity rejection only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Reject Case-Colliding Production Navigation

Summary:
Hardened mobile and desktop app-shell production route and navigation
validation so case variants cannot create ambiguous mounted route paths or home
navigation labels.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart --name "production"`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart --name "production"`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Production UI and platform-native implementations remain pending; this locks
  app-shell route/navigation ambiguity rejection only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Suppress Sensitive Route Fallback Diagnostics

Summary:
Hardened mobile and desktop unknown-route fallback surfaces so suspicious route
names are suppressed instead of echoed into app UI diagnostics.

Files changed:
- `apps/peerdeal_mobile/lib/navigation/app_route_fallback_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/navigation/app_route_fallback_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart --name "route"`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart --name "route"`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Production navigation polish remains pending; this locks fallback diagnostic
  suppression only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Scrub Safe Surface Render Text

Summary:
Hardened shared safe-surface render models so injected capture warnings and
native notes are scrubbed and bounded before app UI can inspect render state.

Files changed:
- `packages/peerdeal_ui_kit/lib/src/safe_surface/safe_surface_render_model.dart`
- `packages/peerdeal_ui_kit/test/safe_surface_render_model_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/safe_surface_render_model_test.dart`
  in `packages/peerdeal_ui_kit`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Real platform capture enforcement remains pending; this locks shared
  safe-surface render text sanitization only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Scrub Capture Native Notes

Summary:
Hardened mobile and desktop capture surface coordinators so sensitive native
capture notes are replaced with stable unavailable text before UI projection.

Files changed:
- `apps/peerdeal_mobile/lib/safe_surface/capture_surface_coordinator.dart`
- `apps/peerdeal_mobile/test/safe_surface/capture_surface_coordinator_test.dart`
- `apps/peerdeal_desktop/lib/safe_surface/capture_surface_coordinator.dart`
- `apps/peerdeal_desktop/test/safe_surface/capture_surface_coordinator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/safe_surface/capture_surface_coordinator_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/safe_surface/capture_surface_coordinator_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Real platform capture blocking remains pending; this locks the app-owned
  capture diagnostic boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Scrub Local-Network Bootstrap Inputs

Summary:
Hardened mobile and desktop local-network bootstrap loaders and join
coordinators so sensitive native peer endpoints are dropped before candidate
resolution, and sensitive table-bootstrap native notes become stable
unavailable text.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_mobile/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_mobile/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_desktop/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_desktop/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/native_bootstrap_candidate_loader_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/join_flow/native_join_bootstrap_coordinator_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_bootstrap_candidate_loader_test.dart`
  in `apps/peerdeal_desktop`
- `flutter test --no-pub test/join_flow/native_join_bootstrap_coordinator_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Real platform local-network discovery remains pending; this locks the
  app-owned bootstrap sanitization boundary.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Scrub Native Transport Session Notes

Summary:
Hardened mobile and desktop native transport session factories so sensitive
native capability notes are replaced with stable unavailable text before app
transport load results expose them.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_session_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/transport/native_transport_session_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/transport/native_transport_session_factory_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Live native transport implementations remain pending; this locks the app
  factory diagnostic boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Mounted Table Recovery Display

Summary:
Hardened mobile and desktop mounted table routes so oversized injected recovery
persistence windows only expose a capped displayed event count plus a stable
warning before reaching table surfaces.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart --name "mounted table"`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart --name "mounted table"`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Production database/platform persistence remains pending; this locks the
  mounted table display boundary for injected recovery windows only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Mounted Table Bootstrap Candidates

Summary:
Hardened mobile and desktop mounted table routes so injected bootstrap
candidate lists are capped before load results reach table surfaces.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart --name "mounted table"`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart --name "mounted table"`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Real native local-network discovery and production transport remain pending;
  this locks the mounted table app-boundary candidate cap only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Scrub Mounted Table Load Warnings

Summary:
Hardened mobile and desktop mounted table routes so injected bootstrap and
recovery persistence warning lists are scrubbed and bounded before load results
reach table surfaces.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart --name "mounted table"`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart --name "mounted table"`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform persistence and real local-network/native implementations remain
  pending; this locks the app-owned mounted table warning boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Scrub Receipt Decoder Diagnostics

Summary:
Hardened mobile and desktop receipt artifact verifiers so decoder rejection
diagnostics are scrubbed and bounded before inspection results return to
presenter paths. Accepted inspections remain unchanged, while unsafe
artifact-derived diagnostics are replaced with stable generic text.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/demo_receipt_artifact_verifier.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_receipt_artifact_verifier_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/demo_receipt_artifact_verifier.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_receipt_artifact_verifier_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/demo_receipt_artifact_verifier_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/demo_receipt_artifact_verifier_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks the
  app-owned receipt verifier decoder diagnostic boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Scrub Receipt Verifier Diagnostics

Summary:
Hardened mobile and desktop receipt artifact verifiers so key-ring loader
warning diagnostics are scrubbed for sensitive markers, blank/control text, and
oversized values, then capped before rejected inspection results reach
presenter paths.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/demo_receipt_artifact_verifier.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_receipt_artifact_verifier_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/demo_receipt_artifact_verifier.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_receipt_artifact_verifier_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/demo_receipt_artifact_verifier_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/demo_receipt_artifact_verifier_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks the
  app-owned receipt verifier diagnostic boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Harden Receipt Verifier Key Loads

Summary:
Hardened mobile and desktop receipt artifact verifiers so key-ring loader
dependency exceptions become scrubbed rejected inspection results instead of
escaping verifier or presenter paths.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/demo_receipt_artifact_verifier.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_receipt_artifact_verifier_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/demo_receipt_artifact_verifier.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_receipt_artifact_verifier_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/demo_receipt_artifact_verifier_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/demo_receipt_artifact_verifier_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks the
  app-owned receipt verifier dependency-fault boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Harden Receipt Export Provisioning Faults

Summary:
Hardened mobile and desktop native receipt export artifact factories so
key-provisioning dependency exceptions return the same stable unavailable
artifact reason as failed provisioning instead of escaping export paths or
leaking diagnostic detail.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_export_artifact_factory.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_export_artifact_factory_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_export_artifact_factory.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_export_artifact_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/native_receipt_export_artifact_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_receipt_export_artifact_factory_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks the
  app-owned receipt export provisioning fault boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Harden Receipt Provisioning Factories

Summary:
Hardened mobile and desktop native receipt key-ring provisioners so app-owned
key-id and key-material factory exceptions fail closed with stable provisioning
warnings instead of escaping receipt export/provisioning paths.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_provisioner.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_provisioner_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_provisioner.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_provisioner_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_provisioner_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_provisioner_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks app-owned
  provisioning dependency failure handling only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Receipt Key Material

Summary:
Hardened mobile and desktop native receipt key-ring loaders and writers so
receipt key material must stay within explicit app-owned length limits and
cannot contain control characters before native records enter signer/cipher
providers or native save calls.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_loader_test.dart test/demo_slice/native_receipt_key_ring_writer_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_loader_test.dart test/demo_slice/native_receipt_key_ring_writer_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks the
  app-owned receipt key material boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Receipt Native Key Metadata

Summary:
Hardened mobile and desktop native receipt key-ring loaders so native secure-key
snapshots with oversized or control-character receipt key ids fail closed before
generic records are mapped into receipt signing/encryption providers. Invalid
loader metadata limits fail closed before native storage calls.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_loader_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_loader_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks the
  app-owned native receipt key metadata boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Receipt Mutation Key IDs

Summary:
Hardened mobile and desktop native receipt key-ring writers so app-owned
receipt key save/delete identifiers must stay within an explicit length limit
and cannot contain control characters before generic secure-key mutations reach
native storage.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_writer_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_writer_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks the
  app-owned receipt key mutation identifier boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Receipt Key Snapshot Records

Summary:
Hardened mobile and desktop native receipt key-ring loaders so native secure-key
snapshots must stay within an app-owned record limit before generic records are
mapped into receipt signing/encryption key material. Invalid app record limits
fail closed before native storage calls.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`
- `pubspec.lock`

Tests run:
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_loader_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_receipt_key_ring_loader_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Platform secure storage implementation remains pending; this locks the
  app-owned receipt key snapshot bound only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Native Transport Receive Batches

Summary:
Hardened mobile and desktop native transport drains so platform receive
snapshots are capped before frames reach session handlers, and invalid app
batch limits fail closed before native receive calls.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_frame_adapter_test.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_frame_adapter_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/transport/native_transport_frame_adapter_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/transport/native_transport_frame_adapter_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Live production transport still needs platform implementation; this locks the
  app-owned receive batch boundary only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Receipt Render Collections

Summary:
Hardened mobile and desktop receipt screens so rendered receipt shareable
fields and recovery diagnostics are capped before UI projection, with stable
truncation lines when injected presenter output exceeds the display limit.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_receipt_screen_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_receipt_screen_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/demo_receipt_screen_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/demo_receipt_screen_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Final production receipt UX still needs product validation; this locks
  mounted receipt render collection bounds only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Demo Route Extension Sets

Summary:
Hardened mobile and desktop demo route registries so enabled demo route
allowlists and route-map allowed-extra path sets enforce collection-size caps
before path validation.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/demo_slice/demo_slice_routes_test.dart` in
  `apps/peerdeal_mobile`
- `dart test test/demo_slice/demo_slice_routes_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Final production navigation design still needs product validation; this locks
  route-registry collection bounds only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Production Route Extensions

Summary:
Hardened mobile and desktop app shells so app-owned production route maps and
production home navigation descriptor lists must stay within explicit caps
before mounted route maps or home navigation are built.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Final production navigation design still needs product validation; this locks
  app-shell extension bounds only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Setup Route Messages

Summary:
Hardened mobile and desktop setup routes so injected setup outcome errors and
warnings are scrubbed and capped before rendering, with stable truncation
markers when the app display limit is exceeded.

Files changed:
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/setup_flow/setup_flow_route_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test/setup_flow/setup_flow_route_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run boundary-check:test`
- `dart run melos run dependency-audit:test`
- `dart run melos run source-text:test`
- `dart run melos run test:dart`
- `dart run melos run test:flutter`
- `git diff --check`

Risks:
- Final production setup UX still needs product/device validation; this locks
  route-level setup outcome rendering only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Bound Join Route Diagnostics

Summary:
Hardened mobile and desktop join routes so injected join outcomes are scrubbed
and capped before diagnostics render, with a stable truncation diagnostic when
the app display limit is exceeded.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/join_flow/join_flow_route_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test/join_flow/join_flow_route_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Final production join UX still needs product/device validation; this locks
  route-level diagnostic rendering only.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Receipt Export Provisioning Reason Scrub

Summary:
Hardened mobile and desktop native receipt export artifact factories so failed
key provisioning returns a stable unavailable artifact reason instead of
copying provisioning warning text into export metadata.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_export_artifact_factory.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_export_artifact_factory_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_export_artifact_factory.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_export_artifact_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/native_receipt_export_artifact_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_receipt_export_artifact_factory_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Native platform secure-key implementations remain external; this only locks
  the app export artifact boundary.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Case-Insensitive Demo Namespace Reservation

Summary:
Hardened mobile and desktop app-shell production route validation plus demo
route-map allowed-extra validation so `/Demo/...` and other case variants of
the reserved `/demo` namespace cannot be mounted as production extensions.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart test/demo_slice/demo_slice_routes_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart test/demo_slice/demo_slice_routes_test.dart`
  in `apps/peerdeal_desktop`
- `flutter test --no-pub test/demo_slice/demo_slice_routes_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/demo_slice_routes_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Native platform implementations, production UI, live transport, real
  local-network discovery, platform secure storage, and production persistence
  remain external readiness gaps.

Next reviewer:
Codex should continue with the next production-readiness package or
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-09 - Codex - Route Map Allowed Extra Validation

Summary:
Hardened mobile and desktop mounted demo route-map validation so caller-provided
allowed extra paths must be `/` or bounded non-demo production-style absolute
paths without unsafe routing metadata before they can permit extra route keys.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\demo_slice\demo_slice_routes_test.dart` in
  `apps/peerdeal_mobile`
- `dart test test\demo_slice\demo_slice_routes_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks route-map allowed-extra metadata only; native implementations,
  platform persistence, and final production UI validation remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Route Registry Metadata Bounds

Summary:
Hardened mobile and desktop mounted demo route registries so route labels and
surface names must be exact, bounded, non-empty strings without control
characters before feeding navigation or mounted route maps.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\demo_slice\demo_slice_routes_test.dart` in
  `apps/peerdeal_mobile`
- `dart test test\demo_slice\demo_slice_routes_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks static demo route registry metadata only; native implementations,
  platform persistence, and final production UI validation remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Route Map Drift Diagnostic Scrub

Summary:
Changed mobile and desktop mounted demo route-map drift validation to emit a
stable generic failure message instead of echoing missing or unexpected route
keys, and locked unexpected-route non-echoing behavior with mirrored tests.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\demo_slice\demo_slice_routes_test.dart` in
  `apps/peerdeal_mobile`
- `dart test test\demo_slice\demo_slice_routes_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks route-map drift diagnostics only; native implementations,
  platform persistence, and final production UI validation remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Enabled Demo Route Metadata Bounds

Summary:
Hardened mobile and desktop demo route allowlists so enabled demo paths must be
bounded canonical `/demo` paths without control, query, fragment,
duplicate-slash, or backslash metadata, and unknown allowlist failures no
longer echo supplied path text.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\demo_slice\demo_slice_routes_test.dart` in
  `apps/peerdeal_mobile`
- `dart test test\demo_slice\demo_slice_routes_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks enabled demo route allowlist metadata only; native
  implementations, platform persistence, and final production UI validation
  remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Production Route Metadata Bounds

Summary:
Bounded mobile and desktop app-owned production route paths, production
navigation labels, and startup routes, and rejected backslash-bearing route
metadata before mounted app-shell routing can consume it.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks app-owned route metadata bounds only; native implementations,
  platform persistence, and final production UI validation remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Production Route Builder Fallback

Summary:
Wrapped mobile and desktop app-owned production route builders after route
metadata validation so builder exceptions render the existing scrubbed
route-unavailable surface instead of escaping app-shell routing.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks production route failure handling only; final production UI,
  native implementations, and platform persistence remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Receipt Render Metadata Scrub

Summary:
Hardened mobile and desktop receipt screens so crafted receipt/recovery surface
view models cannot render arbitrary status, message, shareable field,
recommended-action, or diagnostic text. The render layer preserves
already-redacted values and replaces malformed display metadata with stable
generic text.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_receipt_screen_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_receipt_screen_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\demo_receipt_screen_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\demo_receipt_screen_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks receipt render metadata only; platform key storage, production
  receipt UX, and final native integrations remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Table Warning Rendering Scrub

Summary:
Hardened mobile and desktop mounted table surfaces so bootstrap and recovery
persistence warnings are scrubbed before rendering. Unsafe warning strings
containing paths, tokens, control characters, padding, or excessive length now
render stable generic warning text, while existing safe app warnings continue
to display unchanged.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_table_screen_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_table_screen_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\demo_table_screen_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\demo_table_screen_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks table warning rendering only; production transport, native
  persistence implementations, and final production UI validation remain
  pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Join Outcome Scrubbing Gate

Summary:
Hardened mobile and desktop join routes so app-owned join orchestrator outcomes
cannot render arbitrary result codes or diagnostics. Unsafe result codes fail
closed to `ERR_JOIN_OUTCOME_INVALID`; unsafe diagnostic codes/messages render
as generic safe diagnostic text while legitimate existing route diagnostics
continue to display.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\join_flow\join_flow_route_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\join_flow\join_flow_route_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks route-level join outcome rendering only; final production join UX,
  native implementations, and production UI validation remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Setup Outcome Scrubbing Gate

Summary:
Hardened mobile and desktop setup routes so app-owned setup orchestrator
outcomes cannot render arbitrary result codes, errors, warnings, or Game File
version strings. Unsafe result codes now fail closed to
`ERR_SETUP_OUTCOME_INVALID`, while unsafe displayed errors/warnings/version
values are replaced with stable generic safe codes.

Files changed:
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\setup_flow\setup_flow_route_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\setup_flow\setup_flow_route_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks route-level setup outcome rendering only; final production setup
  UX, native implementations, and production UI validation remain pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Home Navigation Collision Gate

Summary:
Hardened mobile and desktop app shells so production navigation descriptors
cannot reuse labels or paths from enabled demo home navigation. The check runs
before `WidgetsApp` route construction, and the composed home-navigation list
keeps a defensive duplicate-metadata gate before reaching the default or
app-owned home surface.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks app-owned home navigation metadata only; final product navigation
  design, platform native implementations, and production UI validation remain
  pending.

Next reviewer:
Codex should continue with the next production-readiness gap.

---

### 2026-06-09 - Codex - Production Route Metadata Gate

Summary:
Hardened mobile and desktop app-shell production routing validation so
production route paths, production navigation labels, and startup routes reject
unsafe control or whitespace metadata before app routes are mounted.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- This locks app-shell route metadata validation only; final production UI and
  navigation product validation remain pending.

Next reviewer:
Continue with the next codable production-readiness gap; final production UI
and navigation product validation remain outside this app-shell guardrail slice.

---

### 2026-06-09 - Codex - Native Transport Exact Key Gate

Summary:
Hardened native transport receive-frame decoding so platform maps must expose
exact field keys. Frames with keys that merely stringify to `sessionId`,
`senderPeerId`, `recipientPeerId`, `sequence`, or `payloadBytes` are dropped
instead of decoded.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\native_bridge_channel_contract_test.dart test\method_channel_native_transport_bridge_test.dart`
  in `packages/peerdeal_native_bridges`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- This locks Dart/native method-channel receive payload validation only; live
  platform transport implementations remain pending.

Next reviewer:
Continue with the next codable production-readiness gap; live platform
transport implementations remain outside this Dart-only slice.

---

### 2026-06-09 - Codex - Local Network Discovery List Gate

Summary:
Hardened generic local-network discovery decoding so malformed platform
`foundEndpoints` and `interfaceHints` entries are dropped instead of coerced
with `toString()`. This keeps arbitrary platform values out of app-owned
bootstrap mapping.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/local_network/local_network_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\native_bridge_channel_contract_test.dart test\method_channel_local_network_bridge_test.dart`
  in `packages/peerdeal_native_bridges`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- This locks Dart/native method-channel list payload validation only; real
  local-network discovery implementations remain pending.

Next reviewer:
Continue with the next codable production-readiness gap; real local-network
discovery implementations remain outside this Dart-only slice.

---

### 2026-06-09 - Codex - Native Transport Byte Payload Gate

Summary:
Hardened the generic native transport frame model so platform-bound native
transport sends reject payload lists containing values outside the byte range,
matching the receive decoder's fail-closed byte-payload contract.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_bridge_models.dart`
- `packages/peerdeal_native_bridges/test/method_channel_native_transport_bridge_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\native_bridge_channel_contract_test.dart test\method_channel_native_transport_bridge_test.dart`
  in `packages/peerdeal_native_bridges`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- This locks Dart/native method-channel payload validation only; live platform
  transport implementations remain pending.

Next reviewer:
Continue with the next codable production-readiness gap; live platform
transport implementations remain outside this Dart-only slice.

---

### 2026-06-09 - Codex - Native Transport Sequence Gate

Summary:
Aligned the generic native transport bridge with the public network transport
sequence contract. Native transport frames now require positive sequence numbers
before platform-bound sends, and receive-snapshot decoding drops frames with
zero or negative sequence values.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_bridge_models.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `packages/peerdeal_native_bridges/test/method_channel_native_transport_bridge_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\native_bridge_channel_contract_test.dart test\method_channel_native_transport_bridge_test.dart`
  in `packages/peerdeal_native_bridges`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- This locks Dart/native method-channel sequence validation only; live platform
  transport implementations remain pending.

Next reviewer:
Continue with the next codable production-readiness gap; live platform
transport implementations remain outside this Dart-only slice.

---

### 2026-06-08 - Codex - Transport Identity Padding Gate

Summary:
Hardened package-owned transport request validation so `peerdeal_network`
rejects padded session/peer frame identities before validating sender/receiver
boundaries call sinks or handlers, and `peerdeal_native_bridges` rejects padded
native transport frame/receive identities before platform send/receive calls.

Files changed:
- `packages/peerdeal_network/lib/src/services/basic_transport_frame_validator.dart`
- `packages/peerdeal_network/test/basic_transport_frame_validator_test.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_bridge_models.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/method_channel_native_transport_bridge.dart`
- `packages/peerdeal_native_bridges/test/method_channel_native_transport_bridge_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\basic_transport_frame_validator_test.dart test\validating_transport_frame_sender_test.dart test\validating_transport_frame_receiver_test.dart`
  in `packages/peerdeal_network`
- `flutter test --no-pub test\method_channel_native_transport_bridge_test.dart`
  in `packages/peerdeal_native_bridges`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks Dart transport request validation only; live platform transport
  implementations remain pending.

Next reviewer:
Continue with the next codable production-readiness gap; live platform
transport implementations remain outside this Dart-only slice.

---

### 2026-06-08 - Codex - Native Secure Key Request Gate

Summary:
Hardened the generic native secure key storage method-channel bridge so blank
or padded namespaces, key ids, and key record fields fail closed before
platform load/save/delete calls. The contract remains receipt-agnostic; app
receipt key-ring mapping still lives in the app shells.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/secure_storage/method_channel_secure_key_storage_bridge.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_bridge_models.dart`
- `packages/peerdeal_native_bridges/test/method_channel_secure_key_storage_bridge_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub` in `packages/peerdeal_native_bridges`

Risks:
- This locks Dart method-channel request validation only; real platform secure
  key storage implementations remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-08-09 - Codex - Windows Native Host Safety Hardening

Summary:
Hardened the Windows secure-key host against null output buffers and malformed
Credential Manager blob shapes, including zero-length blobs. Capture capability
and enablement now require Windows 10 build 19041 or newer, matching the
availability of `WDA_EXCLUDEFROMCAPTURE`; unsupported hosts fail closed to the
existing app-owned visual fallback.

Files changed:
- `apps/peerdeal_desktop/windows/runner/windows_secure_key_storage.cpp`
- `apps/peerdeal_desktop/windows/runner/windows_capture_protection.cpp`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/API_CONTRACTS.md`
- `HANDOFF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter build windows --debug --no-pub`

Risks:
- Native runtime persistence, OS capture behavior, Android signing/device
  validation, and non-Windows implementations remain open.

Next reviewer:
Run the full repository gates and commit if green.

---

### 2026-08-09 - Codex - SessionClosed Retention Event Adapter

Summary:
Added mirrored app-owned `AppRecoverySessionCloseEventAdapter` seams. They
ignore unrelated events, require the locked protocol catalog entry and exact
recovery scope for `SessionClosed`, reject malformed timestamps, and map the
event's `emitted_at` value into the existing exactly-once retention coordinator.
Protocol reducer truth and event emission remain outside the adapter.

Files changed:
- `apps/peerdeal_mobile/lib/recovery/app_recovery_session_close_coordinator.dart`
- `apps/peerdeal_mobile/lib/recovery/app_recovery_session_close_event_adapter.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_session_close_event_adapter_test.dart`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_session_close_coordinator.dart`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_session_close_event_adapter.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_session_close_event_adapter_test.dart`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/recovery/app_recovery_session_close_event_adapter_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/recovery/app_recovery_session_close_event_adapter_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- The concrete production session owner still must invoke this adapter when
  the reducer accepts `SessionClosed`; platform/database persistence and native
  runtime validation remain open.

Next reviewer:
Run the full repository gates and connect the adapter to the real session
owner when that orchestration surface is available.

---

### 2026-08-09 - Codex - Exactly-Once Session-Close Retention

Summary:
Added mirrored app-owned `AppRecoverySessionCloseCoordinator` seams. Each
coordinator binds one recovery scope and retention policy to one app session,
delegates the first close signal to `AppRecoveryRetentionCoordinator`, and
caches the first success or failure so later close signals cannot repeat policy
evaluation or storage wipe work. It does not emit protocol events or claim that
the real production session owner is wired.

Files changed:
- `apps/peerdeal_mobile/lib/recovery/app_recovery_session_close_coordinator.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_session_close_coordinator_test.dart`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_session_close_coordinator.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_session_close_coordinator_test.dart`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/recovery/app_recovery_session_close_coordinator_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/recovery/app_recovery_session_close_coordinator_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- The real session owner still must invoke the coordinator when `SessionClosed`
  is committed; production database/platform persistence and runtime validation
  remain open.

Next reviewer:
Run the full repository gates and wire this coordinator to the real session
owner once that app/session integration surface exists.

---

### 2026-08-09 - Codex - App Retention Wipe Orchestration

Summary:
Added mirrored mobile and desktop `AppRecoveryRetentionCoordinator` seams.
They reject invalid recovery scopes, evaluate the existing privacy policy engine
with caller-supplied timestamps, invoke `RecoveryPersistenceStore.wipe` only
when due, and normalize policy/storage exceptions into fatal persistence
outcomes. The coordinators are callable app APIs; production session-close
scheduling is not claimed as complete.

Files changed:
- `apps/peerdeal_mobile/lib/recovery/app_recovery_retention_coordinator.dart`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_retention_coordinator.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_retention_coordinator_test.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_retention_coordinator_test.dart`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/REPO_BRIEF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Mobile and desktop retention coordinator focused tests: passed.
- Full `melos run test`, analyze, boundary-check, source-text, and
  dependency-audit gates: passed.

Risks:
- Production session-close scheduling, runtime/device validation, and
  production database/platform persistence remain open.

Next reviewer:
Run the full repository gates and commit if green.

---

### 2026-08-09 - Codex - Recovery Persistence Wipe Hardening

Summary:
Extended the `peerdeal_sync` recovery persistence contract with a validated,
idempotent `wipe` operation. In-memory storage removes the scoped recovery
window; JSON storage removes the scoped durable file and matching interrupted
write temp files while preserving other scopes. Retention policy remains
outside the sync package and decides when to invoke the primitive.

Files changed:
- `packages/peerdeal_sync/lib/src/contracts/recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `packages/peerdeal_sync/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `HANDOFF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused sync persistence tests: passed.
- Mobile and desktop app-shell tests: passed.
- Full `melos run test`, analyze, boundary-check, source-text, and
  dependency-audit gates: passed.

Risks:
- Retention-policy scheduling and production database/platform persistence
  remain separate open work.

Next reviewer:
Run the full repository gates and commit if green.

---

### 2026-06-08 - Codex - Recovery Environment Root Padding Gate

Summary:
Hardened mobile and desktop recovery persistence factories so
`PEERDEAL_RECOVERY_ROOT` is preserved exactly and padded environment-provided
roots fail closed through the existing root validator instead of being silently
trimmed into an accepted durable JSON store path.

Files changed:
- `apps/peerdeal_mobile/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks environment-root validation only; production database/platform
  persistence remains pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Join Route Input Gate

Summary:
Hardened mobile and desktop mounted join routes so injected invite contexts
with blank or padded invite codes/rejoin tokens fail closed before join
orchestrator dependencies are constructed. Focused tests prove malformed
route-level join input returns the existing rejected result codes without
creating the orchestrator.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\join_flow\join_flow_route_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\join_flow\join_flow_route_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks route-level join input validation only; production invite UX and
  live transport integration remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Setup Route Identity Gate

Summary:
Hardened mobile and desktop mounted setup routes so injected setup intents with
blank or padded intent/host identities fail closed before setup orchestrator
dependencies are constructed. Focused tests prove malformed route-level setup
inputs return `ERR_SETUP_INTENT_INVALID` without creating the orchestrator.

Files changed:
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\setup_flow\setup_flow_route_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\setup_flow\setup_flow_route_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks route-level setup intent identity validation only; production
  setup UX and final platform orchestration remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Enabled Demo Route Allowlist Gate

Summary:
Hardened mobile and desktop demo route registries so app-owned enabled-route
allowlists reject blank or padded route paths before route matching. Focused
tests prove padded allowlist entries fail closed instead of silently enabling a
demo surface.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\demo_slice_routes_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\demo_slice_routes_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks app-owned demo route gating only; final production navigation and
  UI validation remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Receipt Delete Key Id Gate

Summary:
Hardened mobile and desktop native receipt key-ring writers so direct app-owned
delete requests reject blank, padded, or delimiter-bearing receipt key ids
before native secure-storage mutation calls. Focused tests prove padded delete
ids fail closed and never reach the native bridge fake.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_writer_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_writer_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks app-owned receipt key delete validation only; native platform
  secure-storage implementations remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Join Input Padding Gate

Summary:
Hardened mobile and desktop join-flow orchestrators so direct app
orchestration rejects blank or padded invite codes and rejoin tokens before
invite resolution or governance commit adapters run. Focused tests prove padded
values fail closed before throwing invite resolvers are reached.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_orchestrator.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_orchestrator_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_orchestrator.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_orchestrator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\join_flow\join_flow_orchestrator_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\join_flow\join_flow_orchestrator_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks app-owned join input validation only; final production invite UX
  and live transport integrations remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Setup Identity Padding Gate

Summary:
Hardened mobile and desktop setup-flow orchestrators so app-owned setup intent
and host identities reject leading or trailing whitespace before wizard
dependencies run. Focused tests prove padded IDs fail closed before throwing
wizard fakes are reached.

Files changed:
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_orchestrator.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_orchestrator_test.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_orchestrator.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_orchestrator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\setup_flow\setup_flow_orchestrator_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\setup_flow\setup_flow_orchestrator_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks app-owned setup identity validation only; final production setup
  UX and product flow validation remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Local Network Bootstrap Padding Gate

Summary:
Hardened mobile and desktop local-network bootstrap scope validation so mounted
table bootstrap loaders and join bootstrap coordinators reject padded
session/table scope before native capability lookup. Tests prove malformed
scope does not reach native bridge calls or bootstrap candidate resolution.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_mobile/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_mobile/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_desktop/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_desktop/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_bootstrap_candidate_loader_test.dart test\join_flow\native_join_bootstrap_coordinator_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_bootstrap_candidate_loader_test.dart test\join_flow\native_join_bootstrap_coordinator_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks app-owned local-network scope validation only; platform-native
  discovery remains pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Recovery Root Padding Gate

Summary:
Hardened mobile and desktop app-owned recovery persistence factories so
app-provided durable root directories fail closed when padded with leading or
trailing whitespace. This prevents ambiguous JSON recovery store roots from
being constructed before platform/database persistence exists.

Files changed:
- `apps/peerdeal_mobile/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks app-owned root validation only; production platform/database
  persistence remains pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Native Transport Sink Validation Gate

Summary:
Added mobile and desktop app-shell guards so `NativeTransportFrameSink`
validates outbound frames before invoking generic native transport send methods,
even when the sink is constructed directly. Session factories now pass their
configured app validator into the sink so direct adapter and factory sender
limits stay aligned.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_frame_adapter_test.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_frame_adapter_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\transport\native_transport_frame_adapter_test.dart test\transport\native_transport_session_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\transport\native_transport_frame_adapter_test.dart test\transport\native_transport_session_factory_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks the app-owned send adapter gate only; live platform transport
  implementations remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Native Transport Receive Scope Gate

Summary:
Added mobile and desktop app-shell guards so `NativeTransportFrameDrain` rejects
blank or padded receive session/peer scope before invoking native transport
receive methods. Focused tests prove malformed app scope fails closed without
calling the generic native bridge.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_frame_adapter_test.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_frame_adapter_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\transport\native_transport_frame_adapter_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\transport\native_transport_frame_adapter_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- This locks the app-owned receive-scope gate only; live platform transport
  implementations remain pending.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Local Network Bootstrap Scope Gate

Summary:
Hardened mobile and desktop local-network bootstrap paths so table bootstrap
loaders fail closed, and join bootstrap coordinators fall back to relay-only
plans, before native capability lookup when app-owned session/table bootstrap
scope is blank.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_mobile/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_mobile/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_desktop/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_desktop/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_bootstrap_candidate_loader_test.dart test\join_flow\native_join_bootstrap_coordinator_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_bootstrap_candidate_loader_test.dart test\join_flow\native_join_bootstrap_coordinator_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Native local-network discovery still requires platform-native
  implementations behind the locked bridge contract.

Next reviewer:
Continue with native/platform implementation gaps or the next codable
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Transport Direct Payload Gate

Summary:
Hardened mobile and desktop native transport session factories so direct
sender and drain creation fail closed before native send or receive calls when
the app-owned payload limit is invalid. This aligns direct factory entry
points with the existing `loadSession` payload-limit gate.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_session_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\transport\native_transport_session_factory_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\transport\native_transport_session_factory_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Live transport still requires platform-native implementations behind the
  locked method-channel contract.

Next reviewer:
Continue with native/platform implementation gaps or the next codable
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Receipt Key Namespace Gate

Summary:
Hardened mobile and desktop native receipt key-ring loaders and writers so
blank or padded app-owned receipt key namespaces fail closed before any native
secure-storage load, save, or delete call.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_writer_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_writer_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Native platform secure-storage implementations still need to enforce their
  own namespace isolation and storage permissions.

Next reviewer:
Continue with native/platform implementation gaps or the next codable
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Receipt Active Key Ambiguity Gate

Summary:
Hardened mobile and desktop native receipt key-ring loaders so snapshots with
multiple active receipt signing or encryption keys fail closed to an empty key
ring with scrubbed app warnings. Provisioners now preserve that failure and do
not create replacement keys over ambiguous native storage state.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_provisioner_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_loader_test.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_provisioner_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_provisioner_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_provisioner_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Native platform secure-storage implementations still need to enforce key
  activation/rotation invariants at the storage layer.

Next reviewer:
Continue with native/platform implementation gaps or the next codable
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - App Home Surface Builder

Summary:
Added app-owned home surface builders to both app runtime objects. Mobile and
desktop shells can now replace the default demo home with a production-owned
surface that receives validated home navigation entries, while builder failures
fail closed to the scrubbed route-unavailable surface.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- Final production UI still needs product and device validation; this slice
  only locks the runtime replacement seam and failure behavior.

Next reviewer:
Continue with native/platform implementation gaps or the next codable
app-boundary gap from `docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - App Production Navigation Gate

Summary:
Added validated app-owned production navigation descriptors to both app runtime
objects. Mobile and desktop home navigation can now link to mounted non-demo
production routes, and malformed labels, duplicate metadata, or paths that do
not reference production routes fail closed before the shell renders.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Runtime callers must mount a production route before advertising it through
  production navigation descriptors.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - App Initial Route Gate

Summary:
Added validated app-owned initial-route selection to both app runtime objects.
Mobile and desktop shells can now start on `/`, an enabled demo route, or a
validated non-demo production route. Malformed startup routes and disabled demo
startup routes fail closed before `WidgetsApp` receives the app route map.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Runtime callers that configure an initial route not present in enabled demo
  routes or production routes now receive a construction-time `StateError`.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - App Production Route Extension

Summary:
Added validated app-owned production route maps to both app runtime objects.
Mobile and desktop shells can now mount non-demo `WidgetBuilder` routes without
editing `DemoSliceRoutes`, while `/demo/*`, `/`, query/fragment paths, trailing
slash paths, and malformed route keys are rejected before `WidgetsApp` receives
the route map.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Runtime callers that previously expected to mount ad hoc `/demo/*` paths
  through app extras must instead use the demo registry or choose a non-demo
  production route path.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - App Demo Route Gates

Summary:
Added app-owned enabled-route gates to mounted demo navigation in both app
shells. The stable mobile and desktop runtime objects can now restrict which
`/demo/*` paths are mounted, home/table/chat actions hide disabled paths, and
direct requests for disabled demo paths fail closed through the existing
scrubbed route-unavailable surface.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_chat_screen.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_chat_screen.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\demo_slice_routes_test.dart test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\demo_slice_routes_test.dart test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Runtime callers that disable mounted demo paths now get the route-unavailable
  surface for direct navigation to those paths instead of the demo surface.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - App Route Mode Gates

Summary:
Added app-owned enabled-mode gates to mounted join and setup routes in both app
shells. The stable mobile and desktop runtime objects can now restrict which
demo route branches are exposed, and disabled initial modes fail closed instead
of running hidden demo flows.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\join_flow\join_flow_route_test.dart test\setup_flow\setup_flow_route_test.dart test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\join_flow\join_flow_route_test.dart test\setup_flow\setup_flow_route_test.dart test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Runtime callers that intentionally disable the initially selected join/setup
  mode now receive explicit unavailable outcomes instead of implicit fallback.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Sync Genesis Recovery Gate

Summary:
Hardened sync recovery boundaries so no-snapshot recovery windows and first
persisted recovery events must chain from the protocol-owned `genesisEventHash`
before conflict resolution, snapshot apply, or persistence append can proceed.
Normalized sync and app recovery test fixtures to the same genesis marker.

Files changed:
- `packages/peerdeal_sync/lib/src/engine/basic_conflict_detector.dart`
- `packages/peerdeal_sync/lib/src/engine/basic_snapshot_applier.dart`
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/basic_conflict_detector_test.dart`
- `packages/peerdeal_sync/test/basic_snapshot_applier_test.dart`
- `packages/peerdeal_sync/test/basic_sync_coordinator_test.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_sync`
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart` in `apps/peerdeal_desktop`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Recovery callers that append or apply first events with lowercase or alternate
  genesis markers now fail closed.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Replay Genesis Window Gate

Summary:
Added a protocol-owned `genesisEventHash` constant and hardened replay
full-window validation so windows without a snapshot base must start at
`event_seq` 1 and chain from the canonical genesis hash before projection.
Replay-local fixtures now use the same genesis marker as protocol fixtures.

Files changed:
- `packages/peerdeal_protocol/lib/src/models/protocol_constants.dart`
- `packages/peerdeal_protocol/lib/peerdeal_protocol.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `packages/peerdeal_replay/lib/src/engine/event_window_validator.dart`
- `packages/peerdeal_replay/test/anchor_hash_calculator_test.dart`
- `packages/peerdeal_replay/test/basic_replay_engine_test.dart`
- `packages/peerdeal_replay/test/fixtures/basic_session_replay.json`
- `packages/peerdeal_replay/test/mismatch_diagnostics_test.dart`
- `packages/peerdeal_replay/test/snapshot_suffix_replayer_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_protocol`
- `dart test` in `packages/peerdeal_replay`
- `dart test test\basic_replay_engine_test.dart --name "does not start at event sequence 1"` in `packages/peerdeal_replay`
- `dart test test\basic_replay_engine_test.dart --name "non-genesis first hash"` in `packages/peerdeal_replay`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Replay callers that pass partial event windows without a snapshot base now
  fail closed instead of projecting from an unanchored suffix.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Core Event Envelope Identity Gate

Summary:
Hardened `CoreReducer` so whitespace-only event envelope identity, stream
scope, timestamp, actor, and hash-chain fields fail closed before
protocol-compatible events can mutate deterministic state.

Files changed:
- `packages/peerdeal_core/lib/src/models/core_invariant_codes.dart`
- `packages/peerdeal_core/lib/src/reducer/core_reducer.dart`
- `packages/peerdeal_core/test/peerdeal_core_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_core`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Direct reducer callers that used whitespace placeholders in event envelopes
  now receive `ERR_EVENT_ENVELOPE_IDENTITY_EMPTY` before projection.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Core Command Identity Gate

Summary:
Hardened `CoreCommandValidator` so whitespace-only command envelope identity
fields fail validation before accepted command paths reach core orchestration.
Open Table commands now also reject blank table ids, not only missing table ids.

Files changed:
- `packages/peerdeal_core/lib/src/validation/core_command_validator.dart`
- `packages/peerdeal_core/test/peerdeal_core_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_core`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- Existing callers that used whitespace placeholders in command envelopes will
  now receive validation errors instead of passing the core command gate.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Wizard Compile Plan Identity Gate

Summary:
Hardened `DefaultGameFileCompiler` so manually constructed build-ready setup
plans with blank plan ids cannot compile into Game Files. Strict `compile`
throws and `tryCompile` now rejects with `setup_plan_id_missing`, preserving the
resolver identity gate at the compiler boundary.

Files changed:
- `packages/peerdeal_wizard/lib/src/engine/default_game_file_compiler.dart`
- `packages/peerdeal_wizard/test/game_file_compiler_test.dart`
- `packages/peerdeal_wizard/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_wizard`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- Manually constructed plans with whitespace-only ids now fail closed even if
  marked build-ready.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Wizard Setup Identity Gate

Summary:
Hardened `peerdeal_wizard` setup resolution so direct wizard callers cannot
turn blank setup intent or host identities into build-ready plans. The resolver
now trims intent ids and carries blank identity problems as unresolved issues
that validation rejects before Game File compilation.

Files changed:
- `packages/peerdeal_wizard/lib/src/engine/default_preset_resolver.dart`
- `packages/peerdeal_wizard/test/preset_resolver_test.dart`
- `packages/peerdeal_wizard/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_wizard`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- Whitespace-padded setup intent ids are normalized before plan id generation.
  This is intentional to prevent whitespace-bearing production plan ids.

Next reviewer:
Continue with the next production-readiness package or app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - App Receipt Source Conflict Preservation

Summary:
Stopped both app shells from masking conflicting receipt export sources before
mounted receipt route construction. If a production runtime supplies both a
prebuilt receipt artifact and an export factory, the route now receives both
and triggers its existing fail-closed conflict gate instead of silently choosing
one source.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- This changes app-shell conflict handling only. Normal artifact-only and
  export-factory-only receipt flows should remain unchanged.

Next reviewer:
Continue with the next production-readiness app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - App Runtime Setup Identity Coverage

Summary:
Added mounted app-shell coverage for runtime-injected setup intent factories in
both Flutter shells. Blank setup intent and host identities now fail closed
through the stable app runtime dependency object path, not only direct route
injection.

Files changed:
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- This is a coverage hardening slice. The behavior was introduced at the
  setup-flow orchestrator boundary in the preceding commit.

Next reviewer:
Continue with the next production-readiness app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Setup Intent Identity Gate

Summary:
Hardened app setup-flow orchestration in both Flutter shells so malformed
app-owned setup identities fail closed before `peerdeal_wizard` resolution.
Blank setup intent ids and host pseudonymous ids now produce an explicit
`ERR_SETUP_INTENT_INVALID` outcome, and mounted setup routes surface that
rejection for injected production setup intent sources.

Files changed:
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_orchestrator.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_orchestrator_test.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_orchestrator.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_orchestrator_test.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\setup_flow\setup_flow_orchestrator_test.dart` in
  `apps/peerdeal_mobile`
- `dart test test\setup_flow\setup_flow_orchestrator_test.dart` in
  `apps/peerdeal_desktop`
- `flutter test --no-pub test\setup_flow\setup_flow_route_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\setup_flow\setup_flow_route_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`

Risks:
- This is app-boundary validation only. The wizard still treats setup intent
  identity as caller-owned structured input.

Next reviewer:
Continue with the next production-readiness app-boundary gap from
`docs/PRODUCTION_READINESS.md`.

---

### 2026-06-08 - Codex - Join Invite Context Gate

Summary:
Hardened mounted join routes in both app shells so app-owned invite contexts are
validated before deeper orchestration. Blank invite codes and whitespace-only
rejoin tokens now fail closed at the route boundary instead of reaching join
adapters.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\join_flow\join_flow_route_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\join_flow\join_flow_route_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This validates mounted route invite context shape only. Production invite
  retrieval and native/local transport remain tracked readiness gaps.

Next reviewer:
Keep route-level invite context validation aligned with future production
invite source adapters.

---

### 2026-06-08 - Codex - App Runtime Override Merge

Summary:
Hardened mobile and desktop app runtime dependency composition. When callers
provide both a runtime dependency object and focused constructor-level
overrides, the non-null constructor overrides are merged instead of being
silently ignored.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- Constructor overrides now take precedence over fields inside a provided
  runtime object. This preserves existing focused injection behavior but callers
  should avoid passing conflicting dependencies.

Next reviewer:
Keep runtime dependency grouping and focused constructor overrides aligned as
non-demo app orchestration replaces demo routes.

---

### 2026-06-08 - Codex - Receipt Export Path Gate

Summary:
Hardened receipt route input handling in both app shells. Direct
`PeerDealReceipt` input now fails closed when no export factory is available,
and app roots only pass default demo receipts when an export path or injected
receipt source requires one.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_receipt_screen_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_receipt_screen_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\demo_receipt_screen_test.dart
  test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\demo_receipt_screen_test.dart
  test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `dart run melos run test`
- `git diff --check`

Risks:
- This locks receipt input/export path agreement only. Platform secure storage
  and final production receipt UX remain tracked readiness gaps.

Next reviewer:
Keep app receipt source injection aligned with the mounted route export
artifact factory boundary.

---

### 2026-06-08 - Codex - Receipt Export Source Conflict Gate

Summary:
Hardened mounted receipt routes in both app shells so conflicting receipt export
sources fail closed. If a route receives both a prebuilt export artifact and an
export factory, it now projects a rejected receipt surface instead of silently
preferring one source.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_receipt_screen_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_receipt_screen_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\demo_receipt_screen_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\demo_receipt_screen_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks app-route receipt export source validation only. Platform secure
  storage and final production receipt UX remain tracked readiness gaps.

Next reviewer:
Keep route-level receipt export configuration gates aligned with future
production receipt source orchestration.

---

### 2026-06-08 - Codex - Wizard Compiler Support Gate

Summary:
Hardened the Game File compiler as a second validation boundary. Even if a
caller manually constructs a build-ready `ValidatedSetupPlan`, the compiler now
rejects unsupported mode and variant ids before emitting a Game File.

Files changed:
- `packages/peerdeal_wizard/lib/src/engine/default_game_file_compiler.dart`
- `packages/peerdeal_wizard/test/game_file_compiler_test.dart`
- `packages/peerdeal_wizard/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_wizard`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This intentionally preserves the current Open Table/Tournament and
  `holdem_nlhe` launch boundary. Future supported modes/variants must widen
  resolver and compiler validation together.

Next reviewer:
Keep compiler support gates in sync with any production-ready mode or variant
expansion.

---

### 2026-06-08 - Codex - Wizard Unsupported Variant Gate

Summary:
Hardened wizard setup validation so unsupported variant ids are validation
errors instead of warnings. Launch setup now fails closed before Game File
compilation when a draft asks for anything outside the implemented
`holdem_nlhe` boundary.

Files changed:
- `packages/peerdeal_wizard/lib/src/engine/default_preset_resolver.dart`
- `packages/peerdeal_wizard/test/preset_resolver_test.dart`
- `packages/peerdeal_wizard/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_wizard`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This preserves the current Hold'em-first launch boundary. Adding Omaha/PLO
  later will require adding the variant implementation and then widening this
  validator intentionally.

Next reviewer:
Keep setup wizard validation aligned with the set of variant adapters that are
actually production-ready.

---

### 2026-06-08 - Codex - Holdem Blind Posting Gate

Summary:
Added a variant-local Hold'em blind-posting coordinator. It validates the
`blindsPosting` phase, blind sizes, blind-seat eligibility, and duplicate
commitments before mutating state; successful posting updates stacks,
commitments, pot, current bet/min raise, marks short blinds all-in, and advances
to `dealingHole`.

Files changed:
- `packages/peerdeal_variants/lib/peerdeal_variants.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_blind_posting_coordinator.dart`
- `packages/peerdeal_variants/test/holdem_blind_posting_coordinator_test.dart`
- `packages/peerdeal_variants/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\holdem_blind_posting_coordinator_test.dart` in
  `packages/peerdeal_variants`
- `dart test` in `packages/peerdeal_variants`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks deterministic blind posting only. Session-owned hand setup,
  hole-card dealing, event emission, and production app orchestration remain
  separate integration work.

Next reviewer:
Wire session-owned hand setup to call the blind-posting gate before hole-card
dealing when production hand orchestration is introduced.

---

### 2026-06-08 - Codex - Holdem Showdown Active Seat Gate

Summary:
Hold'em showdown evaluation now rejects inputs with fewer than two active
non-folded seats. The showdown coordinator fails closed on that warning, keeping
single-winner hands on the existing uncontested-settlement path instead of
allowing accidental showdown settlement.

Files changed:
- `packages/peerdeal_variants/lib/src/holdem/holdem_showdown_evaluator.dart`
- `packages/peerdeal_variants/test/holdem_adapter_test.dart`
- `packages/peerdeal_variants/test/holdem_showdown_coordinator_test.dart`
- `packages/peerdeal_variants/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\holdem_adapter_test.dart test\holdem_showdown_coordinator_test.dart test\holdem_lifecycle_settlement_test.dart test\holdem_action_street_coordinator_test.dart`
  in `packages/peerdeal_variants`
- `dart test` in `packages/peerdeal_variants`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This hardens Hold'em lifecycle semantics only; production app orchestration
  must still route one-active-seat hands through uncontested settlement.

Next reviewer:
Continue closing variant-local lifecycle gaps before platform-native work,
especially blind/posting and session-owned event emission integration.

---

### 2026-06-08 - Codex - Join Bootstrap Provider Fallback

Summary:
Mobile and desktop app-owned join bootstrap coordinators now convert
`BootstrapCandidateProvider` failures into relay-only bootstrap plans after
native discovery succeeds. This aligns join bootstrap with mounted table
bootstrap behavior and keeps candidate resolution faults from escaping the app
boundary.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_desktop/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_mobile/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `apps/peerdeal_desktop/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\join_flow\native_join_bootstrap_coordinator_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\join_flow\native_join_bootstrap_coordinator_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks app-level fallback behavior only; real native discovery and live
  transport remain platform implementation gaps.

Next reviewer:
Verify production candidate providers surface useful scrubbed diagnostics when
real local-network discovery is wired.

---

### 2026-06-08 - Codex - Network Validating Receive Boundary

Summary:
Added a network-owned validating transport receive boundary. Session handlers
now have a public `TransportFrameHandler` contract, and
`ValidatingTransportFrameReceiver` validates inbound frames before calling the
handler, rejects malformed frames without invoking session code, and converts
handler exceptions into explicit failed receive results.

Files changed:
- `packages/peerdeal_network/lib/peerdeal_network.dart`
- `packages/peerdeal_network/lib/src/contracts/transport_frame_receiver.dart`
- `packages/peerdeal_network/lib/src/contracts/transport_frame_handler.dart`
- `packages/peerdeal_network/lib/src/models/transport_frame_receive_result.dart`
- `packages/peerdeal_network/lib/src/services/validating_transport_frame_receiver.dart`
- `packages/peerdeal_network/test/validating_transport_frame_receiver_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_network`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- This locks the Dart receive boundary only; live platform transport and
  session integration remain production-readiness gaps.

Next reviewer:
Wire production inbound transport through `ValidatingTransportFrameReceiver`
when live transport code is added.

---

### 2026-06-08 - Codex - Network Validating Send Boundary

Summary:
Added a network-owned validating transport send boundary. Platform transport
sinks now have a public `TransportFrameSink` contract, and
`ValidatingTransportFrameSender` validates frames before calling the sink,
rejects malformed frames without invoking transport code, and converts sink
exceptions into explicit failed send results.

Files changed:
- `packages/peerdeal_network/lib/peerdeal_network.dart`
- `packages/peerdeal_network/lib/src/contracts/transport_frame_sender.dart`
- `packages/peerdeal_network/lib/src/contracts/transport_frame_sink.dart`
- `packages/peerdeal_network/lib/src/models/transport_frame_send_result.dart`
- `packages/peerdeal_network/lib/src/services/validating_transport_frame_sender.dart`
- `packages/peerdeal_network/test/validating_transport_frame_sender_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_network`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- This locks the Dart send boundary only; live platform transport
  implementations remain a production-readiness gap.

Next reviewer:
Wire production transport adapters through `ValidatingTransportFrameSender`
when platform transport code is added.

---

### 2026-06-08 - Codex - App Unknown Route Fallback

Summary:
Added fail-closed unknown-route handling in both Flutter app shells. Unsupported
route names now render an explicit rejected route-unavailable surface instead
of relying on default framework route errors.

Files changed:
- `apps/peerdeal_mobile/lib/navigation/app_route_fallback_screen.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/navigation/app_route_fallback_screen.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- This hardens app navigation failure behavior, but it is not final production
  navigation design or visual polish.
- Native transport, durable persistence, platform implementations, and final UI
  polish remain tracked readiness gaps.

Next reviewer:
Continue with app-shell navigation polish or platform implementation work where
the environment can exercise it.

---

### 2026-06-08 - Codex - Mounted Setup Flow Route

Summary:
Mounted the setup-flow boundary in both Flutter app shells. Demo home now links
to a setup route that receives an app-owned `SetupFlowOrchestrator` factory,
compiles build-ready setup intent through `peerdeal_wizard`, can display
fail-closed rejected setup outcomes, and returns a rejected unavailable outcome
when route-level factory construction fails.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_route_test.dart`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/setup_flow/setup_flow_orchestrator_test.dart test/setup_flow/setup_flow_route_test.dart test/app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test/setup_flow/setup_flow_orchestrator_test.dart test/setup_flow/setup_flow_route_test.dart test/app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- This mounts setup orchestration but is still a demo-grade route surface, not
  final production UX or navigation polish.
- Native transport, durable persistence, and platform implementations remain
  tracked readiness gaps.

Next reviewer:
Continue with another app-flow route mount or with platform implementation
work outside this chat environment.

---

### 2026-06-08 - Codex - App Setup Flow Orchestrator

Summary:
Added app-owned setup-flow orchestrators in both Flutter shells. The new
boundary resolves setup intent through `peerdeal_wizard`, validates the draft,
and compiles the Game File with `tryCompile`, returning explicit
compiled/rejected outcomes so UI routes do not own setup truth or catch compiler
exceptions directly.

Files changed:
- `apps/peerdeal_mobile/pubspec.yaml`
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_models.dart`
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_orchestrator.dart`
- `apps/peerdeal_mobile/test/setup_flow/setup_flow_orchestrator_test.dart`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/pubspec.yaml`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_models.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_orchestrator.dart`
- `apps/peerdeal_desktop/test/setup_flow/setup_flow_orchestrator_test.dart`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/setup_flow/setup_flow_orchestrator_test.dart` in
  `apps/peerdeal_mobile`
- `flutter test --no-pub test/setup_flow/setup_flow_orchestrator_test.dart` in
  `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- This is an app-service boundary, not production navigation or UI polish.
- Native transport, durable persistence, and platform implementations remain
  tracked readiness gaps.

Next reviewer:
Continue by mounting setup-flow outcomes in production-oriented app navigation,
or by implementing platform-native contracts outside this chat environment.

---

### 2026-06-07 - DeepSeek-Claude + Codex - Docs Bootstrap

Summary:
DeepSeek-Claude read `docs/ai/repomix-summary.xml` in a background worktree and
generated stable AI context docs. Codex reviewed the generated docs, corrected
ASCII/encoding artifacts, fixed the `SnapshotEnvelope`/`ProtocolDiagnostic`
contract summary against source, and copied the reviewed docs into the main
repo. No application code was changed.

Files changed:
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- TODO: docs-only review; no code tests required.

Risks:
- `peerdeal_wizard` scope remains a TODO until verified from source/README.
- Route paths are intentionally described as categories unless verified from
  current app-shell route code.
- Native transport, persistence, platform key storage, and production UI remain
  readiness gaps tracked in `docs/PRODUCTION_READINESS.md`.

Next reviewer:
Codex or DeepSeek-Claude should keep these docs concise and update only durable
facts.

---

### 2026-06-08 - Codex - Sync Recovery Persistence Seam

Summary:
Added a sync-owned recovery persistence contract plus an in-memory validation
store for snapshot/event recovery windows. The store rejects scope drift,
protocol drift, sequence gaps, hash-chain breaks, and snapshots ahead of the
stored event stream before mutating state. This advances the persistence
software seam without claiming durable platform storage is complete.

Files changed:
- `packages/peerdeal_sync/lib/peerdeal_sync.dart`
- `packages/peerdeal_sync/lib/src/contracts/recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/models/persisted_recovery_window.dart`
- `packages/peerdeal_sync/lib/src/models/recovery_persistence_result.dart`
- `packages/peerdeal_sync/lib/src/models/recovery_persistence_scope.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `packages/peerdeal_sync/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- Durable platform persistence remains a production gap; this slice locks the
  package contract and validation behavior only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Join Bootstrap App Candidate Limit Gate

Summary:
Hardened mobile and desktop `NativeJoinBootstrapCoordinator.buildPlan(...)` so
an invalid app-owned peer candidate limit returns the relay-fallback bootstrap
plan before local-network capability or discovery lookup. This matches the
mounted table bootstrap loader behavior and keeps bad join bootstrap
configuration from crossing the native bridge.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_desktop/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_mobile/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `apps/peerdeal_desktop/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\join_flow\native_join_bootstrap_coordinator_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\join_flow\native_join_bootstrap_coordinator_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks app join-bootstrap configuration validation only; real
  local-network discovery implementations remain a tracked readiness gap.

Next reviewer:
- Verify production join bootstrap configuration provides a positive peer
  candidate limit where native discovery is enabled.

### 2026-06-08 - Codex - Recovery Root Control Character Gate

Summary:
Hardened mobile and desktop `AppRecoveryPersistenceStoreFactory` so
app-provided or environment-provided recovery roots containing control
characters fail closed before constructing a durable JSON recovery store. This
keeps malformed recovery-root configuration out of `peerdeal_sync` while
preserving the app-owned environment configuration boundary.

Files changed:
- `apps/peerdeal_mobile/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks app recovery-root configuration validation only; production
  database/platform persistence remains a tracked readiness gap.

Next reviewer:
- Verify deployment configuration provides a stable, printable recovery root
  where durable JSON recovery persistence is enabled.

### 2026-06-08 - Codex - Native Bootstrap App Candidate Limit Gate

Summary:
Hardened mobile and desktop `NativeBootstrapCandidateLoader.load(...)` so an
invalid app-owned peer candidate limit fails closed before local-network
capability or discovery lookup. This keeps bad app bootstrap configuration from
crossing the native bridge while preserving existing discovery normalization and
candidate bounding.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_bootstrap_candidate_loader_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_bootstrap_candidate_loader_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks app bootstrap configuration validation only; real local-network
  discovery implementations remain a tracked readiness gap.

Next reviewer:
- Verify deployed app shells configure a positive peer candidate limit where
  native bootstrap discovery is enabled.

### 2026-06-08 - Codex - Native Transport App Payload Limit Gate

Summary:
Hardened mobile and desktop `NativeTransportSessionFactory.loadSession(...)`
so an invalid app-owned payload limit fails closed before native capability
lookup. This prevents bad app transport configuration from crossing into the
platform bridge while preserving existing native capability validation.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_session_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\transport\native_transport_session_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test\transport\native_transport_session_factory_test.dart`
  in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks app configuration validation only; real platform-native transport
  implementations remain a tracked readiness gap.

Next reviewer:
- Verify deployed app shells provide a positive app payload limit where
  transport is enabled.

### 2026-06-08 - Codex - Replay Projector Failure Gate

Summary:
Hardened `BasicReplayEngine` so projector base-state construction or event
application failures return an explicit failed replay result instead of letting
reconstruction exceptions escape. The diagnostic exposes the exception type
only and does not surface exception text.

Files changed:
- `packages/peerdeal_replay/lib/src/engine/basic_replay_engine.dart`
- `packages/peerdeal_replay/test/basic_replay_engine_test.dart`
- `packages/peerdeal_replay/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\basic_replay_engine_test.dart` in
  `packages/peerdeal_replay`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks replay dependency failure handling only; live transport, platform
  persistence, native implementations, and final production UI remain tracked
  readiness gaps.

Next reviewer:
- Verify no replay callers depend on projector exceptions escaping the replay
  boundary.

### 2026-06-08 - Codex - Replay Scope Mismatch Gate

Summary:
Hardened `BasicReplayEngine` so replay rejects event and snapshot table/session
scope mismatches against the replay request before projection. This prevents
reconstruction from merging another table/session stream into verified replay
state.

Files changed:
- `packages/peerdeal_replay/lib/src/engine/basic_replay_engine.dart`
- `packages/peerdeal_replay/test/basic_replay_engine_test.dart`
- `packages/peerdeal_replay/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\basic_replay_engine_test.dart` in
  `packages/peerdeal_replay`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This locks replay-window scope validation only; live transport, platform
  persistence, and app routing still remain separate readiness work.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Recovery Persistence Store Factory

Summary:
Added app-owned recovery persistence store factories in both app shells. The
factory creates the sync package's JSON file-backed recovery store only when
the app/platform layer supplies a usable root directory, and returns an
explicit unavailable result when the root cannot be resolved. This gives app
orchestration a stable durable recovery-store boundary without inventing
platform path-provider behavior or a production database.

Files changed:
- `apps/peerdeal_mobile/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart` in `apps/peerdeal_desktop`

Risks:
- Real platform directory selection and production database/platform
  persistence remain pending; this locks app construction of the existing file
  store only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Mounted Receipt Export Flow

Summary:
Wired app-owned receipt export artifact factories into mounted receipt routes
in both app shells. Routes can now build deterministic receipt inputs from the
active snapshot, export signed/encrypted artifacts through the native-backed
key provisioner boundary, then verify the artifact before projecting the safe
receipt surface. Existing fixture-only receipt presentation remains unchanged
unless an export factory is injected.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_export_artifact_factory.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_export_artifact_factory.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart test\demo_slice\demo_receipt_screen_test.dart test\demo_slice\native_receipt_export_artifact_factory_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart test\demo_slice\demo_receipt_screen_test.dart test\demo_slice\native_receipt_export_artifact_factory_test.dart` in `apps/peerdeal_desktop`

Risks:
- The native key storage implementation remains pending; this slice wires the
  route-level app boundary that will consume it.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Receipt Export Artifact Factory

Summary:
Added app-owned receipt export artifact factories in both app shells. The
factory provisions native-backed receipt keys, builds receipt signer/cipher
adapters from the provisioned key ring, and exports signed/encrypted artifacts
through the receipt service. Export fails closed when native key loading or
key mutation cannot complete.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_export_artifact_factory.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_export_artifact_factory_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_export_artifact_factory.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_export_artifact_factory_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_writer_test.dart test\demo_slice\native_receipt_key_ring_provisioner_test.dart test\demo_slice\native_receipt_export_artifact_factory_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_writer_test.dart test\demo_slice\native_receipt_key_ring_provisioner_test.dart test\demo_slice\native_receipt_export_artifact_factory_test.dart` in `apps/peerdeal_desktop`

Risks:
- Real keychain/keystore implementations remain pending; this locks the app
  export boundary that will consume them.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Receipt Key-Ring Provisioner

Summary:
Added app-owned receipt key-ring provisioners in both app shells. The
provisioner loads the native-backed receipt key ring, creates missing active
signing/encryption keys with secure random material, persists them through the
app-owned writer, and fails closed when native storage cannot be loaded or a
mutation is rejected. Receipt key semantics remain app/receipt-owned.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_provisioner.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_provisioner_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_provisioner.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_provisioner_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_writer_test.dart test\demo_slice\native_receipt_key_ring_provisioner_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_writer_test.dart test\demo_slice\native_receipt_key_ring_provisioner_test.dart` in `apps/peerdeal_desktop`

Risks:
- Real keychain/keystore implementations remain pending; this locks
  provisioning behavior behind the existing generic mutation bridge.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Receipt Key-Ring Writer Boundary

Summary:
Added app-owned receipt key-ring writers in both app shells. They map receipt
signing/encryption keys into generic native secure-key mutation records,
reject invalid save/delete requests before crossing the native bridge, and
return fail-closed write results when native mutation fails. Receipt semantics
remain in the app/receipt boundary, not in `peerdeal_native_bridges`.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_writer.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_receipt_key_ring_writer_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_writer_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_receipt_key_ring_loader_test.dart test\demo_slice\native_receipt_key_ring_writer_test.dart` in `apps/peerdeal_desktop`

Risks:
- Real keychain/keystore implementations remain pending; this locks the
  app-owned mapping and fail-closed mutation boundary only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Capability-Gated Native Transport Sessions

Summary:
Extended app-owned native transport session factories so production
orchestration can call `loadSession(...)` and fail closed unless the native
transport bridge reports available send and receive capability. Available
sessions expose only validated `peerdeal_network` sender/drain handles plus
native capability metadata.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/transport/native_transport_session_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/transport/native_transport_session_factory_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- Real native transport remains pending; this slice adds the app capability
  gate for the existing Dart/method-channel transport boundary only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Native Transport Session Factories

Summary:
Added app-owned native transport session factories in both app shells. The
factory defaults to `MethodChannelNativeTransportBridge` and creates only
validated `peerdeal_network` transport senders plus native frame drains backed
by validating receivers. This gives app orchestration a stable construction
boundary without manually composing native bridges and validation gates.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/transport/native_transport_frame_adapter_test.dart test/transport/native_transport_session_factory_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/transport/native_transport_frame_adapter_test.dart test/transport/native_transport_session_factory_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- Real native transport remains pending; this slice locks app construction of
  the Dart/native validation composition only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Native Transport Validation Adapters

Summary:
Added app-owned transport adapters in both app shells that map generic
`peerdeal_native_bridges` byte frames to `peerdeal_network` `TransportFrame`
objects. Outbound sends are intended to run through
`ValidatingTransportFrameSender`, and inbound native frame drains run through a
provided `TransportFrameReceiver`, so native transport cannot bypass the
network frame validation boundary.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_frame_adapter_test.dart`
- `apps/peerdeal_mobile/README.md`
- `apps/peerdeal_desktop/lib/transport/native_transport_frame_adapter.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_frame_adapter_test.dart`
- `apps/peerdeal_desktop/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/transport/native_transport_frame_adapter_test.dart`
  in `apps/peerdeal_mobile`
- `flutter test --no-pub test/transport/native_transport_frame_adapter_test.dart`
  in `apps/peerdeal_desktop`

Risks:
- Real native transport remains pending; this slice composes the Dart app
  boundary and validation gate only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Native Transport Channel Contract

Summary:
Added a generic native transport method-channel seam in
`peerdeal_native_bridges` for capability lookup, byte-frame sends, and inbound
frame snapshots. The seam is intentionally transport-adjacent only: it carries
session/peer identifiers, sequence numbers, and payload bytes, while routing
policy and protocol truth stay in `peerdeal_network` and higher layers.

Files changed:
- `packages/peerdeal_native_bridges/lib/peerdeal_native_bridges.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_bridge.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_bridge_models.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_channel_contract.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/method_channel_native_transport_bridge.dart`
- `packages/peerdeal_native_bridges/fixtures/native_transport_bridge_contract.json`
- `packages/peerdeal_native_bridges/test/method_channel_native_transport_bridge_test.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `packages/peerdeal_native_bridges/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/method_channel_native_transport_bridge_test.dart test/native_bridge_channel_contract_test.dart`
  in `packages/peerdeal_native_bridges`

Risks:
- Real native transport remains pending; this locks the Dart method-channel
  contract only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Canonical Recovery File Writes

Summary:
Hardened `JsonFileRecoveryPersistenceStore` so durable recovery windows are
written as canonical protocol JSON through a temporary file before replacing
the stored window. This keeps on-disk bytes stable for diagnostics and reduces
direct-write corruption risk while preserving the existing sync persistence
contract and validation gate.

Files changed:
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `packages/peerdeal_sync/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test/recovery_persistence_store_test.dart` in `packages/peerdeal_sync`

Risks:
- Production database/platform persistence remains pending; this hardens the
  Dart file-backed recovery store only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - File Recovery Persistence Store

Summary:
Added public JSON parsers for protocol event and snapshot envelopes, then added
`JsonFileRecoveryPersistenceStore` in `peerdeal_sync`. The file store writes
one JSON recovery window per scope, rehydrates through the existing in-memory
validation gate before each mutation, round-trips persisted windows across
store instances, and fails closed when stored data is corrupt.

Files changed:
- `packages/peerdeal_protocol/lib/src/models/event_envelope.dart`
- `packages/peerdeal_protocol/lib/src/models/snapshot_envelope.dart`
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart`
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/peerdeal_sync.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `packages/peerdeal_sync/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_protocol`
- `dart test` in `packages/peerdeal_sync`

Remaining gaps:
- Production database/platform persistence remains pending. This slice adds a
  durable Dart file store and protocol parse boundary, not a platform storage
  integration.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Native Join Bootstrap Coordinator

Summary:
Added app-owned `NativeJoinBootstrapCoordinator` implementations in mobile and
desktop. The mounted demo join factory now uses this coordinator by default
instead of hard-coded fake peer candidates. The coordinator reads generic
native local-network facts, normalizes endpoint strings, delegates candidate
resolution to `peerdeal_network`, and emits join `BootstrapPlan` inputs with
relay fallback preserved when local discovery is unavailable.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_mobile/lib/join_flow/demo_join_flow_orchestrator_factory.dart`
- `apps/peerdeal_mobile/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `apps/peerdeal_desktop/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_desktop/lib/join_flow/demo_join_flow_orchestrator_factory.dart`
- `apps/peerdeal_desktop/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/join_flow/native_join_bootstrap_coordinator_test.dart test/join_flow/join_flow_orchestrator_test.dart test/app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test/join_flow/native_join_bootstrap_coordinator_test.dart test/join_flow/join_flow_orchestrator_test.dart test/app_shell_test.dart` in `apps/peerdeal_desktop`

Remaining gaps:
- Real native local-network discovery and production transport remain pending
  platform work. This slice removes fake join bootstrap candidates from the
  default app factory but does not implement live transport.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Local-Network Bootstrap Boundary

Summary:
Added app-owned native bootstrap candidate loaders in both app shells. The
loaders read generic `peerdeal_native_bridges` local-network capability and
discovery snapshots, normalize endpoint strings at the app boundary, and pass
them to `peerdeal_network` bootstrap candidate resolution. Capability,
discovery, permission, and provider failures return explicit fail-closed
results instead of throwing. Mounted table routes now receive an app-owned
loader factory, load bootstrap candidates asynchronously, and render only the
resulting table view state.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/demo_slice/native_bootstrap_candidate_loader_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test/demo_slice/native_bootstrap_candidate_loader_test.dart` in `apps/peerdeal_desktop`
- `flutter test --no-pub test/app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test/app_shell_test.dart` in `apps/peerdeal_desktop`

Remaining gaps:
- Real native local-network discovery and production transport remain pending
  platform work. This slice locks the Dart app-boundary mapping and mounted
  route consumption only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Wizard Safe Compile Boundary

Summary:
Added a fail-closed `GameFileCompileResult` and `DefaultGameFileCompiler.tryCompile`
boundary so app/session setup flows can reject invalid or non-build-ready wizard
plans without compiler exceptions escaping orchestration. The existing strict
`compile` API remains for direct misuse detection.

Files changed:
- `packages/peerdeal_wizard/lib/src/models/game_file_compile_result.dart`
- `packages/peerdeal_wizard/lib/src/contracts/game_file_compiler.dart`
- `packages/peerdeal_wizard/lib/src/engine/default_game_file_compiler.dart`
- `packages/peerdeal_wizard/lib/peerdeal_wizard.dart`
- `packages/peerdeal_wizard/test/game_file_compiler_test.dart`
- `packages/peerdeal_wizard/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/REPO_BRIEF.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_wizard`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- App shells still mount demo-oriented setup/navigation surfaces; this slice
  only locks the wizard compile boundary for future app orchestration.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Sync Snapshot Persistence Integrity

Summary:
Hardened the sync recovery persistence seam so stored snapshots cannot regress
to an older checkpoint or replace an existing checkpoint at the same base event
sequence with a different snapshot hash. This protects verified recovery
anchors from stale or tampered snapshot writes while leaving durable platform
storage implementation as a separate gap.

Files changed:
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/test/recovery_persistence_store_test.dart`
- `packages/peerdeal_sync/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_sync`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- Durable platform persistence remains pending; this slice hardens the
  contract-level in-memory persistence gate.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Network Transport Frame Gate

Summary:
Added a `peerdeal_network` transport frame model and validator contract so
future LAN/relay transport implementations have a package-owned frame gate.
The validator fails closed on missing session/peer identities, self-send
frames, invalid sequences, empty payloads, and oversized payloads. This does
not implement live transport; it locks the transport boundary that live
adapters must satisfy.

Files changed:
- `packages/peerdeal_network/lib/peerdeal_network.dart`
- `packages/peerdeal_network/lib/src/contracts/transport_frame_validator.dart`
- `packages/peerdeal_network/lib/src/models/transport_frame.dart`
- `packages/peerdeal_network/lib/src/models/transport_frame_validation_result.dart`
- `packages/peerdeal_network/lib/src/services/basic_transport_frame_validator.dart`
- `packages/peerdeal_network/test/basic_transport_frame_validator_test.dart`
- `packages/peerdeal_network/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test` in `packages/peerdeal_network`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- Live peer transport remains pending; this slice only adds the deterministic
  transport frame gate.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Mounted Recovery Persistence Loading

Summary:
Wired the app-owned recovery persistence store factory into mounted table
routes in both app shells. The route now loads the active scenario recovery
window when the app supplies a platform/root-backed factory and fails closed
with an explicit warning when no platform persistence root is available.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`

Risks:
- Real platform root selection and production database/platform persistence
  remain pending; this locks mounted app loading of the existing durable store
  only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Shared App Shell UI Primitives

Summary:
Added shared Widgets-only app-shell primitives to `peerdeal_ui_kit` and moved
mobile/desktop mounted home and table routes onto the shared scaffold, action
button, status pill, and info row components. This reduces raw placeholder UI
without moving game truth or route orchestration into the UI kit.

Files changed:
- `packages/peerdeal_ui_kit/lib/peerdeal_ui_kit.dart`
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_action_button.dart`
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_app_scaffold.dart`
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_info_row.dart`
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_status_pill.dart`
- `packages/peerdeal_ui_kit/test/app_shell_widgets_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_mobile/lib/demo_slice/widgets/demo_status_banner.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_table_screen.dart`
- `apps/peerdeal_desktop/lib/demo_slice/widgets/demo_status_banner.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub` in `packages/peerdeal_ui_kit`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`

Risks:
- Final production UI polish still needs product/device validation; this locks
  reusable app-shell primitives and removes the raw placeholder route layout.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Local Network Peer Candidate Cap

Summary:
Mobile and desktop app local-network bootstrap paths now cap normalized native
peer discovery before candidate resolution. Mounted table loaders warn when
discovery exceeds the app candidate limit and fail closed when the configured
limit is invalid. Join bootstrap coordinators apply the same cap and fall back
to relay-only bootstrap when the limit is invalid, keeping noisy platform
discovery from flooding app/network bootstrap resolution.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_mobile/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_mobile/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_mobile/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_bootstrap_candidate_loader.dart`
- `apps/peerdeal_desktop/test/demo_slice/native_bootstrap_candidate_loader_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/native_join_bootstrap_coordinator.dart`
- `apps/peerdeal_desktop/test/join_flow/native_join_bootstrap_coordinator_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\native_bootstrap_candidate_loader_test.dart test\join_flow\native_join_bootstrap_coordinator_test.dart test\join_flow\join_flow_orchestrator_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\native_bootstrap_candidate_loader_test.dart test\join_flow\native_join_bootstrap_coordinator_test.dart test\join_flow\join_flow_orchestrator_test.dart` in `apps/peerdeal_desktop`

Risks:
- This bounds app intake of native discovery facts; it does not implement real
  platform local-network discovery.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Native Transport Payload Limit Guard

Summary:
Mobile and desktop `NativeTransportSessionFactory` now own an app payload
limit, feed it into the default `BasicTransportFrameValidator`, and fail closed
when native capability reports either a non-positive payload limit or a limit
larger than the app validator accepts. This prevents native capability facts
from advertising sends that the app/network validation boundary would later
reject.

Files changed:
- `apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_mobile/test/transport/native_transport_session_factory_test.dart`
- `apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart`
- `apps/peerdeal_desktop/test/transport/native_transport_session_factory_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\transport\native_transport_session_factory_test.dart test\transport\native_transport_frame_adapter_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\transport\native_transport_session_factory_test.dart test\transport\native_transport_frame_adapter_test.dart` in `apps/peerdeal_desktop`

Risks:
- This hardens app/native transport capability agreement; it is not a live peer
  transport implementation.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Environment Recovery Root

Summary:
Mobile and desktop app shells can now create their default
`AppRecoveryPersistenceStoreFactory` from `PEERDEAL_RECOVERY_ROOT`, while still
preferring explicit constructor injection. The factory trims configured paths,
returns no default factory for missing/blank configuration, and continues to
fail closed when root creation is unavailable or invalid. Mounted table routes
therefore have a deployable durable recovery-root configuration path without
moving platform/database policy into `peerdeal_sync`.

Files changed:
- `apps/peerdeal_mobile/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `apps/peerdeal_mobile/lib/demo_slice/README.md`
- `apps/peerdeal_desktop/lib/recovery/app_recovery_persistence_store_factory.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/recovery/app_recovery_persistence_store_factory_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\recovery\app_recovery_persistence_store_factory_test.dart test\app_shell_test.dart` in `apps/peerdeal_desktop`

Risks:
- This is a configurable file-store root, not a production database or native
  platform path-provider implementation.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Route Map Registry Validation

Summary:
Mounted app route maps in both app shells now pass through the app-owned
`DemoSliceRoutes.requireMountedRouteMap` invariant before `WidgetsApp` sees
them. The guard rejects missing mounted routes and unexpected extra routes while
allowing `/` only as an explicit framework default-route alias, reducing route
drift while production navigation remains app-shell owned.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\demo_slice_routes_test.dart test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\demo_slice_routes_test.dart test\app_shell_test.dart` in `apps/peerdeal_desktop`

Risks:
- This locks demo mounted-route coverage only; final production navigation and
  non-demo route replacement still need product validation.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Route Registry

Summary:
Added app-owned mounted route descriptors and primary-navigation definitions in
both app shells. Home navigation now derives labels and destinations from the
route registry instead of scattering route labels and paths through the UI, and
focused tests lock uniqueness, lookup, and primary navigation coverage.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_slice_routes_test.dart`
- `apps/peerdeal_desktop/lib/demo_slice/demo_slice_routes.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_home_screen.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_slice_routes_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\demo_slice\demo_slice_routes_test.dart test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\demo_slice\demo_slice_routes_test.dart test\app_shell_test.dart` in `apps/peerdeal_desktop`

Risks:
- This locks the current mounted route registry; final production navigation
  still needs product validation and non-demo route replacement.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Mounted Route UI Shell Coverage

Summary:
Moved the remaining mounted chat, receipt, join, setup, and unknown-route
surfaces in both app shells onto the shared `peerdeal_ui_kit` app-shell
primitives. This extends the prior home/table UI primitive adoption across the
demo route surface while preserving app-owned orchestration and exact
fail-closed result text.

Files changed:
- `packages/peerdeal_ui_kit/lib/src/app_shell/peer_deal_app_scaffold.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_chat_screen.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_mobile/lib/navigation/app_route_fallback_screen.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_chat_screen.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/lib/setup_flow/setup_flow_route.dart`
- `apps/peerdeal_desktop/lib/navigation/app_route_fallback_screen.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart test\demo_slice\demo_receipt_screen_test.dart test\join_flow\join_flow_route_test.dart test\setup_flow\setup_flow_route_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart test\demo_slice\demo_receipt_screen_test.dart test\join_flow\join_flow_route_test.dart test\setup_flow\setup_flow_route_test.dart` in `apps/peerdeal_desktop`

Risks:
- Final production UI validation still requires product/device review; this
  locks shared shell coverage for currently mounted route surfaces.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - Secure Key Storage Mutation Contract

Summary:
Extended the generic native secure key storage bridge with save/delete
method-channel contracts and fail-closed mutation results. The new mutation
interface is separate from the existing read-only bridge so app loaders and
test fakes do not need unused write methods. The contract remains
receipt-agnostic; platform implementations still own real OS storage.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_bridge.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_bridge_models.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_channel_contract.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/method_channel_secure_key_storage_bridge.dart`
- `packages/peerdeal_native_bridges/fixtures/secure_key_storage_bridge_contract.json`
- `packages/peerdeal_native_bridges/test/method_channel_secure_key_storage_bridge_test.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `packages/peerdeal_native_bridges/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub` in `packages/peerdeal_native_bridges`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- Real platform storage remains pending; this locks the generic Dart
  method-channel contract only.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App-Owned Join Factory Boundary

Summary:
Moved join-flow demo adapter construction out of mounted `JoinFlowRoute` and
behind app-owned orchestrator factories in both app shells. `JoinFlowRoute` now
requires an injected factory, and mounted app tests cover fail-closed behavior
when the app boundary cannot construct a join orchestrator.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_mobile/lib/join_flow/demo_join_flow_orchestrator_factory.dart`
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/test/join_flow/join_flow_route_test.dart`
- `apps/peerdeal_desktop/lib/join_flow/join_flow_route.dart`
- `apps/peerdeal_desktop/lib/join_flow/demo_join_flow_orchestrator_factory.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/join_flow/join_flow_route_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test/join_flow/join_flow_route_test.dart test/app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test/join_flow/join_flow_route_test.dart test/app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run dependency-audit`
- `git diff --check`
- `dart run melos run test`

Risks:
- The default factory still uses demo adapters until production invite,
  transport, disclosure, and governance implementations exist.

Next reviewer:
Codex should run the full local gate set and commit if green.

---

### 2026-06-08 - Codex - App Runtime Dependency Boundary

Summary:
Added app-owned runtime dependency objects for the mobile and desktop shells.
Mounted-route dependencies for receipt presentation/export/verification,
join/setup orchestration, native bootstrap loading, recovery persistence, and
table runtime scope can now be supplied as a single app-shell unit while the
existing per-factory constructor injection remains supported.

Files changed:
- `apps/peerdeal_mobile/lib/main.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_desktop/lib/main.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_mobile`
- `flutter test --no-pub test\app_shell_test.dart` in `apps/peerdeal_desktop`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- Final production navigation, platform native implementations, and product UI
  validation remain pending; this only locks the app-shell dependency boundary.

Next reviewer:
Codex should run focused app shell tests, then the full local gate set, and
commit if green.

---

### 2026-06-08 - Codex - Holdem Raise Sizing Semantics

Summary:
Hardened Hold'em action application so full opening bets and full raises update
the next legal minimum raise amount. Short all-ins that increase the amount to
call now preserve the prior minimum raise size and do not claim
last-aggressor/full-raise reopen semantics unless they meet the current
full-raise threshold.

Files changed:
- `packages/peerdeal_variants/lib/src/holdem/holdem_action_applier.dart`
- `packages/peerdeal_variants/test/holdem_action_applier_test.dart`
- `packages/peerdeal_variants/README.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- `dart test test\holdem_action_applier_test.dart` in
  `packages/peerdeal_variants`
- `dart run melos run analyze`
- `dart run melos run boundary-check`
- `dart run melos run source-text`
- `dart run melos run test`
- `dart run melos run dependency-audit`
- `git diff --check`

Risks:
- This hardens variant-local action semantics only; session/core event emission
  and platform app integration remain separate readiness work.

Next reviewer:
Codex should run the full local gate set and commit if green.
### T63: typed first-join session handoff

- Added mirrored `JoinFlowSessionContext` propagation for selected peer and
  assigned seat.
- Added context-aware app bootstrap/source loading and persisted-input mapping.
- Focused mobile and desktop join/session tests passed.
- Remaining: concrete product persistence/transport and Android/Windows runtime
  validation.

### T64: governance-bound rejoin session handoff

- Added optional app-owned `GovernanceCommitResult.assignedPeerId`.
- Accepted rejoin outcomes now build the typed session context from the
  governance-assigned peer and seat; first join remains bootstrap-selected.
- Missing governance peer data produces no production session handoff.
- Mirrored mobile and desktop orchestrator and route tests pass for accepted
  rejoin propagation and fail-closed missing-peer behavior.

Remaining:
- Concrete product source/database provisioning, native transport reachability,
  and runtime/device validation remain outside this local contract seam.

### T65: persisted production-session configuration

- Added mirrored async
  `AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(...)`.
- The factory composes native local identity provisioning, the existing JSON
  recovery store, persisted Hold'em source hydration, caller-owned route policy,
  and event factories into the validated bootstrap route.
- Focused mobile and desktop persisted-session suites passed with 8 tests each;
  both app analyzers passed.

Remaining:
- This closes app-owned recovery-backed composition only. Product database and
  state selection, native transport reachability, and runtime/device validation
  remain integration or operator work.

### T66: fail-early persisted-session configuration validation

- Mirrored `AppHoldemProductionSessionConfiguration` entry points now reject
  non-positive source-load timeouts before route assembly.
- The async persisted-identity factory validates before native local-identity
  provisioning, preventing invalid configuration from mutating secure-key
  storage.
- Focused mobile and desktop persisted-session suites passed with 9 tests each,
  including the no-secure-key-mutation regression.

Remaining:
- Product database/state provisioning, native transport reachability, and
  runtime/device validation remain integration or operator work.

### T74: native transport strict identity decoding

- Android native transport receive decoding now uses a reporting UTF-8
  decoder; malformed bytes and C1/control-bearing identity fields are dropped
  before frames enter the bounded queue.
- Windows native transport now validates identity fields with strict UTF-8
  conversion and matching whitespace/control checks before queueing received
  frames or sending datagrams.
- Both mirrored Android APK and Windows debug builds passed.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- transport/readiness/handoff records and READMEs

Remaining:
- Device/network reachability, firewall/multicast behavior, runtime host
  validation, other-platform hosts, release signing, and product persistence
  remain external or integration-owned.

### T73: transport polling cancellation propagation

- Mirrored `AppTableSessionTransportProvisioner` instances now observe route
  cancellation while awaiting injected session factories and fail closed with
  a stable unavailable warning.
- Mirrored `NativeTransportSessionFactory` and `NativeTransportSession` paths
  carry cancellation into `AppTableSessionTransportSource`.
- Transport sources race pending polls against route cancellation and source
  disposal. The visible wait cancels immediately, while the underlying drain
  remains registered until settlement to prevent overlapping native drains.

Files changed:
- mirrored `apps/peerdeal_mobile/lib/transport/` source, factory, and
  provisioner files
- mirrored `apps/peerdeal_desktop/lib/transport/` source, factory, and
  provisioner files
- mirrored transport source and provisioner tests
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`

Tests run:
- Focused mobile transport source/provisioner suite: passed, 14 tests.
- Focused desktop transport source/provisioner suite: passed, 14 tests.
- Focused mirrored app analysis passed before documentation edits.

Remaining:
- Native transport reachability and already-dispatched host-call semantics,
  runtime/device validation, release signing, other-platform hosts, and
  product database/state provisioning remain external or integration-owned.

### T72: receipt verification cancellation propagation

- Mirrored `NativeReceiptKeyRingLoader` implementations now expose additive
  `loadCancellable` capability and forward cancellation to cancellable native
  secure-key bridges while preserving the base loader path.
- Mirrored `DemoReceiptArtifactVerifier` and presenter paths propagate the
  cancellation signal into native-backed receipt verification.
- Mounted receipt routes complete the signal on replacement and disposal, so a
  pending native key load cannot outlive the route's Dart presentation owner.

Files changed:
- `apps/peerdeal_mobile/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_mobile/lib/demo_slice/controllers/demo_receipt_artifact_verifier.dart`
- `apps/peerdeal_mobile/lib/demo_slice/controllers/demo_receipt_surface_presenter.dart`
- `apps/peerdeal_mobile/lib/demo_slice/screens/demo_receipt_screen.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/native_receipt_key_ring_loader.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/demo_receipt_artifact_verifier.dart`
- `apps/peerdeal_desktop/lib/demo_slice/controllers/demo_receipt_surface_presenter.dart`
- `apps/peerdeal_desktop/lib/demo_slice/screens/demo_receipt_screen.dart`
- mirrored receipt loader, verifier, and route tests
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`

Tests run:
- Focused mobile receipt loader/verifier/factory/presenter/route suite: passed,
  39 tests including pending-route cancellation.
- Focused desktop receipt loader/verifier/factory/presenter/route suite:
  passed, 39 tests including pending-route cancellation.
- Focused `dart analyze apps/peerdeal_mobile apps/peerdeal_desktop`: passed.
- `git diff --check`: passed before documentation edits.

Remaining:
- Native host persistence and already-dispatched operation semantics, device or
  profile validation, release signing, other-platform storage, and product
  database/state provisioning remain external or integration-owned.

### T71: secure-storage cancellation propagation

- Added additive `CancellableSecureKeyStorageBridge` and mutation capability
  interfaces; the base secure-storage interfaces remain compatible.
- Generic method-channel load/save/delete calls now race the existing bounded
  deadline against caller cancellation and return stable unavailable/failure
  results when cancellation wins.
- Mirrored app local-identity loaders, writers, provisioners, and persisted
  Hold'em sources forward route cancellation through the capability.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_bridge.dart`
- `packages/peerdeal_native_bridges/lib/src/secure_storage/method_channel_secure_key_storage_bridge.dart`
- `packages/peerdeal_native_bridges/test/method_channel_secure_key_storage_bridge_test.dart`
- `apps/peerdeal_mobile/lib/session/native_local_peer_identity_loader.dart`
- `apps/peerdeal_mobile/lib/session/native_local_peer_identity_writer.dart`
- `apps/peerdeal_mobile/lib/session/native_local_peer_identity_provisioner.dart`
- `apps/peerdeal_mobile/lib/session/app_persisted_holdem_production_session_source.dart`
- `apps/peerdeal_desktop/lib/session/native_local_peer_identity_loader.dart`
- `apps/peerdeal_desktop/lib/session/native_local_peer_identity_writer.dart`
- `apps/peerdeal_desktop/lib/session/native_local_peer_identity_provisioner.dart`
- `apps/peerdeal_desktop/lib/session/app_persisted_holdem_production_session_source.dart`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `PROJECT_STATE.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused secure-storage method-channel suite: passed, 14 tests.
- Focused mobile identity and persisted-source suites: passed, 21 tests.
- Focused desktop identity and persisted-source suites: passed, 21 tests.
- `dart analyze packages/peerdeal_native_bridges apps/peerdeal_mobile apps/peerdeal_desktop`: passed.
- `git diff --check`: passed.

Remaining:
- Runtime Android/Windows key persistence, host mutation idempotency under
  cancellation, operator release signing, other-platform storage, product
  database/state provisioning, and native transport reachability remain
  integration or operator work.

### T69: persisted-source cancellation propagation

- Mirrored persisted invite and session-context loads now honor route
  cancellation before recovery access and around lazy identity provisioning.
- Cancelled loads fail closed with a stable `StateError`; focused mobile and
  desktop persisted-session suites passed with 13 tests each, including the
  pre-cancel no-secure-key-mutation regression.

Remaining:
- Product database/state provisioning, native transport reachability, and
  runtime/device validation remain integration or operator work.

### T70: bounded capture bridge calls

- Generic capture protection method-channel capability and blocking calls now
  use a bounded five-second default deadline.
- Timeout results are stable and fail closed; non-positive timeout configuration
  is rejected before a platform call.
- Mirrored app receipt tests inject the existing recording capture fake when no
  native platform channel is intentionally configured, avoiding fake-clock
  deadline residue while preserving real timeout coverage in the bridge suite.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/capture_protection/method_channel_capture_protection_bridge.dart`
- `packages/peerdeal_native_bridges/test/method_channel_capture_protection_bridge_test.dart`
- `apps/peerdeal_mobile/test/app_shell_test.dart`
- `apps/peerdeal_mobile/test/demo_slice/demo_receipt_screen_test.dart`
- `apps/peerdeal_desktop/test/app_shell_test.dart`
- `apps/peerdeal_desktop/test/demo_slice/demo_receipt_screen_test.dart`
- `HANDOFF.md`
- `HANDOFF_QUEUE.md`
- `docs/PRODUCTION_READINESS.md`
- `docs/ai/API_CONTRACTS.md`
- `docs/ai/ARCHITECTURE_MAP.md`
- `docs/ai/HANDOFF_LOG.md`

Tests run:
- Focused capture method-channel suite: passed, 9 tests.

Remaining:
- Runtime Android/Windows capture behavior, operator release signing, and
  other-platform capture implementations remain external.

### T68: lazy persisted-session identity provisioning

- Mirrored production configuration now composes
  `AppPersistedHoldemProductionSessionSource.fromLocalIdentityProvisioner(...)`.
- Invite-scoped snapshot validation and deterministic recovery replay complete
  before native local identity provisioning; missing or rejected recovery state
  cannot mutate secure-key storage.
- Focused mobile and desktop persisted-session suites passed with 12 tests each.

Remaining:
- Product database/state provisioning, native transport reachability, and
  runtime/device validation remain integration or operator work.

### T67: fail-early persisted route-policy validation

- Mirrored persisted Hold'em route policies now validate route path, navigation
  label, remote peer identity, and positive local seat before native local-peer
  identity provisioning.
- Invalid route policy fails with `ArgumentError`; focused mobile and desktop
  persisted-session suites passed with 10 tests each, including the regression
  proving secure-key storage is not mutated.

Remaining:
- Product database/state provisioning, native transport reachability, and
  runtime/device validation remain integration or operator work.

---

### 2026-08-10 - Codex - Local-Network Host Channel Registration

Summary:
- Registered the locked generic local-network method channel on the Android and
  Windows hosts.
- Added bounded active-interface availability and generic interface hints.
- Kept peer discovery fail-closed with an empty endpoint list because no
  discovery advertisement protocol or product endpoint-provisioning contract
  exists in the repository.

Files changed:
- Mirrored Android and Windows local-network host handlers and registration.
- Matching handoff, readiness, README, and AI context records.

Tests run:
- Android debug APK build: passed.
- Windows debug build: passed.

Risks:
- The hosts expose interface capability only. Protocol-owned peer discovery,
  endpoint provisioning, device/network reachability, and runtime validation
  remain open.

Next reviewer:
Continue with runtime Android/Windows validation or define the missing
protocol-owned discovery advertisement before populating `foundEndpoints`.

---

### 2026-08-11 - Codex - Capture Route Cancellation

Summary:
- Added additive cancellable capture capability and action interfaces without
  changing the existing base bridge contracts.
- Generic capture method-channel calls now race caller cancellation against
  their existing five-second deadline and fail closed with stable results.
- Mirrored receipt presenters and capture coordinators forward route
  cancellation; teardown release remains uncancelled so native blocking can be
  disabled.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/capture_protection/`
- Mirrored app capture coordinators, receipt presenters, receipt routes, and
  focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused native capture bridge suite: passed, 11 tests.
- Mirrored mobile and desktop capture coordinator suites: passed, 8 tests each.
- Mirrored mobile and desktop receipt presenter suites: passed, 4 tests each.

Risks:
- Already-dispatched native calls remain host-owned. Android/Windows runtime
  capture validation, release signing, other-platform hosts, and product
  database/state wiring remain external or integration-owned.

---

### 2026-08-11 - Codex - App-Support Directory Cancellation

Summary:
- Added an additive cancellable app-support directory bridge capability while
  preserving the existing base interface.
- Generic app-storage lookup now races a positive five-second deadline against
  caller cancellation and returns stable unavailable facts on either outcome.
- Mirrored recovery persistence factories forward cancellation to compatible
  bridges and fail closed without constructing a factory when lookup fails.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/app_storage/` and focused tests.
- Mirrored app recovery persistence factories and focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests run:
- Focused native app-storage bridge suite: passed, 7 tests.
- Mirrored mobile and desktop recovery-factory suites: passed, 13 tests each.

Risks:
- Already-dispatched native calls remain host-owned. Runtime persistence
  validation, product database/state provisioning, other-platform storage,
  and release/operator validation remain external or integration-owned.

---

### 2026-08-11 - Codex - Native Readiness Lifecycle Cancellation

Summary:
- Added additive per-call cancellation capabilities for generic local-network
  and native-transport capability calls without changing base interfaces.
- Mirrored app-native readiness loaders forward route cancellation to compatible
  capture, local-network, transport, and secure-key bridges.
- App states cancel stale readiness work when the loader changes and when the
  app state disposes; cancellation remains a stable fail-closed readiness fact.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/local_network/` and
  `packages/peerdeal_native_bridges/lib/src/transport/` plus focused tests.
- Mirrored app readiness loaders, app-state lifecycle code, and focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and compact AI context docs.

Tests run:
- Focused local-network bridge: passed, 11 tests.
- Focused native transport bridge: passed, 13 tests.
- Mirrored mobile and desktop readiness-loader suites: passed, 7 tests each.
- Analyze, boundary-check, source-text, dependency-audit, and full test gates:
  passed. Dependency audit reports zero actionable upgrades.

Risks:
- Already-dispatched native calls remain host-owned. Runtime/device readiness,
  network reachability, other-platform native implementations, release signing,
  and product database/state wiring remain external or integration-owned.

---

### 2026-08-11 - Codex - Native Host CI Build Gates

Summary:
- Added separate CI jobs for Android debug APK and Windows debug host
  compilation.
- Preserved the existing workspace quality gates and kept compile success
  distinct from release signing and runtime/device validation.

Files changed:
- `.github/workflows/ci.yml`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Tests and builds:
- Local `flutter build apk --debug --no-pub`: passed.
- Local `flutter build windows --no-pub`: passed.
- Full repository gates remain the required CI baseline.

Risks:
- CI host compilation does not prove physical-device persistence/capture,
  firewall or cross-device reachability, release signing, other-platform host
  implementations, or product database/state wiring.

---

### 2026-08-11 - Codex - Android Release Signing Guard CI Check

Summary:
- Added a credential-free expected-failure CI step for Android release builds.
- The step requires the existing Gradle guard to reject `assembleRelease`
  before artifact assembly when all four operator signing values are absent.

Files changed:
- `.github/workflows/ci.yml`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Local credential-free release build failed at `build.gradle.kts:49` with the
  explicit `PEERDEAL_ANDROID_*` signing requirement.
- The check does not consume or expose operator credentials.

Risks:
- This is a negative signing guard only. A successful signed release,
  operator credential validation, and device/profile validation remain
  external.

---

### 2026-08-11 - Codex - Exact Android Signing Guard Assertion

Summary:
- Explicitly blanked all four Android signing variables in the CI negative
  test.
- Required the exact Gradle signing diagnostic after the expected nonzero
  release-build result, preventing arbitrary failures from passing the check.

Files changed:
- `.github/workflows/ci.yml`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Local credential-free release build still produced the expected Gradle
  signing diagnostic and failed before artifact assembly.
- Workflow YAML parses successfully.

Risks:
- This remains a negative guard only; signed release, operator credential,
  profile, and device validation remain external.

---

### 2026-08-11 - Codex - Mounted Join-Flow Cancellation Propagation

Summary:
- Added mirrored route-owned cancellation on join outcome replacement and
  disposal.
- Added pre-commit cancellation checks to first-join and rejoin orchestration,
  preventing cancelled bootstrap work from reaching governance.
- Forwarded cancellation through native join bootstrap to cancellable local
  network bridges without changing legacy bridge contracts.

Files changed:
- `apps/peerdeal_mobile/lib/join_flow/*` and mirrored desktop join-flow files.
- Mirrored join-flow route, orchestrator, and native bootstrap tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Focused mobile and desktop join-flow tests passed, including route disposal,
  cancellation forwarding, and governance protection.

Risks:
- Already-dispatched adapter or governance calls remain owner-hosted; native
  runtime/device validation and signed release validation remain external.

---

### 2026-08-11 - Codex - Receipt Key Provisioning Single-Flight

Summary:
- Mirrored app receipt key-ring provisioners now share one in-flight
  `ensureActiveKeys()` operation across concurrent callers.
- This prevents duplicate active-key generation and divergent in-memory key
  rings while preserving retry behavior after completion.

Files changed:
- Mirrored `native_receipt_key_ring_provisioner.dart` implementations and
  focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Mobile and desktop focused provisioner suites passed.
- Workspace analyze passed.

Risks:
- Cross-process/native storage atomicity, runtime/device persistence,
  operator-owned release signing, and product database/state wiring remain
  external or integration-owned.

---

### 2026-08-28 - Codex - Fixture and Contract Gates

Summary:
- T323 added native transport bound parity checks across the canonical Dart
  limits and Android/Windows host declarations.
- T324 added generic rejection coverage for every `invalid_` and
  `unsupported_` protocol fixture through its catalog/schema family.
- T325 updated the existing Hold'em opening-hand fixture to the current strict
  persisted-state shape and added a test that loads it through
  `HoldemHandState.fromJson`.

Files changed:
- `scripts/check_native_contract_bounds.py`, CI wiring, and native transport
  contract tests for T323.
- `packages/peerdeal_protocol/test/peerdeal_protocol_test.dart` for T324.
- `packages/peerdeal_variants/test/fixtures/holdem_opening_hand.json` and
  `packages/peerdeal_variants/test/holdem_hand_state_persistence_test.dart`
  for T325.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and this stable AI handoff log.

Verification:
- Direct `peerdeal_variants` analysis passed.
- Fixture JSON parsing passed.
- The focused Flutter test runner stalled without output and was stopped;
  no test failure was emitted. Full repository gates remain required.

Risks:
- Full variant fixture breadth, native/device runtime validation, production
  persistence, and product session wiring remain separate gates.

---

### 2026-08-28 - Codex - Hold'em Fixture Breadth Gate

Summary:
- Added a valid all-in/five-card Hold'em persistence edge fixture.
- Added invalid duplicate-seat and negative-stack fixtures.
- Added a generic test requiring every `invalid_` Hold'em fixture to be
  rejected by `HoldemHandState.fromJson`.

Files changed:
- `packages/peerdeal_variants/test/fixtures/holdem_all_in_edge.json`
- `packages/peerdeal_variants/test/fixtures/invalid_holdem_duplicate_seat.json`
- `packages/peerdeal_variants/test/fixtures/invalid_holdem_negative_stack.json`
- `packages/peerdeal_variants/test/holdem_hand_state_persistence_test.dart`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and this stable AI handoff log.

Verification:
- Direct `peerdeal_variants` analysis passed.
- Fixture JSON inventory and source-text checks passed.
- Focused Dart test execution stalled without output in the local runner;
  no test failure was emitted.

Risks:
- Full gameplay fixture breadth, native/device runtime validation, production
  persistence, and product session wiring remain separate gates.

---

### 2026-08-28 - Codex - Mode Fixture Breadth Gate

Summary:
- Added an invalid duplicate-participant governance fixture.
- Added a directory-driven test that sends every mode JSON fixture through the
  existing governance policy engine and requires invalid contexts to fail with
  `ERR_GOVERNANCE_CONTEXT_INVALID`.

Files changed:
- `packages/peerdeal_modes/test/fixtures/invalid_duplicate_participant.json`
- `packages/peerdeal_modes/test/governance_engine_test.dart`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and this stable AI handoff log.

Verification:
- Direct `peerdeal_modes` analysis passed.
- Dart focused test startup stalled without output and was stopped; no test
  failure was emitted. Deterministic repository checks remain required.

Risks:
- This closes local mode-fixture coverage only. Native/device validation,
  production persistence, product session wiring, release signing, and final
  UX validation remain separate gates.

---

### 2026-08-28 - Codex - Replay Fixture Breadth Gate

Summary:
- Added hand-scoped, snapshot-plus-suffix, anchor-mismatch, and
  protocol-mismatch replay fixtures.
- Added a typed test-only fixture decoder for replay requests, snapshots, and
  expected anchors.
- Added a directory-driven test requiring every replay JSON fixture to decode
  before the scenario assertions run.

Files changed:
- `packages/peerdeal_replay/test/fixture_loader.dart`
- `packages/peerdeal_replay/test/basic_replay_engine_test.dart`
- `packages/peerdeal_replay/test/fixtures/basic_session_replay.json`
- `packages/peerdeal_replay/test/fixtures/hand_scoped_replay.json`
- `packages/peerdeal_replay/test/fixtures/snapshot_suffix_replay.json`
- `packages/peerdeal_replay/test/fixtures/anchor_mismatch_replay.json`
- `packages/peerdeal_replay/test/fixtures/protocol_mismatch_replay.json`
- `packages/peerdeal_replay/test/fixtures/starter_fixture_notes.md`
- `packages/peerdeal_replay/README.md`, `HANDOFF.md`, `HANDOFF_QUEUE.md`,
  `PROJECT_STATE.md`, `docs/PRODUCTION_READINESS.md`, and this log.

Verification:
- Direct `peerdeal_replay` analysis passed.
- Replay fixture JSON parsing passed.
- Focused replay Dart test startup stalled without output and was stopped; no
  test failure was emitted.

Risks:
- This closes the documented local replay-fixture gap only. Product projectors,
  durable persistence, native/device validation, and release operations remain
  separate gates.

---

### 2026-08-28 - Codex - T318 Production Route Failure Surface

Summary:
- Mirrored `AppHoldemTableSessionRoute` owners now keep injected production
  surface-builder failures inside the shared app-shell scaffold/status state.
- The fallback exposes bounded unavailable state/action text and never projects
  the caught exception into the UI.

Files changed:
- Mirrored app route files and focused route tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Verification:
- Focused mobile route suite: 14 tests passed.
- Focused desktop route suite: 14 tests passed.
- Mobile and desktop analyzers, boundary check, source-text check, formatting,
  and `git diff --check` passed.

Risks:
- Final visual/device and non-demo product-flow validation remain separate
  external gates; this change does not alter session, transport, or game truth.

---

### 2026-08-28 - Codex - T319 Production Table Operational UI Hierarchy

Summary:
- Mirrored production Hold'em surfaces now group bounded runtime data into
  Session, Table state, Seats, Connection, and Controls sections.
- Repeated seat rows retain existing safe values and semantics while visually
  distinguishing the configured local and current acting seats.

Files changed:
- Mirrored production table surface files and route tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Focused mobile and desktop route suites remain the required local evidence;
  final visual/device and non-demo product-flow validation remain external.

Risks:
- No game truth, transport, persistence, or package ownership moved into UI.

---

### 2026-08-28 - Codex - T320 Transport Replay-Scope Admission Serialization

Summary:
- `ValidatingTransportFrameReceiver` now serializes unrecorded replay-scope
  admission and per-scope receive lifecycles before handler dispatch and replay
  recording.
- Concurrent first frames cannot invoke a handler before a bounded replay
  scope-limit record can fail. Handler failures still leave frames retryable.

Files changed:
- `packages/peerdeal_network/lib/src/services/validating_transport_frame_receiver.dart`
- `packages/peerdeal_network/test/validating_transport_frame_receiver_test.dart`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Focused receiver suite: passed, 6 tests.
- Full `peerdeal_network` package suite: passed, 74 tests.
- Package analysis: passed.

Risks:
- Device/network reachability, product transport wiring, runtime validation,
  release signing, and durable product persistence remain separate gates.

---

### 2026-08-28 - Codex - T321 Cross-Platform Transport Sequence Bounds

Summary:
- Generic native transport models and channel decoding now reject sequence IDs
  above the shared signed 32-bit maximum required by Android and the native wire
  envelope.
- Windows host argument and wire decoding now apply the same ceiling instead of
  accepting its broader unsigned 32-bit range.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/native_bridge_payload_limits.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_bridge_models.dart`
- `packages/peerdeal_native_bridges/lib/src/transport/native_transport_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `packages/peerdeal_native_bridges/test/method_channel_native_transport_bridge_test.dart`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Native bridge package analysis: passed.
- Boundary, source-text, formatting, and diff checks: passed.
- Flutter widget tests and Windows native build were not runnable because the
  local Flutter command wrapper stalled before launching its test/build child.

Risks:
- Device/network reachability, cross-device runtime validation, release
  signing, and product transport wiring remain separate gates.

---

### 2026-08-28 - Codex - T322 Cross-Platform Transport Payload Bounds

Summary:
- The shared native transport payload ceiling is now 60 KiB, matching the
  Android and Windows host implementations and their private wire envelope.
- A contract test locks the common ceiling so oversized payloads fail closed
  before native dispatch.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/native_bridge_payload_limits.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Native bridge package analysis: passed.
- Boundary, source-text, formatting, and diff checks: passed.
- Flutter widget and native runtime/build validation remain unavailable in the
  local command environment.

Risks:
- Device/network reachability, cross-device runtime validation, release
  signing, and product transport wiring remain separate gates.

---

### 2026-08-20 - Codex - T294 Source-Backed Production Hardening

Summary:
- Fixed the Android native transport encoder's under-sized variable-length
  buffer allocation.
- Receipt view authorization now enforces session and user bindings; mixed
  receipts enforce both bindings.
- Governance administrative actions now require existing host/cohost
  authority, while seat acceptance is bound to the subject participant and
  self-service waitlist/away/return actions cannot be forged by another ID.
- Button-relative odd-chip settlement now fails closed because the existing
  core API has no button position input; the deterministic default remains
  unchanged.
- Diagnostics redaction now covers common credential field names.
- Refreshed the workspace lockfile's two currently resolvable transitive
  upgrades: `source_maps` and `vm_service`.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `packages/peerdeal_receipts/lib/src/services/default_receipt_authorizer.dart`
- `packages/peerdeal_receipts/test/default_receipt_authorizer_test.dart`
- `packages/peerdeal_modes/lib/src/governance/default_governance_engine.dart`
- `packages/peerdeal_modes/test/governance_engine_test.dart`
- `packages/peerdeal_core/lib/src/pot/pot_engine.dart`
- `packages/peerdeal_core/test/pot/pot_engine_test.dart`
- `packages/peerdeal_privacy/lib/src/services/default_diagnostics_scrubber.dart`
- `packages/peerdeal_privacy/test/default_diagnostics_scrubber_test.dart`
- `pubspec.lock`, `docs/PRODUCTION_READINESS.md`, and this handoff log.

Verification:
- Focused receipt, governance, core settlement, and privacy suites passed.
- Full analyze, boundary-check, source-text, serialized Dart/Flutter test,
  dependency-audit, and diff-check gates pass.
- Android debug APK build passed.
- Windows debug native smoke host build passed, and the smoke script passed
  app-storage, capture, local-network, transport, secure-key, and cleanup
  checks including secure-key read-back and conditional mutation.

Architecture status:
- No new package, schema, route, native channel, or persistence boundary was
  added. Existing locked ownership and fail-closed behavior were preserved.

Remaining:
- Real Android secure-key/capture and Android/Windows cross-device multicast
  validation; operator release signing; other-platform native
  implementations; concrete product database/auth/local identity/state
  wiring; and final product UX remain integration, operator, or device-owned
  work.

---

### 2026-08-20 - Codex - T295 Generic Event Content Integrity

Summary:
- Added the protocol-owned canonical event hash payload map and SHA-256
  calculator. The map covers every event envelope field except `event_hash`.
- `CoreReducer`, replay event-window validation, direct sync conflict and
  snapshot validation, and recovery persistence now reject content-hash
  mismatches before projection or mutation.
- Hold'em cursor hashing now reuses the protocol canonical field map. Existing
  calculator seams remain available for documented variant hash policies.
- Legacy placeholder-hash tests now pass an explicit test-only calculator;
  production defaults remain strict.

Files changed:
- `packages/peerdeal_protocol/lib/src/hashing/event_hash.dart`
- `packages/peerdeal_protocol/lib/peerdeal_protocol.dart`
- `packages/peerdeal_core/lib/src/reducer/core_reducer.dart`
- `packages/peerdeal_replay/lib/src/engine/event_window_validator.dart`
- `packages/peerdeal_sync/lib/src/engine/basic_conflict_detector.dart`
- `packages/peerdeal_sync/lib/src/engine/basic_snapshot_applier.dart`
- `packages/peerdeal_sync/lib/src/engine/in_memory_recovery_persistence_store.dart`
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
- `packages/peerdeal_variants/lib/src/holdem/holdem_core_projection_adapter.dart`
- Focused package regression tests, package READMEs, and readiness docs.

Verification:
- Protocol, core, replay, sync, and variants package suites pass.
- New protocol, core, replay, and sync tamper regressions pass.
- Full repository analyze, boundary, source-text, test, dependency, and
  diff-check gates remain required before commit.

Architecture status:
- No package, schema, route, native channel, or persistence boundary was
  added. Hash policy remains protocol-owned by default and variant-injectable
  at existing package seams.

Remaining:
- Real device/native validation, cross-device multicast reachability, release
  signing, product-owned auth/database/local-identity/state wiring, and final
  product UX remain external or integration-owned gates.

---

### 2026-08-18 - Codex - Secure-Key Mutation Contradiction Guard

Summary:
- `SecureKeyStorageChannelContract` now rejects native mutation payloads that
  claim both success and compare-and-set conflict.
- This keeps app-owned receipt and local-identity writers from treating an
  uncommitted native mutation as committed.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused native bridge contract suite passed.
- Full repository gates are running after this handoff update.

Risks:
- Native device persistence, Android/Windows cross-device validation,
  operator-owned release signing, other-platform hosts, product state/database
  wiring, and session authentication remain separate gates.

---

### 2026-08-12 - Codex - Secure-Key Snapshot Integrity

Summary:
- The shared secure-key method-channel decoder now fails closed when a native
  snapshot contains malformed records or duplicate key IDs.
- Invalid records are no longer silently discarded, preventing partial key-ring
  state from reaching receipt provisioning or verification.

Files changed:
- `packages/peerdeal_native_bridges/lib/src/secure_storage/secure_key_storage_channel_contract.dart`
- `packages/peerdeal_native_bridges/test/native_bridge_channel_contract_test.dart`
- `docs/PRODUCTION_READINESS.md`

Verification:
- Focused `peerdeal_native_bridges` channel-contract suite: passed.
- Full repository gates remain required before commit.


---

### 2026-08-11 - Codex - T105 Native Transport Interface Enumeration Bounds

Summary:
- Android transport interface selection now caps interfaces at 64 and each
  interface-address scan at 256 entries.
- Windows transport interface selection rejects adapter buffers above 1 MiB and
  caps adapters at 64 and unicast-address scans at 256 entries.
- Android and Windows debug builds passed; direct Windows native-host smoke
  passed all channel checks.

Risks:
- Device behavior, cross-device network reachability, other-platform hosts,
  product persistence, and release signing remain separate.

---

### 2026-08-11 - Codex - T104 Native Local-Network Enumeration Bounds

Summary:
- Android local-network enumeration now caps interfaces at 64 entries.
- Windows rejects adapter address buffers above 1 MiB, caps adapters at 64, and
  caps each unicast-address scan at 256 entries.
- Android and Windows debug host builds passed; direct Windows native-host
  smoke passed all channel checks.

Risks:
- Device behavior, cross-device network reachability, other-platform hosts,
  product persistence, and release signing remain separate.

---

### 2026-08-11 - Codex - T103 Generic App Storage and Capture Payload Bounds

Summary:
- Capped generic app-storage directory paths at 4096 UTF-8 bytes.
- Capped generic capture capability/action notes and warnings at 512 UTF-8
  bytes before app orchestration receives them.
- Added regression coverage for oversized paths and capture diagnostics.

Validation:
- Focused Flutter native-bridge suite passed: 41 tests.
- Package analysis passed.

Risks:
- Native host/device behavior, cross-device network reachability, product
  persistence, and release signing remain separate validation surfaces.

---

### 2026-08-11 - Codex - T102 Generic Native Bridge Payload Bounds

Summary:
- Added shared `NativeBridgePayloadLimits` for generic method-channel
  transport, discovery, secure-key, and diagnostic values.
- Bounded platform-provided collections before iteration and bounded strings
  and byte payloads before generic model construction.
- Added regression coverage for oversized frame batches/payloads, discovery
  collections, secure-key records, and secure-key fields.

Validation:
- Focused Flutter native-bridge suite passed: 61 tests.
- Package analysis passed.

Risks:
- Native host/device behavior, cross-device network reachability, product
  persistence, and release signing remain separate validation surfaces.

---

### 2026-08-11 - Codex - T101 Recovery File Size Bounds

Summary:
- Added a positive configurable file-size cap to
  `JsonFileRecoveryPersistenceStore`, defaulting to 4 MiB.
- Oversized durable recovery files are rejected before JSON decoding, and
  oversized canonical windows are rejected before temporary-file replacement.
- Both paths return `ERR_RECOVERY_PERSISTENCE_FILE_TOO_LARGE` without hydrating
  or writing the oversized state.

Files changed:
- `packages/peerdeal_sync/lib/src/engine/json_file_recovery_persistence_store.dart`
  and its focused persistence tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Tests run:
- Focused recovery persistence suite: 21 tests passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Dependency audit reports zero actionable upgrades and 11 newer versions below
  the current toolchain ceiling.

Risks:
- This bounds the JSON recovery fallback only. Production database replacement,
  platform filesystem/runtime validation, product startup, and release signing
  remain separate boundaries.

Next reviewer:
- Preserve the file cap when adding recovery-window writers and keep database
  selection outside `peerdeal_sync`.

---

### 2026-08-11 - Codex - T100 Receipt Processing Bounds

Summary:
- Added the shared `ReceiptExportLimits` contract to `peerdeal_receipts`.
- Opaque export encoding and inspection now bound encoded bodies, decoded
  bodies, and payloads before base64 or JSON work.
- The HMAC receipt cipher now bounds plaintext, ciphertext, and nonce sizes
  before keystream work and fails closed for oversized input.

Files changed:
- `packages/peerdeal_receipts/lib/src/models/receipt_export_limits.dart` and
  the receipt package barrel.
- Opaque export encoder/decoder, HMAC cipher, and focused regression tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Tests run:
- Focused receipt export and cipher suite: 24 tests passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.
- Dependency audit reports zero actionable upgrades and 11 newer versions below
  the current toolchain ceiling.

Risks:
- This bounds Dart-side receipt processing only. Native key storage,
  device/network validation, product persistence, and release signing remain
  separate external boundaries.

Next reviewer:
- Preserve the shared limits when adding future receipt formats or native
  adapters; do not move receipt semantics into generic native bridges.

---

### 2026-08-11 - Codex - T99 Identity Single-Flight Cleanup Race

Summary:
- Mirrored local-peer identity provisioners now share only non-cancellable
  operations and clear in-flight state only when the exact tracked Future
  completes.
- This prevents a completed cancellable operation from clearing a newer shared
  operation while preserving cancellation propagation into native secure-key
  calls.

Files changed:
- Mirrored local identity provisioners and focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Mobile and desktop focused identity suites passed.
- Full repository gates remain the release check for this change.

Risks:
- Cross-process/native/device persistence validation and release signing remain
  external; no cross-process lock is claimed by the app-level single-flight.

---

### 2026-08-11 - Codex - Persistence Checkpoint Preflight

Summary:
- Mirrored app persistence writers now preflight snapshot identity, snapshot
  metadata, scope/cursor/hash consistency, and typed Hold'em state before
  appending an event suffix.
- Invalid checkpoint input cannot leave a durable event suffix behind, while
  genuine checkpoint storage failures retain the intentional durable-suffix
  replay behavior.

Files changed:
- Mirrored app `AppHoldemProductionSessionSnapshotWriter` and
  `AppHoldemProductionSessionPersistenceWriter` implementations.
- Mirrored persistence-writer regression tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Verification:
- Focused mobile and desktop persistence-writer suites: passed, 6 tests each.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates: passed.

Risks:
- Product state selection, event/snapshot identity, durable database wiring,
  native/device validation, cross-device reachability, and release signing
  remain external or integration-owned.

---

### 2026-08-11 - Codex - Windows Native Host Smoke CI Enforcement

Summary:
- Added a bounded PowerShell runner beside the existing Windows native host
  smoke target.
- CI now builds and executes that target, requires its stable pass marker, and
  fails closed on nonzero exit or timeout.

Files changed:
- `.github/workflows/ci.yml`
- `apps/peerdeal_desktop/tool/run_windows_native_host_smoke.ps1`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Windows smoke target rebuilt successfully.
- Bounded local runner passed all app-storage, capture, local-network,
  transport, and secure-key checkpoints.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed.

Risks:
- Firewall behavior, Android runtime/device validation, release signing,
  cross-device reachability, other-platform implementations, and product
  database/session-state wiring remain external or integration-owned.

---

### 2026-08-11 - Codex - Native Transport Send Contract Alignment

Summary:
- Fixed the Android and Windows native transport handlers to unwrap the nested
  `frame` map emitted by the locked Dart `sendFrame` channel contract.
- Windows now selects an operational IPv4 multicast interface by adapter metric
  and uses it for multicast membership and outbound sends.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp`
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, `docs/ai/API_CONTRACTS.md`, and
  `docs/ai/ARCHITECTURE_MAP.md`.

Verification:
- Direct Windows native host smoke passed transport capability/send/receive,
  secure-key CAS/tombstone checks, capture lifecycle, and app/local-network
  checks with exit code 0.
- Android debug APK compilation passed.

Risks:
- Android device runtime, cross-device multicast reachability, release signing,
  other-platform native implementations, and product database/session-state
  wiring remain external or integration-owned.

---

### 2026-08-11 - Codex - Android Multicast Interface Selection

Summary:
- Android native transport now chooses an operational non-loopback IPv4
  multicast interface, preferring Wi-Fi/Ethernet deterministically.
- The selected interface is applied to outbound multicast sockets and the
  receiver; missing usable interfaces fail closed.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, `docs/ai/API_CONTRACTS.md`, and
  `docs/ai/ARCHITECTURE_MAP.md`.

Verification:
- Android debug APK compilation passed.
- No Android device or emulator was attached for runtime validation.

Risks:
- Android runtime persistence/capture, cross-device multicast reachability,
  release signing, other-platform native implementations, and product
  database/session-state wiring remain external or integration-owned.

---

### 2026-08-11 - Codex - Secure-Key Revision Compare-and-Swap

Summary:
- Added additive namespace revisions to generic secure-key snapshots and
  conditional save/delete method-channel operations with explicit conflicts.
- Mirrored receipt key-ring and local-identity provisioners now pass expected
  revisions, refresh after conflicts, and fail closed when no valid competing
  record is available.
- Android encrypted file envelopes and Windows Credential Manager v2 envelopes
  persist revisions, including empty-namespace tombstones, while legacy formats
  remain readable with revision zero.

Files changed:
- Generic secure-key bridge contracts, models, channel bridge, and focused tests.
- Mirrored mobile and desktop receipt/identity adapters and tests.
- Android `SecureKeyStorageHandler` and Windows secure-key host.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Verification:
- Focused bridge and mirrored identity tests passed.
- Android debug APK and Windows debug host builds passed.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed. Dependency audit
  reports zero actionable upgrades and 11 newer versions below the current
  toolchain ceiling.

Risks:
- Runtime/device persistence and capture validation, other-platform native
  implementations, operator-owned release signing, and concrete product
  database/state wiring remain external or integration-owned.

---

### 2026-08-11 - Codex - Windows Native Host Runtime Smoke

Summary:
- Added a dependency-free `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart`
  target using the existing public native bridge contracts.
- Direct execution of the built Windows runner passed app storage, capture
  capability/enable/release, local-network capability/discovery, transport
  capability/receive, and secure-key save/read-back/CAS/conditional-delete
  checks.
- UDP multicast send returned the host's stable send failure and is retained as
  a network/firewall validation warning.

Files changed:
- `apps/peerdeal_desktop/tool/windows_native_host_smoke.dart` and desktop README.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Verification:
- `flutter build windows --debug --no-pub -t tool/windows_native_host_smoke.dart`:
  passed.
- Direct built executable smoke run: passed all required channel checkpoints;
  multicast send emitted the documented warning.
- Full analyze, boundary-check, source-text, serialized test,
  dependency-audit, and `git diff --check` gates passed. Dependency audit
  reports zero actionable upgrades and 11 newer versions below the current
  toolchain ceiling.

Risks:
- Android device/emulator runtime validation, Windows multicast reachability,
  firewall/profile validation, other-platform native implementations,
  operator-owned release signing, and product database/state wiring remain
  external or integration-owned.

---

### 2026-08-11 - Codex - Android Secure-Key Process Serialization

Summary:
- Added a hash-named private file lock under Android `noBackupFilesDir` for
  generic secure-key load/save/delete operations.
- Moved the encrypted envelope to a private file with flushed/synced temporary
  replacement and migrate legacy preference records under the same lock.
- Bounded `tryLock` retries to five seconds and fail closed on lock failure,
  preserving the encrypted storage and method-channel contracts.

Files changed:
- `apps/peerdeal_mobile/android/app/src/main/kotlin/com/peerdeal/peerdeal_mobile/SecureKeyStorageHandler.kt`
- Android README plus T87 handoff/readiness and stable AI context docs.

Verification:
- `flutter build apk --debug --no-pub`: passed.
- Full Dart/Flutter repository gates: passed.

Risks:
- This closes the PeerDeal Android host read-modify-write race but does not
  add compare-and-swap/version semantics or prove runtime/device, signing, or
  product persistence behavior.

---

### 2026-08-11 - Codex - Windows Secure-Key Process Serialization

Summary:
- Added a per-namespace Local named mutex to the Windows secure-key host.
- Load, save, and delete now serialize PeerDeal process access and fail closed
  after a bounded five-second lock wait.

Files changed:
- `apps/peerdeal_desktop/windows/runner/windows_secure_key_storage.cpp`
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Verification:
- `flutter build windows --no-pub`: passed.
- Full Dart/Flutter repository gates remain required after the documentation
  update.

Risks:
- This closes the PeerDeal Windows host read-modify-write race but does not
  add compare-and-swap/version semantics or prove Android multi-process,
  runtime/device, signing, or product persistence behavior.

---

### 2026-08-11 - Codex - Mounted Receipt Export Cancellation

Summary:
- Added an additive cancellable receipt export callback through both app-shell
  runtime configurations and mounted receipt routes.
- Forwarded route teardown cancellation through app key provisioning, secure
  key writes, and cancellable native secure-storage capabilities.
- Preserved the legacy one-argument export callback and failed closed on
  conflicting export sources.

Files changed:
- Mirrored app receipt export factories, key-ring writers/provisioners, receipt
  routes, app runtimes, and focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`,
  `docs/PRODUCTION_READINESS.md`, and stable AI context docs.

Verification:
- Focused mobile and desktop receipt writer/provisioner/export/route suites:
  passed.
- Full analyze, boundary-check, source-text, test, dependency-audit, and
  `git diff --check` gates: passed.

Risks:
- Already-dispatched native mutations remain host-owned. Android/Windows
  runtime validation, release signing, other-platform storage, and product
  database/state wiring remain external or integration-owned.

---

### 2026-08-11 - Codex - Receipt Key Persistence Read-Back Verification

Summary:
- Mirrored receipt key-ring provisioners now reload native storage after
  successful creation of any missing active key.
- Provisioning fails closed with an empty key ring unless the persisted active
  signing and encryption key IDs and secrets match the provisioned ring.

Files changed:
- Mirrored `native_receipt_key_ring_provisioner.dart` implementations and
  focused tests.
- `HANDOFF.md`, `HANDOFF_QUEUE.md`, `PROJECT_STATE.md`, and
  `docs/PRODUCTION_READINESS.md`.

Verification:
- Mobile and desktop focused provisioner suites passed.
- Workspace analyze passed.

Risks:
- Cross-process/native storage atomicity, runtime/device persistence,
  operator-owned release signing, and product database/state wiring remain
  external or integration-owned.

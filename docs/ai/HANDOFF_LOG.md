# Handoff Log

Use this for concise agent handoffs only.

## Format

### YYYY-MM-DD - Agent - Task

Summary:
Files changed:
Tests run:
Risks:
Next reviewer:

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

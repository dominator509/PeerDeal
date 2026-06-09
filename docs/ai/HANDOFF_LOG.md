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

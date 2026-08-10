# Handoff Queue

Generated: 2026-08-09
Branch: `retrofit/baseline-v1`
Backup tag: `pre-retrofit-20260613T075234Z`

## Queue

| ID | Source | Category | Tier | Status | Resolution / Blocker |
| --- | --- | --- | --- | --- | --- |
| `LEGACY-GAP-2026-06-13-001` | `REPO_INVENTORY.md` | 2 | T1 | RESOLVED | Added repository inventory and package boundary map. |
| `LEGACY-GAP-2026-06-13-002` | `HANDOFF_QUEUE.md` | 5 | T1 | RESOLVED | Added stable queue for retrofit gaps and deferred production blockers. |
| `LEGACY-GAP-2026-06-13-003` | `PROJECT_STATE.md` | 2 | T1 | RESOLVED | Added current tier, branch, tag, and required gates. |
| `LEGACY-GAP-2026-06-13-004` | `HANDOFF.md` | 5 | T1 | RESOLVED | Added current handoff snapshot for Codex/Claude continuity. |
| `LEGACY-GAP-2026-06-13-005` | `DECISIONS.log` | 5 | T1 | RESOLVED | Added immutable decision trail for this retrofit baseline. |
| `LEGACY-GAP-2026-06-13-006` | `.github/workflows/ci.yml` | 8 | T4 | RESOLVED | CI now activates Melos 8.2.2, matching the workspace dependency and lockfile. |
| `LEGACY-GAP-2026-06-13-007` | `docs/PRODUCTION_READINESS.md` | 4 | T4 | DEFERRED | Remaining native work is other-platform capture, local-network discovery, live peer transport, production database persistence, runtime key/capture validation, and other-platform storage; JSON recovery wipe, app retention coordination, exactly-once per-session close seams, protocol-event adapters, mirrored app session-runtime owners, canonical event-byte decoding, app frame-to-runtime handlers, bounded app source scheduling, route lifecycle source mounting, the app transport provisioner, and Android/Windows app-private recovery-root selection are implemented. Native peer transport implementation, platform source provisioning, database persistence, and other-platform storage remain open. |
| `LEGACY-GAP-2026-06-13-008` | `docs/PRODUCTION_READINESS.md` | 4 | T4 | DEFERRED | Final production UI validation and non-demo product flow validation remain future work. |
| `LEGACY-GAP-2026-08-09-009` | `apps/peerdeal_mobile/android/` | 4 | T4 | RESOLVED | Added the Android host, generic Keystore-backed secure-key implementation, and fail-closed release-signing configuration behind the existing channel contract. |
| `LEGACY-GAP-2026-08-09-010` | `apps/peerdeal_desktop/windows/` | 4 | T4 | RESOLVED | Added the Windows host, generic Credential Manager-backed secure-key implementation, bounded versioned record envelope, and locked channel registration; runtime profile persistence validation remains explicit. |
| `LEGACY-GAP-2026-08-09-011` | `apps/peerdeal_mobile/android/`, `apps/peerdeal_desktop/windows/` | 4 | T4 | DEFERRED | Added Android `FLAG_SECURE` and Windows `SetWindowDisplayAffinity` behind the generic `setBlocking` contract, with app-owned serialized apply/release and fail-closed visual-obscuring fallback; runtime/device behavior and other-platform capture remain open. |
| `LEGACY-GAP-2026-08-10-012` | `packages/peerdeal_native_bridges/`, `apps/peerdeal_mobile/`, `apps/peerdeal_desktop/` | 4 | T18 | RESOLVED | Added the generic app-support directory bridge and wired Android private no-backup storage plus Windows `LocalAppData` into the app-owned recovery factory, with explicit environment-root precedence and fail-closed fallback behavior. |
| `LEGACY-GAP-2026-08-10-013` | `apps/peerdeal_mobile/`, `apps/peerdeal_desktop/` | 4 | T19 | RESOLVED | Production entrypoints now install the app-owned method-channel native readiness loader; unavailable host capabilities render as unavailable and cannot silently bypass readiness-gated routes. |

## Status Definitions

- RESOLVED: Closed by this additive retrofit baseline.
- OPEN: Actionable future implementation gap.
- DEFERRED: Known production-readiness work intentionally outside T1 scope.

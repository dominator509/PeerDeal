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
| `LEGACY-GAP-2026-06-13-007` | `docs/PRODUCTION_READINESS.md` | 4 | T4 | DEFERRED | Remaining native work is capture blocking, local-network discovery, live transport, durable persistence, runtime key persistence validation, and non-Windows platform storage; mobile Android and Windows desktop secure storage are resolved at the host implementation/build level. |
| `LEGACY-GAP-2026-06-13-008` | `docs/PRODUCTION_READINESS.md` | 4 | T4 | DEFERRED | Final production UI validation and non-demo product flow validation remain future work. |
| `LEGACY-GAP-2026-08-09-009` | `apps/peerdeal_mobile/android/` | 4 | T4 | RESOLVED | Added the Android host, generic Keystore-backed secure-key implementation, and fail-closed release-signing configuration behind the existing channel contract. |
| `LEGACY-GAP-2026-08-09-010` | `apps/peerdeal_desktop/windows/` | 4 | T4 | RESOLVED | Added the Windows host, generic Credential Manager-backed secure-key implementation, bounded versioned record envelope, and locked channel registration; runtime profile persistence validation remains explicit. |

## Status Definitions

- RESOLVED: Closed by this additive retrofit baseline.
- OPEN: Actionable future implementation gap.
- DEFERRED: Known production-readiness work intentionally outside T1 scope.

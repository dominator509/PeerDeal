# AGENTS.md - peerdeal_crypto

## Mission
Provide fair-deal provider normalization and verification logic without owning UI, transport, or canonical reducer truth.

## Rules
- Keep provider internals behind explicit contracts.
- Keep verification outputs deterministic for a given request + evidence bundle.
- Do not pull UI, app-shell, or transport concerns into this package.
- Do not make receipts or exported artifacts authoritative.
- Prefer fixture-backed additions over ad hoc logic.

# PeerDeal Release Rules

A phase is not done because code exists. It is done only when:
- contract is explicit
- behavior is deterministic
- local tests pass
- fixtures/goldens exist where appropriate
- package ownership remains clean

## Phase 0 release bar
- monorepo structure present
- root docs present
- protocol spine present
- package-local tests wired
- boundary checks wired

## Production release bar
Use `docs/PRODUCTION_READINESS.md` as the production-readiness checklist. A
production release must satisfy those gates in addition to the phase release
bar above.

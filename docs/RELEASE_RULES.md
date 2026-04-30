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

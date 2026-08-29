# Starter Fixture Notes

These fixtures are intentionally small and are decoded through the typed
test-only recovery fixture loader.

They are meant to prove the starter package shape for:
- snapshot + suffix replay planning
- fatal vs recoverable conflict detection
- recovery coordinator decision shaping

Current fixtures:
- `basic_snapshot_recovery.json`: valid snapshot plus contiguous suffix,
  including expected final sequence and hash metadata.
- `fatal_protocol_recovery.json`: unsupported snapshot protocol that must
  produce a fatal safe-close recommendation.

Every JSON fixture in this directory is loaded by the fixture breadth test.
They are still not a production-complete recovery corpus.

# Replay Starter Fixtures

- `basic_session_replay.json` is a minimal two-event session window.
- `hand_scoped_replay.json` covers a verified hand-scoped window.
- `snapshot_suffix_replay.json` covers snapshot hydration followed by a
  verified event suffix.
- `anchor_mismatch_replay.json` covers fail-closed anchor comparison.
- `protocol_mismatch_replay.json` covers protocol rejection before projection.
- `basic_replay_engine_test.dart` loads every JSON fixture through the typed
  replay request decoder.

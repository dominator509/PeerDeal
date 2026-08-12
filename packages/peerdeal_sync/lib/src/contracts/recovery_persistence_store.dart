import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/persisted_recovery_window.dart';
import '../models/recovery_persistence_load_result.dart';
import '../models/recovery_persistence_result.dart';
import '../models/recovery_persistence_scope.dart';

abstract interface class RecoveryPersistenceStore {
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  });

  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  });

  /// Removes all persisted recovery data for [scope].
  ///
  /// Implementations must treat an already-empty scope as success and must
  /// reject invalid scope identities before touching storage.
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope});

  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope);
}

/// Optional additive read-result contract for stores that can report why a
/// persisted recovery window was unavailable.
abstract interface class RecoveryPersistenceLoadResultStore {
  RecoveryPersistenceLoadResult loadWindowResult(
    RecoveryPersistenceScope scope,
  );
}

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/persisted_recovery_window.dart';
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

  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope);
}

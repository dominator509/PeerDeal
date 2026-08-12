import 'package:peerdeal_sync/peerdeal_sync.dart';

import '../models/demo_scenario_snapshot.dart';

class DemoRecoveryResultFactory {
  const DemoRecoveryResultFactory();

  RecoveryResult<Object?>? createFor(DemoScenarioSnapshot snapshot) {
    if (snapshot.scenarioId != 'recovery_pause_transfer') return null;

    return RecoveryResult<Object?>(
      isSuccess: false,
      reconciliation: ReconciliationResult(
        canResume: false,
        requiresRecovery: true,
        recommendedAction: 'safe_close',
      ),
      conflicts: <SyncConflict>[
        SyncConflict(
          code: 'ERR_FINAL_EVENT_HASH_MISMATCH',
          message:
              'Final event hash does not match expected recovery baseline.',
          severity: SyncConflictSeverity.fatal,
          expected: 'expected_hash',
          actual: 'actual_hash',
        ),
      ],
      safeCloseRecommended: true,
    );
  }
}

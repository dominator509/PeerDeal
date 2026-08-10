import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

class AppRecoveryRetentionEnforcementResult {
  const AppRecoveryRetentionEnforcementResult({
    required this.isWipeDue,
    required this.persistenceResult,
  });

  final bool isWipeDue;
  final RecoveryPersistenceResult persistenceResult;

  bool get isSuccess => persistenceResult.isSuccess;

  bool get didWipe => isWipeDue && persistenceResult.isSuccess;
}

class AppRecoveryRetentionCoordinator {
  const AppRecoveryRetentionCoordinator({
    required RecoveryPersistenceStore store,
    this.retentionPolicyEngine = const DefaultRetentionPolicyEngine(),
  }) : _store = store;

  final RecoveryPersistenceStore _store;
  final RetentionPolicyEngine retentionPolicyEngine;

  AppRecoveryRetentionEnforcementResult enforceAfterSessionClose({
    required RecoveryPersistenceScope scope,
    required RetentionPolicy policy,
    required DateTime sessionClosedAt,
    required DateTime now,
  }) {
    if (!scope.hasValidStorageIdentity) {
      return _failure(
        isWipeDue: false,
        code: 'ERR_RECOVERY_RETENTION_SCOPE_INVALID',
        message: 'Recovery retention scope identity is invalid.',
      );
    }

    final bool wipeDue;
    try {
      wipeDue = retentionPolicyEngine.isWipeDue(
        policy: policy,
        sessionClosedAt: sessionClosedAt,
        now: now,
      );
    } on Object {
      return _failure(
        isWipeDue: false,
        code: 'ERR_RECOVERY_RETENTION_DECISION_FAILED',
        message: 'Recovery retention decision could not be evaluated.',
      );
    }

    if (!wipeDue) {
      return const AppRecoveryRetentionEnforcementResult(
        isWipeDue: false,
        persistenceResult: RecoveryPersistenceResult.success(),
      );
    }

    try {
      return AppRecoveryRetentionEnforcementResult(
        isWipeDue: true,
        persistenceResult: _store.wipe(scope: scope),
      );
    } on Object {
      return _failure(
        isWipeDue: true,
        code: 'ERR_RECOVERY_RETENTION_WIPE_FAILED',
        message: 'Recovery retention wipe could not be completed.',
      );
    }
  }

  static AppRecoveryRetentionEnforcementResult _failure({
    required bool isWipeDue,
    required String code,
    required String message,
  }) {
    return AppRecoveryRetentionEnforcementResult(
      isWipeDue: isWipeDue,
      persistenceResult: RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: <SyncConflict>[
          SyncConflict(
            code: code,
            message: message,
            severity: SyncConflictSeverity.fatal,
          ),
        ],
      ),
    );
  }
}

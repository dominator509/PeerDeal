import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

import 'app_recovery_retention_coordinator.dart';

/// Owns the retention attempt for one app session and close-time scope.
class AppRecoverySessionCloseCoordinator {
  AppRecoverySessionCloseCoordinator({
    required AppRecoveryRetentionCoordinator retentionCoordinator,
    required RecoveryPersistenceScope scope,
    required RetentionPolicy policy,
  }) : _retentionCoordinator = retentionCoordinator,
       _scope = scope,
       _policy = policy;

  final AppRecoveryRetentionCoordinator _retentionCoordinator;
  final RecoveryPersistenceScope _scope;
  final RetentionPolicy _policy;
  AppRecoveryRetentionEnforcementResult? _result;

  bool get isClosed => _result != null;

  AppRecoveryRetentionEnforcementResult close({
    required DateTime sessionClosedAt,
    required DateTime now,
  }) {
    final cachedResult = _result;
    if (cachedResult != null) return cachedResult;

    final result = _retentionCoordinator.enforceAfterSessionClose(
      scope: _scope,
      policy: _policy,
      sessionClosedAt: sessionClosedAt,
      now: now,
    );
    _result = result;
    return result;
  }
}

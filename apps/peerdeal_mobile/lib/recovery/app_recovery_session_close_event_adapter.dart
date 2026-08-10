import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'app_recovery_retention_coordinator.dart';
import 'app_recovery_session_close_coordinator.dart';

enum AppRecoverySessionCloseEventDisposition { ignored, rejected, enforced }

class AppRecoverySessionCloseEventResult {
  const AppRecoverySessionCloseEventResult._({
    required this.disposition,
    this.enforcementResult,
    this.warning,
  });

  const AppRecoverySessionCloseEventResult.ignored()
    : this._(disposition: AppRecoverySessionCloseEventDisposition.ignored);

  const AppRecoverySessionCloseEventResult.rejected({required String warning})
    : this._(
        disposition: AppRecoverySessionCloseEventDisposition.rejected,
        warning: warning,
      );

  const AppRecoverySessionCloseEventResult.enforced({
    required AppRecoveryRetentionEnforcementResult enforcementResult,
  }) : this._(
         disposition: AppRecoverySessionCloseEventDisposition.enforced,
         enforcementResult: enforcementResult,
       );

  final AppRecoverySessionCloseEventDisposition disposition;
  final AppRecoveryRetentionEnforcementResult? enforcementResult;
  final String? warning;

  bool get isIgnored =>
      disposition == AppRecoverySessionCloseEventDisposition.ignored;

  bool get isRejected =>
      disposition == AppRecoverySessionCloseEventDisposition.rejected;

  bool get isEnforced =>
      disposition == AppRecoverySessionCloseEventDisposition.enforced;

  bool get isSuccess =>
      isIgnored || (isEnforced && enforcementResult!.isSuccess);
}

/// Maps a validated protocol close event into app-owned retention orchestration.
class AppRecoverySessionCloseEventAdapter {
  AppRecoverySessionCloseEventAdapter({
    required AppRecoverySessionCloseCoordinator sessionCloseCoordinator,
    this.protocolCatalog = const ProtocolCatalog(),
  }) : _sessionCloseCoordinator = sessionCloseCoordinator;

  final AppRecoverySessionCloseCoordinator _sessionCloseCoordinator;
  final ProtocolCatalog protocolCatalog;

  AppRecoverySessionCloseEventResult handle(
    EventEnvelope event, {
    required DateTime now,
  }) {
    if (event.eventType != 'SessionClosed') {
      return const AppRecoverySessionCloseEventResult.ignored();
    }

    if (!protocolCatalog.checkEventEnvelope(event).isSupported) {
      return const AppRecoverySessionCloseEventResult.rejected(
        warning: 'Session close event is not supported.',
      );
    }

    final scope = _sessionCloseCoordinator.scope;
    if (event.tableId != scope.tableId ||
        event.sessionId != scope.sessionId ||
        event.protocolVersion != scope.protocolVersion) {
      return const AppRecoverySessionCloseEventResult.rejected(
        warning: 'Session close event scope does not match recovery scope.',
      );
    }

    final sessionClosedAt = DateTime.tryParse(event.emittedAt);
    if (sessionClosedAt == null) {
      return const AppRecoverySessionCloseEventResult.rejected(
        warning: 'Session close event timestamp is invalid.',
      );
    }

    return AppRecoverySessionCloseEventResult.enforced(
      enforcementResult: _sessionCloseCoordinator.close(
        sessionClosedAt: sessionClosedAt.toUtc(),
        now: now,
      ),
    );
  }
}

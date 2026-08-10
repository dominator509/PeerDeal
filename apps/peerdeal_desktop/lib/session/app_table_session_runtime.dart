import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../recovery/app_recovery_session_close_event_adapter.dart';

enum AppTableSessionEventDisposition { applied, rejected }

class AppTableSessionEventResult {
  const AppTableSessionEventResult._({
    required this.disposition,
    required this.state,
    this.recoveryResult,
    this.reasonCode,
    this.warnings = const <String>[],
  });

  const AppTableSessionEventResult.applied({
    required TableState state,
    AppRecoverySessionCloseEventResult? recoveryResult,
    List<String> warnings = const <String>[],
  }) : this._(
         disposition: AppTableSessionEventDisposition.applied,
         state: state,
         recoveryResult: recoveryResult,
         warnings: warnings,
       );

  const AppTableSessionEventResult.rejected({
    required TableState state,
    required String reasonCode,
    AppRecoverySessionCloseEventResult? recoveryResult,
    List<String> warnings = const <String>[],
  }) : this._(
         disposition: AppTableSessionEventDisposition.rejected,
         state: state,
         recoveryResult: recoveryResult,
         reasonCode: reasonCode,
         warnings: warnings,
       );

  final AppTableSessionEventDisposition disposition;
  final TableState state;
  final AppRecoverySessionCloseEventResult? recoveryResult;
  final String? reasonCode;
  final List<String> warnings;

  bool get isApplied => disposition == AppTableSessionEventDisposition.applied;
  bool get isRejected =>
      disposition == AppTableSessionEventDisposition.rejected;
}

/// Owns one app session's protocol-event projection and close-time retention.
///
/// Core remains the only source of deterministic table state. This class binds
/// that state to one app session and makes retention part of accepting a close.
class AppTableSessionRuntime {
  AppTableSessionRuntime({
    required TableState initialState,
    required AppRecoverySessionCloseEventAdapter closeEventAdapter,
    CoreReducer reducer = const CoreReducer(),
    DateTime Function()? clock,
  }) : _state = _validateInitialState(initialState),
       _closeEventAdapter = closeEventAdapter,
       _reducer = reducer,
       _clock = clock ?? DateTime.now;

  TableState _state;
  final AppRecoverySessionCloseEventAdapter _closeEventAdapter;
  final CoreReducer _reducer;
  final DateTime Function() _clock;
  EventEnvelope? _lastAcceptedEvent;
  int _acceptedEventCount = 0;

  TableState get state => _state;
  EventEnvelope? get lastAcceptedEvent => _lastAcceptedEvent;
  int get acceptedEventCount => _acceptedEventCount;
  bool get isClosed => _state.phase == TablePhase.closed;
  bool get isWiped => _state.phase == TablePhase.wiped;

  AppTableSessionEventResult applyEvent(EventEnvelope event, {DateTime? now}) {
    if (event.tableId != _state.tableId ||
        event.sessionId != _state.sessionId) {
      return _rejected(
        reasonCode: 'ERR_APP_SESSION_SCOPE_MISMATCH',
        warnings: const <String>['Session event scope does not match runtime.'],
      );
    }
    if (event.protocolVersion != _state.protocolVersion) {
      return _rejected(
        reasonCode: 'ERR_APP_SESSION_PROTOCOL_MISMATCH',
        warnings: const <String>[
          'Session event protocol does not match runtime.',
        ],
      );
    }

    final TableState projectedState;
    try {
      projectedState = _reducer.apply(_state, event);
    } on InvariantViolation catch (error) {
      return _rejected(reasonCode: error.code);
    } on Object {
      return _rejected(reasonCode: 'ERR_APP_SESSION_EVENT_REJECTED');
    }

    AppRecoverySessionCloseEventResult? recoveryResult;
    if (event.eventType == 'SessionClosed') {
      recoveryResult = _closeEventAdapter.handle(
        event,
        now: (now ?? _clock()).toUtc(),
      );
      if (!recoveryResult.isSuccess) {
        return _rejected(
          reasonCode: recoveryResult.isRejected
              ? 'ERR_SESSION_CLOSE_RETENTION_REJECTED'
              : 'ERR_SESSION_CLOSE_RETENTION_FAILED',
          recoveryResult: recoveryResult,
          warnings: _retentionWarnings(recoveryResult),
        );
      }
    }

    _state = projectedState;
    _lastAcceptedEvent = event;
    _acceptedEventCount++;
    return AppTableSessionEventResult.applied(
      state: _state,
      recoveryResult: recoveryResult,
    );
  }

  AppTableSessionEventResult _rejected({
    required String reasonCode,
    AppRecoverySessionCloseEventResult? recoveryResult,
    List<String> warnings = const <String>[],
  }) {
    return AppTableSessionEventResult.rejected(
      state: _state,
      reasonCode: reasonCode,
      recoveryResult: recoveryResult,
      warnings: warnings,
    );
  }

  static TableState _validateInitialState(TableState state) {
    if (state.tableId.trim().isEmpty || state.sessionId.trim().isEmpty) {
      throw ArgumentError(
        'Session state must have table and session identity.',
      );
    }
    if (state.protocolVersion.trim().isEmpty) {
      throw ArgumentError('Session state must have a protocol version.');
    }
    return state;
  }

  static List<String> _retentionWarnings(
    AppRecoverySessionCloseEventResult result,
  ) {
    final warnings = <String>[if (result.warning != null) result.warning!];
    final enforcementResult = result.enforcementResult;
    if (enforcementResult != null) {
      warnings.addAll(
        enforcementResult.persistenceResult.conflicts.map(
          (conflict) => conflict.code,
        ),
      );
    }
    return List<String>.unmodifiable(warnings);
  }
}

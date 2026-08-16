import 'dart:async';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import '../join_flow/join_flow_models.dart';
import '../recovery/app_recovery_session_close_event_adapter.dart';
import '../transport/app_table_session_transport_source.dart';
import '../transport/native_transport_session_factory.dart';
import 'app_holdem_production_session_factory.dart';
import 'app_holdem_production_session_snapshot_coordinator.dart';

/// Supplies the canonical product state and local identity for one resolved
/// invite. This source owns persistence/network hydration; the app bootstrap
/// only validates the correlation and composes the existing runtime.
abstract interface class AppHoldemProductionSessionSource {
  Future<AppHoldemProductionSessionInput> load(
    ResolvedInvite invite, {
    Future<void>? cancellation,
  });
}

/// Optional extension for sources that can consume the verified peer and seat
/// selected by the accepted join flow.
abstract interface class AppHoldemProductionSessionContextSource {
  Future<AppHoldemProductionSessionInput> loadForSessionContext(
    JoinFlowSessionContext sessionContext, {
    Future<void>? cancellation,
  });
}

/// All product-owned inputs required by the app Hold'em composition boundary.
class AppHoldemProductionSessionInput {
  const AppHoldemProductionSessionInput({
    required this.initialTableState,
    required this.initialHandState,
    required this.initialCursor,
    required this.closeEventAdapter,
    required this.path,
    required this.navigationLabel,
    required this.peerId,
    required this.localPeerId,
    required this.localSeat,
    this.reducer = const CoreReducer(),
    this.clock,
    this.projectionAdapter = const HoldemCoreProjectionAdapter(),
    this.eventReducer = const HoldemEventReducer(),
    this.nativeSessionFactory,
    this.pollInterval = const Duration(seconds: 1),
    this.timerFactory,
    this.snapshotCoordinator,
  });

  final TableState initialTableState;
  final HoldemHandState initialHandState;
  final HoldemEventCursor initialCursor;
  final AppRecoverySessionCloseEventAdapter closeEventAdapter;
  final String path;
  final String navigationLabel;
  final String peerId;
  final String localPeerId;
  final int localSeat;
  final CoreReducer reducer;
  final DateTime Function()? clock;
  final HoldemCoreProjectionAdapter projectionAdapter;
  final HoldemEventReducer eventReducer;
  final NativeTransportSessionFactory? nativeSessionFactory;
  final Duration pollInterval;
  final NativeTransportSourceTimerFactory? timerFactory;
  final AppHoldemProductionSessionSnapshotCoordinator? snapshotCoordinator;
}

/// Converts a product-owned resolved invite into the mounted production route.
///
/// No identifiers, state, persistence, or transport configuration are
/// derived here. A mismatch between the resolved invite and hydrated state is
/// rejected before a route or native transport can be exposed.
class AppHoldemProductionSessionBootstrap {
  AppHoldemProductionSessionBootstrap({
    required AppHoldemProductionSessionSource source,
    AppHoldemProductionSessionContextSource? contextSource,
    AppHoldemProductionSessionFactory factory =
        const AppHoldemProductionSessionFactory(),
    this.sourceLoadTimeout = const Duration(seconds: 5),
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  }) : _source = source,
       _contextSource = contextSource,
       _factory = factory,
       maxRecoveryEvents = _validateMaxRecoveryEvents(maxRecoveryEvents);

  final AppHoldemProductionSessionSource _source;
  final AppHoldemProductionSessionContextSource? _contextSource;
  final AppHoldemProductionSessionFactory _factory;
  final Duration sourceLoadTimeout;
  final int maxRecoveryEvents;

  Future<AppHoldemProductionSessionComposition> createForInvite(
    ResolvedInvite invite, {
    Future<void>? cancellation,
  }) async {
    if (sourceLoadTimeout <= Duration.zero) {
      throw ArgumentError.value(
        sourceLoadTimeout,
        'sourceLoadTimeout',
        'Production session source timeout must be positive.',
      );
    }
    _validateInvite(invite);
    final input = await _loadSource(invite, cancellation: cancellation);
    _validateInput(invite, input);

    return _createComposition(input);
  }

  Future<AppHoldemProductionSessionComposition> createForSessionContext(
    JoinFlowSessionContext sessionContext, {
    Future<void>? cancellation,
  }) async {
    if (sourceLoadTimeout <= Duration.zero) {
      throw ArgumentError.value(
        sourceLoadTimeout,
        'sourceLoadTimeout',
        'Production session source timeout must be positive.',
      );
    }
    _validateInvite(sessionContext.invite);
    _validateIdentity(
      sessionContext.remotePeerId,
      'sessionContext.remotePeerId',
    );
    if (sessionContext.localSeat < 1) {
      throw ArgumentError.value(
        sessionContext.localSeat,
        'sessionContext.localSeat',
        'Production session seat must be positive.',
      );
    }
    final source = _contextSource;
    if (source == null) {
      throw StateError(
        'Production session source does not support session context.',
      );
    }
    final input = await _loadSourceFuture(
      (sourceCancellation) => source.loadForSessionContext(
        sessionContext,
        cancellation: sourceCancellation,
      ),
      cancellation: cancellation,
    );
    _validateInput(sessionContext.invite, input);

    return _createComposition(input);
  }

  AppHoldemProductionSessionComposition _createComposition(
    AppHoldemProductionSessionInput input,
  ) {
    return _factory.create(
      initialTableState: input.initialTableState,
      initialHandState: input.initialHandState,
      initialCursor: input.initialCursor,
      closeEventAdapter: input.closeEventAdapter,
      path: input.path,
      navigationLabel: input.navigationLabel,
      peerId: input.peerId,
      localPeerId: input.localPeerId,
      localSeat: input.localSeat,
      reducer: input.reducer,
      clock: input.clock,
      projectionAdapter: input.projectionAdapter,
      eventReducer: input.eventReducer,
      nativeSessionFactory: input.nativeSessionFactory,
      pollInterval: input.pollInterval,
      timerFactory: input.timerFactory,
      snapshotCoordinator: input.snapshotCoordinator,
      maxRecoveryEvents: maxRecoveryEvents,
    );
  }

  Future<AppHoldemProductionSessionInput> _loadSource(
    ResolvedInvite invite, {
    Future<void>? cancellation,
  }) {
    return _loadSourceFuture(
      (sourceCancellation) =>
          _source.load(invite, cancellation: sourceCancellation),
      cancellation: cancellation,
    );
  }

  Future<AppHoldemProductionSessionInput> _loadSourceFuture(
    Future<AppHoldemProductionSessionInput> Function(
      Future<void> sourceCancellation,
    )
    load, {
    Future<void>? cancellation,
  }) {
    final sourceCancellation = Completer<void>();

    void cancelSource() {
      if (!sourceCancellation.isCompleted) {
        sourceCancellation.complete();
      }
    }

    late final Future<AppHoldemProductionSessionInput> sourceFuture;
    try {
      sourceFuture = load(sourceCancellation.future);
    } on Object catch (error, stackTrace) {
      cancelSource();
      sourceFuture = Future<AppHoldemProductionSessionInput>.error(
        error,
        stackTrace,
      );
    }

    return _loadFuture(
      sourceFuture,
      cancellation: cancellation,
      cancelSource: cancelSource,
    );
  }

  Future<AppHoldemProductionSessionInput> _loadFuture(
    Future<AppHoldemProductionSessionInput> sourceFuture, {
    Future<void>? cancellation,
    void Function()? cancelSource,
  }) {
    final result = Completer<AppHoldemProductionSessionInput>();
    Timer? timeoutTimer;

    void completeValue(AppHoldemProductionSessionInput input) {
      if (result.isCompleted) return;
      timeoutTimer?.cancel();
      result.complete(input);
    }

    void completeError(Object error, [StackTrace? stackTrace]) {
      if (result.isCompleted) return;
      timeoutTimer?.cancel();
      result.completeError(error, stackTrace);
    }

    timeoutTimer = Timer(sourceLoadTimeout, () {
      cancelSource?.call();
      completeError(TimeoutException('Production session source timed out.'));
    });
    sourceFuture.then<void>(
      completeValue,
      onError: (Object error, StackTrace stackTrace) {
        completeError(error, stackTrace);
      },
    );
    cancellation?.then<void>(
      (_) {
        cancelSource?.call();
        completeError(StateError('Production session source load cancelled.'));
      },
      onError: (Object error, StackTrace stackTrace) {
        cancelSource?.call();
        completeError(error, stackTrace);
      },
    );
    return result.future;
  }

  static void _validateInvite(ResolvedInvite invite) {
    _validateIdentity(invite.inviteId, 'invite.inviteId');
    _validateIdentity(invite.tableId, 'invite.tableId');
    _validateIdentity(invite.sessionId, 'invite.sessionId');
    _validateIdentity(invite.modeType, 'invite.modeType');
    _validateIdentity(invite.protocolVersion, 'invite.protocolVersion');
  }

  static void _validateInput(
    ResolvedInvite invite,
    AppHoldemProductionSessionInput input,
  ) {
    final tableState = input.initialTableState;
    final cursor = input.initialCursor;
    if (tableState.tableId != invite.tableId ||
        tableState.sessionId != invite.sessionId ||
        tableState.protocolVersion != invite.protocolVersion) {
      throw StateError(
        'Hydrated table state does not match the resolved invite scope.',
      );
    }
    if (cursor.tableId != invite.tableId ||
        cursor.sessionId != invite.sessionId ||
        cursor.protocolVersion != invite.protocolVersion) {
      throw StateError(
        'Hydrated Holdem cursor does not match the resolved invite scope.',
      );
    }
  }

  static void _validateIdentity(String value, String name) {
    if (value.trim().isEmpty ||
        value != value.trim() ||
        value.codeUnits.any(
          (codeUnit) =>
              codeUnit <= 0x20 || (codeUnit >= 0x7F && codeUnit <= 0x9F),
        )) {
      throw ArgumentError.value(
        value,
        name,
        'Resolved invite identity must be non-empty, unpadded, and control-free.',
      );
    }
  }
}

int _validateMaxRecoveryEvents(int value) {
  if (value <= 0) {
    throw ArgumentError.value(
      value,
      'maxRecoveryEvents',
      'Recovery event limit must be positive.',
    );
  }
  return value;
}

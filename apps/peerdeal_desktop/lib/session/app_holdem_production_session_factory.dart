import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import '../recovery/app_recovery_session_close_event_adapter.dart';
import '../transport/app_table_session_transport_source.dart';
import '../transport/native_transport_session_factory.dart';
import 'app_holdem_production_route_registration.dart';
import 'app_holdem_production_session_snapshot_coordinator.dart';
import 'app_holdem_table_session_runtime.dart';
import 'app_table_session_runtime.dart';

/// The app-owned composition of one validated production Hold'em session.
///
/// Product/session orchestration supplies the canonical table state, hand
/// state, event cursor, close adapter, and peer identity. This object only
/// binds those inputs to the existing app runtimes and route surface.
class AppHoldemProductionSessionComposition {
  const AppHoldemProductionSessionComposition({
    required this.sessionRuntime,
    required this.holdemRuntime,
    required this.route,
  });

  final AppTableSessionRuntime sessionRuntime;
  final AppHoldemTableSessionRuntime holdemRuntime;
  final AppHoldemProductionRouteRegistration route;
}

/// Creates the app boundary for a native-backed production Hold'em route.
///
/// This factory deliberately does not derive IDs, hydrate persistence, or
/// create game state. Those values must come from the product session source.
class AppHoldemProductionSessionFactory {
  const AppHoldemProductionSessionFactory();

  AppHoldemProductionSessionComposition create({
    required TableState initialTableState,
    required HoldemHandState initialHandState,
    required HoldemEventCursor initialCursor,
    required AppRecoverySessionCloseEventAdapter closeEventAdapter,
    required String path,
    required String navigationLabel,
    required String peerId,
    required String localPeerId,
    required int localSeat,
    CoreReducer reducer = const CoreReducer(),
    DateTime Function()? clock,
    HoldemCoreProjectionAdapter projectionAdapter =
        const HoldemCoreProjectionAdapter(),
    HoldemEventReducer eventReducer = const HoldemEventReducer(),
    NativeTransportSessionFactory? nativeSessionFactory,
    Duration pollInterval = const Duration(seconds: 1),
    NativeTransportSourceTimerFactory? timerFactory,
    AppHoldemProductionSessionSnapshotCoordinator? snapshotCoordinator,
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  }) {
    _validateRouteMetadata(path: path, navigationLabel: navigationLabel);
    _validateTransportIdentity(
      initialTableState.tableId,
      'initialTableState.tableId',
    );
    _validateTransportIdentity(
      initialTableState.sessionId,
      'initialTableState.sessionId',
    );
    _validateTransportIdentity(
      initialTableState.protocolVersion,
      'initialTableState.protocolVersion',
    );
    _validatePeerIdentity(peerId, 'peerId');
    _validatePeerIdentity(localPeerId, 'localPeerId');
    if (peerId == localPeerId) {
      throw ArgumentError('Remote and local peer identities must differ.');
    }
    if (localSeat < 1 || initialHandState.findSeat(localSeat) == null) {
      throw ArgumentError.value(
        localSeat,
        'localSeat',
        'Local seat must identify a seat in the supplied hand state.',
      );
    }
    if (pollInterval < const Duration(milliseconds: 100) ||
        pollInterval > const Duration(minutes: 1)) {
      throw ArgumentError.value(
        pollInterval,
        'pollInterval',
        'Production transport polling must be between 100ms and one minute.',
      );
    }

    final sessionRuntime = AppTableSessionRuntime(
      initialState: initialTableState,
      closeEventAdapter: closeEventAdapter,
      reducer: reducer,
      clock: clock,
      maxRecoveryEvents: maxRecoveryEvents,
    );
    final holdemRuntime = AppHoldemTableSessionRuntime(
      sessionRuntime: sessionRuntime,
      initialHandState: initialHandState,
      initialCursor: initialCursor,
      projectionAdapter: projectionAdapter,
      eventReducer: eventReducer,
    );
    final route = AppHoldemProductionRouteRegistration.withDefaultSurface(
      path: path,
      navigationLabel: navigationLabel,
      runtime: holdemRuntime,
      peerId: peerId,
      localPeerId: localPeerId,
      localSeat: localSeat,
      nativeSessionFactory: nativeSessionFactory,
      pollInterval: pollInterval,
      timerFactory: timerFactory,
      snapshotCoordinator: snapshotCoordinator,
    );

    return AppHoldemProductionSessionComposition(
      sessionRuntime: sessionRuntime,
      holdemRuntime: holdemRuntime,
      route: route,
    );
  }

  static void _validateRouteMetadata({
    required String path,
    required String navigationLabel,
  }) {
    if (path.trim().isEmpty ||
        path != path.trim() ||
        !path.startsWith('/') ||
        path == '/' ||
        path.endsWith('/') ||
        path.contains('?') ||
        path.contains('#') ||
        path.contains('//') ||
        path.contains('\\') ||
        _containsControlCharacter(path)) {
      throw ArgumentError.value(
        path,
        'path',
        'Production route path is not safe.',
      );
    }
    if (navigationLabel.trim().isEmpty ||
        navigationLabel != navigationLabel.trim() ||
        _containsLabelControlCharacter(navigationLabel)) {
      throw ArgumentError.value(
        navigationLabel,
        'navigationLabel',
        'Production navigation label is not safe.',
      );
    }
  }

  static void _validatePeerIdentity(String value, String name) {
    _validateTransportIdentity(value, name);
  }

  static void _validateTransportIdentity(String value, String name) {
    if (!NativeBridgePayloadLimits.isSafeUtf8Text(
      value,
      NativeBridgePayloadLimits.maxTransportIdentityBytes,
    )) {
      throw ArgumentError.value(
        value,
        name,
        'Peer identity must be non-empty, unpadded, and control-free.',
      );
    }
  }

  static bool _containsControlCharacter(String value) =>
      value.codeUnits.any((codeUnit) => codeUnit <= 0x20 || codeUnit == 0x7F);

  static bool _containsLabelControlCharacter(String value) =>
      value.codeUnits.any((codeUnit) => codeUnit < 0x20 || codeUnit == 0x7F);
}

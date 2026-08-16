import 'package:flutter/widgets.dart';

import '../transport/app_table_session_transport_source.dart';
import '../transport/native_transport_session_factory.dart';
import 'app_holdem_production_session_snapshot_coordinator.dart';
import 'app_holdem_production_table_surface.dart';
import 'app_holdem_table_session_route.dart';
import 'app_holdem_table_session_runtime.dart';

/// Typed app-shell registration for one native-backed Hold'em production route.
///
/// The caller owns validated session and variant state construction. This
/// registration only supplies the route map builder and the native-readiness
/// navigation metadata around the existing Hold'em route boundary.
class AppHoldemProductionRouteRegistration {
  const AppHoldemProductionRouteRegistration({
    required this.path,
    required this.navigationLabel,
    required this.runtime,
    required this.peerId,
    required this.localPeerId,
    required this.surfaceBuilder,
    this.nativeSessionFactory,
    this.snapshotCoordinator,
    this.pollInterval = const Duration(seconds: 1),
    this.timerFactory,
  });

  /// Builds a route with the app-owned production table surface.
  ///
  /// The caller still supplies the validated runtime and local identity. The
  /// surface owns presentation and transport-backed action dispatch only.
  AppHoldemProductionRouteRegistration.withDefaultSurface({
    required String path,
    required String navigationLabel,
    required AppHoldemTableSessionRuntime runtime,
    required String peerId,
    required String localPeerId,
    required int localSeat,
    NativeTransportSessionFactory? nativeSessionFactory,
    Duration pollInterval = const Duration(seconds: 1),
    NativeTransportSourceTimerFactory? timerFactory,
    AppHoldemProductionSessionSnapshotCoordinator? snapshotCoordinator,
  }) : this(
         path: path,
         navigationLabel: navigationLabel,
         runtime: runtime,
         peerId: peerId,
         localPeerId: localPeerId,
         surfaceBuilder: (_, routeContext) => AppHoldemProductionTableSurface(
           routeContext: routeContext,
           localPeerId: localPeerId,
           localSeat: localSeat,
         ),
         nativeSessionFactory: nativeSessionFactory,
         snapshotCoordinator: snapshotCoordinator,
         pollInterval: pollInterval,
         timerFactory: timerFactory,
       );

  final String path;
  final String navigationLabel;
  final AppHoldemTableSessionRuntime runtime;
  final String peerId;
  final String localPeerId;
  final AppHoldemTableSessionSurfaceBuilder surfaceBuilder;
  final NativeTransportSessionFactory? nativeSessionFactory;
  final AppHoldemProductionSessionSnapshotCoordinator? snapshotCoordinator;
  final Duration pollInterval;
  final NativeTransportSourceTimerFactory? timerFactory;

  WidgetBuilder get builder {
    return (context) => AppHoldemTableSessionRoute(
      runtime: runtime,
      peerId: peerId,
      localPeerId: localPeerId,
      surfaceBuilder: surfaceBuilder,
      nativeSessionFactory: nativeSessionFactory,
      snapshotCoordinator: snapshotCoordinator,
      pollInterval: pollInterval,
      timerFactory: timerFactory,
    );
  }
}

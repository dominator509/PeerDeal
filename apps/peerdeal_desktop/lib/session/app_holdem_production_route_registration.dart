import 'package:flutter/widgets.dart';

import '../transport/app_table_session_transport_source.dart';
import '../transport/native_transport_session_factory.dart';
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
    required this.surfaceBuilder,
    this.nativeSessionFactory,
    this.pollInterval = const Duration(seconds: 1),
    this.timerFactory,
  });

  final String path;
  final String navigationLabel;
  final AppHoldemTableSessionRuntime runtime;
  final String peerId;
  final AppHoldemTableSessionSurfaceBuilder surfaceBuilder;
  final NativeTransportSessionFactory? nativeSessionFactory;
  final Duration pollInterval;
  final NativeTransportSourceTimerFactory? timerFactory;

  WidgetBuilder get builder {
    return (context) => AppHoldemTableSessionRoute(
      runtime: runtime,
      peerId: peerId,
      surfaceBuilder: surfaceBuilder,
      nativeSessionFactory: nativeSessionFactory,
      pollInterval: pollInterval,
      timerFactory: timerFactory,
    );
  }
}

import 'package:flutter/widgets.dart';

import 'app_holdem_production_session_bootstrap.dart';
import 'app_holdem_production_session_bootstrap_route.dart';

/// Registers the app-owned bootstrap route used by an accepted join outcome.
///
/// The registration mounts the existing route adapter but does not create
/// product state, local identity, or persistence. The app shell supplies the
/// resolved invite as route arguments when the join-ready handoff runs.
class AppHoldemProductionSessionBootstrapRouteRegistration {
  const AppHoldemProductionSessionBootstrapRouteRegistration({
    required this.path,
    required this.bootstrap,
  });

  final String path;
  final AppHoldemProductionSessionBootstrap bootstrap;

  WidgetBuilder get builder {
    return AppHoldemProductionSessionBootstrapRoute.fromRouteSettings(
      bootstrap: bootstrap,
    );
  }
}

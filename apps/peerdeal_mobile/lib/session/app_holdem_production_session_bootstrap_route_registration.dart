import 'package:flutter/widgets.dart';

import 'app_holdem_production_session_bootstrap.dart';
import 'app_holdem_production_session_bootstrap_route.dart';
import 'app_holdem_production_session_factory.dart';

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

  /// Builds a registration directly from the product-owned source boundary.
  ///
  /// The source still owns state hydration, local identity, persistence, and
  /// any cancellation beneath its load contract. This constructor only keeps
  /// bootstrap and route registration configuration together at the app edge.
  factory AppHoldemProductionSessionBootstrapRouteRegistration.fromSource({
    required String path,
    required AppHoldemProductionSessionSource source,
    AppHoldemProductionSessionFactory sessionFactory =
        const AppHoldemProductionSessionFactory(),
    Duration sourceLoadTimeout = const Duration(seconds: 5),
  }) {
    return AppHoldemProductionSessionBootstrapRouteRegistration(
      path: path,
      bootstrap: AppHoldemProductionSessionBootstrap(
        source: source,
        contextSource: source is AppHoldemProductionSessionContextSource
            ? source as AppHoldemProductionSessionContextSource
            : null,
        factory: sessionFactory,
        sourceLoadTimeout: sourceLoadTimeout,
      ),
    );
  }

  final String path;
  final AppHoldemProductionSessionBootstrap bootstrap;

  WidgetBuilder get builder {
    return AppHoldemProductionSessionBootstrapRoute.fromRouteSettings(
      bootstrap: bootstrap,
    );
  }
}

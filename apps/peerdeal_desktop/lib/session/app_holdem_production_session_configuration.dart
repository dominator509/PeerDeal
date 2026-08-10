import 'app_holdem_production_session_bootstrap.dart';
import 'app_holdem_production_session_bootstrap_route_registration.dart';
import 'app_holdem_production_session_factory.dart';

/// Holds one stable app-owned production-session route configuration.
///
/// The product source remains responsible for loading canonical table and
/// Hold'em state, local identity, persistence, and cancellation. This object
/// only creates the route registration once so app rebuilds do not recreate
/// the default join handoff callback.
class AppHoldemProductionSessionConfiguration {
  factory AppHoldemProductionSessionConfiguration.fromSource({
    required String path,
    required AppHoldemProductionSessionSource source,
    AppHoldemProductionSessionFactory sessionFactory =
        const AppHoldemProductionSessionFactory(),
    Duration sourceLoadTimeout = const Duration(seconds: 5),
  }) {
    return AppHoldemProductionSessionConfiguration._(
      routeRegistration:
          AppHoldemProductionSessionBootstrapRouteRegistration.fromSource(
            path: path,
            source: source,
            sessionFactory: sessionFactory,
            sourceLoadTimeout: sourceLoadTimeout,
          ),
    );
  }

  const AppHoldemProductionSessionConfiguration._({
    required this.routeRegistration,
  });

  final AppHoldemProductionSessionBootstrapRouteRegistration routeRegistration;
}

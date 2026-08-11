import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import 'app_holdem_production_session_bootstrap.dart';
import 'app_holdem_production_session_bootstrap_route_registration.dart';
import 'app_holdem_production_session_factory.dart';
import 'app_persisted_holdem_production_session_source.dart';
import 'native_local_peer_identity_provisioner.dart';

/// Holds one stable app-owned production-session route configuration.
///
/// The product source remains responsible for loading canonical table and
/// Hold'em state, local identity, persistence, and cancellation. This object
/// only creates the route registration once so app rebuilds do not recreate
/// the default join handoff callback.
class AppHoldemProductionSessionConfiguration {
  /// Builds one stable route configuration from the app-owned persisted source.
  ///
  /// The recovery store and native identity provisioner remain app-owned
  /// inputs. This factory only composes them with the existing validated
  /// bootstrap route; it does not turn recovery persistence into a product
  /// database or derive route policy.
  static Future<AppHoldemProductionSessionConfiguration>
  fromPersistedLocalIdentity({
    required RecoveryPersistenceStore store,
    required NativeLocalPeerIdentityProvisioner identityProvisioner,
    required AppPersistedHoldemProductionSessionRoutePolicy routePolicy,
    required HoldemEventIdFactory eventIdFactory,
    required HoldemEventTimestampFactory emittedAtFactory,
    required HoldemEventHashFactory eventHashFactory,
    HoldemCoreProjectionAdapter replayAdapter =
        const HoldemCoreProjectionAdapter(),
    HoldemEventReducer eventReducer = const HoldemEventReducer(),
    String snapshotType = 'HoldemStateSnapshot',
    String snapshotVersion = '1.0',
    AppHoldemProductionSessionFactory sessionFactory =
        const AppHoldemProductionSessionFactory(),
    Duration sourceLoadTimeout = const Duration(seconds: 5),
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  }) async {
    _validateSourceLoadTimeout(sourceLoadTimeout);
    final source =
        await AppPersistedHoldemProductionSessionSource.fromLocalIdentityProvisioner(
          store: store,
          identityProvisioner: identityProvisioner,
          routePolicy: routePolicy,
          eventIdFactory: eventIdFactory,
          emittedAtFactory: emittedAtFactory,
          eventHashFactory: eventHashFactory,
          replayAdapter: replayAdapter,
          eventReducer: eventReducer,
          snapshotType: snapshotType,
          snapshotVersion: snapshotVersion,
          maxRecoveryEvents: maxRecoveryEvents,
        );
    return AppHoldemProductionSessionConfiguration.fromSource(
      path: routePolicy.path,
      source: source,
      sessionFactory: sessionFactory,
      sourceLoadTimeout: sourceLoadTimeout,
      maxRecoveryEvents: maxRecoveryEvents,
    );
  }

  factory AppHoldemProductionSessionConfiguration.fromSource({
    required String path,
    required AppHoldemProductionSessionSource source,
    AppHoldemProductionSessionFactory sessionFactory =
        const AppHoldemProductionSessionFactory(),
    Duration sourceLoadTimeout = const Duration(seconds: 5),
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  }) {
    _validateSourceLoadTimeout(sourceLoadTimeout);
    return AppHoldemProductionSessionConfiguration._(
      routeRegistration:
          AppHoldemProductionSessionBootstrapRouteRegistration.fromSource(
            path: path,
            source: source,
            sessionFactory: sessionFactory,
            sourceLoadTimeout: sourceLoadTimeout,
            maxRecoveryEvents: maxRecoveryEvents,
          ),
    );
  }

  const AppHoldemProductionSessionConfiguration._({
    required this.routeRegistration,
  });

  final AppHoldemProductionSessionBootstrapRouteRegistration routeRegistration;

  static void _validateSourceLoadTimeout(Duration sourceLoadTimeout) {
    if (sourceLoadTimeout <= Duration.zero) {
      throw ArgumentError.value(
        sourceLoadTimeout,
        'sourceLoadTimeout',
        'Production session source timeout must be positive.',
      );
    }
  }
}

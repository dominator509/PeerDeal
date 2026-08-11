import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import '../recovery/app_recovery_persistence_store_factory.dart';
import 'app_holdem_production_session_configuration.dart';
import 'app_holdem_production_session_factory.dart';
import 'app_holdem_production_session_snapshot_writer.dart';
import 'app_persisted_holdem_production_session_source.dart';
import 'native_local_peer_identity_provisioner.dart';

typedef AppHoldemProductionSessionRoutePolicyFactory =
    AppPersistedHoldemProductionSessionRoutePolicy Function(
      RecoveryPersistenceStore store,
    );

class AppHoldemProductionSessionConfigurationLoadResult {
  const AppHoldemProductionSessionConfigurationLoadResult.available({
    required this.configuration,
    required this.snapshotWriter,
    this.warnings = const <String>[],
  });

  const AppHoldemProductionSessionConfigurationLoadResult.unavailable({
    required this.warnings,
  }) : configuration = null,
       snapshotWriter = null;

  final AppHoldemProductionSessionConfiguration? configuration;
  final AppHoldemProductionSessionSnapshotWriter? snapshotWriter;
  final List<String> warnings;

  bool get isAvailable => configuration != null;
}

/// Composes the app-owned persisted Hold'em route from its real storage and
/// identity boundaries without selecting product session state or policy.
class AppHoldemProductionSessionConfigurationFactory {
  const AppHoldemProductionSessionConfigurationFactory({
    required AppRecoveryPersistenceStoreFactory recoveryStoreFactory,
    required AppHoldemProductionSessionRoutePolicyFactory routePolicyFactory,
    required HoldemEventIdFactory eventIdFactory,
    required HoldemEventTimestampFactory emittedAtFactory,
    required HoldemEventHashFactory eventHashFactory,
    NativeLocalPeerIdentityProvisioner? identityProvisioner,
    HoldemCoreProjectionAdapter replayAdapter =
        const HoldemCoreProjectionAdapter(),
    HoldemEventReducer eventReducer = const HoldemEventReducer(),
    String snapshotType = 'HoldemStateSnapshot',
    String snapshotVersion = '1.0',
    AppHoldemProductionSessionFactory sessionFactory =
        const AppHoldemProductionSessionFactory(),
    Duration sourceLoadTimeout = const Duration(seconds: 5),
  }) : _recoveryStoreFactory = recoveryStoreFactory,
       _routePolicyFactory = routePolicyFactory,
       _eventIdFactory = eventIdFactory,
       _emittedAtFactory = emittedAtFactory,
       _eventHashFactory = eventHashFactory,
       _identityProvisioner = identityProvisioner,
       _replayAdapter = replayAdapter,
       _eventReducer = eventReducer,
       _snapshotType = snapshotType,
       _snapshotVersion = snapshotVersion,
       _sessionFactory = sessionFactory,
       _sourceLoadTimeout = sourceLoadTimeout;

  final AppRecoveryPersistenceStoreFactory _recoveryStoreFactory;
  final AppHoldemProductionSessionRoutePolicyFactory _routePolicyFactory;
  final HoldemEventIdFactory _eventIdFactory;
  final HoldemEventTimestampFactory _emittedAtFactory;
  final HoldemEventHashFactory _eventHashFactory;
  final NativeLocalPeerIdentityProvisioner? _identityProvisioner;
  final HoldemCoreProjectionAdapter _replayAdapter;
  final HoldemEventReducer _eventReducer;
  final String _snapshotType;
  final String _snapshotVersion;
  final AppHoldemProductionSessionFactory _sessionFactory;
  final Duration _sourceLoadTimeout;

  Future<AppHoldemProductionSessionConfigurationLoadResult> create() async {
    final persistence = _recoveryStoreFactory.create();
    final store = persistence.store;
    if (store == null) {
      return AppHoldemProductionSessionConfigurationLoadResult.unavailable(
        warnings: persistence.warnings,
      );
    }

    try {
      final routePolicy = _routePolicyFactory(store);
      routePolicy.validate();
      final configuration =
          await AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(
            store: store,
            identityProvisioner:
                _identityProvisioner ??
                NativeLocalPeerIdentityProvisioner.methodChannel(),
            routePolicy: routePolicy,
            eventIdFactory: _eventIdFactory,
            emittedAtFactory: _emittedAtFactory,
            eventHashFactory: _eventHashFactory,
            replayAdapter: _replayAdapter,
            eventReducer: _eventReducer,
            snapshotType: _snapshotType,
            snapshotVersion: _snapshotVersion,
            sessionFactory: _sessionFactory,
            sourceLoadTimeout: _sourceLoadTimeout,
          );
      return AppHoldemProductionSessionConfigurationLoadResult.available(
        configuration: configuration,
        snapshotWriter: AppHoldemProductionSessionSnapshotWriter(store: store),
        warnings: persistence.warnings,
      );
    } on Object {
      return const AppHoldemProductionSessionConfigurationLoadResult.unavailable(
        warnings: <String>[
          'Holdem production session configuration is unavailable.',
        ],
      );
    }
  }
}

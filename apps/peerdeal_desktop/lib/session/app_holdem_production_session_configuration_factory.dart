import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import '../join_flow/join_flow_models.dart';
import '../recovery/app_recovery_persistence_store_factory.dart';
import 'app_holdem_production_session_configuration.dart';
import 'app_holdem_production_session_factory.dart';
import 'app_holdem_production_session_persistence_writer.dart';
import 'app_holdem_production_session_snapshot_coordinator.dart';
import 'app_holdem_production_session_snapshot_writer.dart';
import 'app_persisted_holdem_production_session_source.dart';
import 'native_local_peer_identity_provisioner.dart';

typedef AppHoldemProductionSessionRoutePolicyFactory =
    AppPersistedHoldemProductionSessionRoutePolicy Function(
      RecoveryPersistenceStore store,
    );

typedef AppHoldemProductionSessionContextRoutePolicyFactory =
    AppPersistedHoldemProductionSessionRoutePolicy Function(
      RecoveryPersistenceStore store,
      JoinFlowSessionContext sessionContext,
    );

class AppHoldemProductionSessionConfigurationLoadResult {
  AppHoldemProductionSessionConfigurationLoadResult.available({
    required this.configuration,
    required this.persistenceWriter,
    required this.snapshotWriter,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  AppHoldemProductionSessionConfigurationLoadResult.unavailable({
    required List<String> warnings,
  }) : configuration = null,
       persistenceWriter = null,
       snapshotWriter = null,
       warnings = List<String>.unmodifiable(warnings);

  final AppHoldemProductionSessionConfiguration? configuration;
  final AppHoldemProductionSessionPersistenceWriter? persistenceWriter;
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
    AppHoldemProductionSessionContextRoutePolicyFactory?
    contextRoutePolicyFactory,
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
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
    int maxPendingCheckpoints = AppHoldemProductionSessionSnapshotCoordinator
        .defaultMaxPendingCheckpoints,
    int maxPendingCheckpointBytes =
        AppHoldemProductionSessionSnapshotCoordinator
            .defaultMaxPendingCheckpointBytes,
    AppHoldemProductionSessionInitialSnapshotLoader? initialSnapshotLoader,
    AppHoldemProductionSessionContextInitialSnapshotLoader?
    contextInitialSnapshotLoader,
  }) : _recoveryStoreFactory = recoveryStoreFactory,
       _routePolicyFactory = routePolicyFactory,
       _contextRoutePolicyFactory = contextRoutePolicyFactory,
       _eventIdFactory = eventIdFactory,
       _emittedAtFactory = emittedAtFactory,
       _eventHashFactory = eventHashFactory,
       _identityProvisioner = identityProvisioner,
       _replayAdapter = replayAdapter,
       _eventReducer = eventReducer,
       _snapshotType = snapshotType,
       _snapshotVersion = snapshotVersion,
       _sessionFactory = sessionFactory,
       _sourceLoadTimeout = sourceLoadTimeout,
       _maxRecoveryEvents = maxRecoveryEvents,
       _maxPendingCheckpoints = maxPendingCheckpoints,
       _maxPendingCheckpointBytes = maxPendingCheckpointBytes,
       _initialSnapshotLoader = initialSnapshotLoader,
       _contextInitialSnapshotLoader = contextInitialSnapshotLoader;

  final AppRecoveryPersistenceStoreFactory _recoveryStoreFactory;
  final AppHoldemProductionSessionRoutePolicyFactory _routePolicyFactory;
  final AppHoldemProductionSessionContextRoutePolicyFactory?
  _contextRoutePolicyFactory;
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
  final int _maxRecoveryEvents;
  final int _maxPendingCheckpoints;
  final int _maxPendingCheckpointBytes;
  final AppHoldemProductionSessionInitialSnapshotLoader? _initialSnapshotLoader;
  final AppHoldemProductionSessionContextInitialSnapshotLoader?
  _contextInitialSnapshotLoader;

  Future<AppHoldemProductionSessionConfigurationLoadResult> create({
    JoinFlowSessionContext? sessionContext,
  }) async {
    final persistence = _recoveryStoreFactory.create();
    final store = persistence.store;
    if (store == null) {
      return AppHoldemProductionSessionConfigurationLoadResult.unavailable(
        warnings: persistence.warnings,
      );
    }

    try {
      final routePolicy = sessionContext == null
          ? _routePolicyFactory(store)
          : (_contextRoutePolicyFactory?.call(store, sessionContext) ??
                _routePolicyFactory(store));
      routePolicy.validate();
      final snapshotWriter = AppHoldemProductionSessionSnapshotWriter(
        store: store,
      );
      final persistenceWriter = AppHoldemProductionSessionPersistenceWriter(
        store: store,
        maxRecoveryEvents: _maxRecoveryEvents,
        snapshotWriter: snapshotWriter,
      );
      final snapshotCoordinator = AppHoldemProductionSessionSnapshotCoordinator(
        persistenceWriter: persistenceWriter,
        maxRecoveryEvents: _maxRecoveryEvents,
        maxPendingCheckpoints: _maxPendingCheckpoints,
        maxPendingCheckpointBytes: _maxPendingCheckpointBytes,
      );
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
            snapshotCoordinator: snapshotCoordinator,
            initialSnapshotLoader: _initialSnapshotLoader,
            contextInitialSnapshotLoader: _contextInitialSnapshotLoader,
            maxRecoveryEvents: _maxRecoveryEvents,
          );
      return AppHoldemProductionSessionConfigurationLoadResult.available(
        configuration: configuration,
        persistenceWriter: persistenceWriter,
        snapshotWriter: snapshotWriter,
        warnings: persistence.warnings,
      );
    } on Object {
      return AppHoldemProductionSessionConfigurationLoadResult.unavailable(
        warnings: <String>[
          ...persistence.warnings,
          'Holdem production session configuration is unavailable.',
        ],
      );
    }
  }
}

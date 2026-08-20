import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
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

const _maximumConfigurationWarningCount = 4;
const _maximumConfigurationWarningLength = 160;

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
  }) : warnings = _safeConfigurationWarnings(warnings);

  AppHoldemProductionSessionConfigurationLoadResult.unavailable({
    required List<String> warnings,
  }) : configuration = null,
       persistenceWriter = null,
       snapshotWriter = null,
       warnings = _safeConfigurationWarnings(warnings);

  final AppHoldemProductionSessionConfiguration? configuration;
  final AppHoldemProductionSessionPersistenceWriter? persistenceWriter;
  final AppHoldemProductionSessionSnapshotWriter? snapshotWriter;
  final List<String> warnings;

  bool get isAvailable => configuration != null;
}

List<String> _safeConfigurationWarnings(List<String> warnings) {
  final truncated = warnings.length > _maximumConfigurationWarningCount;
  final valueLimit = truncated
      ? _maximumConfigurationWarningCount - 1
      : _maximumConfigurationWarningCount;
  final safe = <String>[];
  for (final warning in warnings) {
    if (safe.length == valueLimit) break;
    final trimmed = warning.trim();
    safe.add(
      trimmed.isEmpty ||
              trimmed != warning ||
              warning.length > _maximumConfigurationWarningLength ||
              warning.codeUnits.any(
                (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
              )
          ? 'Holdem production session warning unavailable.'
          : warning,
    );
  }
  if (truncated) {
    safe.add('Holdem production session warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
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

  /// Composes production-session configuration from the native app-support
  /// directory without selecting product state or route policy.
  static Future<AppHoldemProductionSessionConfigurationFactory?>
  fromNativeAppSupport({
    required AppHoldemProductionSessionRoutePolicyFactory routePolicyFactory,
    AppHoldemProductionSessionContextRoutePolicyFactory?
    contextRoutePolicyFactory,
    required HoldemEventIdFactory eventIdFactory,
    required HoldemEventTimestampFactory emittedAtFactory,
    required HoldemEventHashFactory eventHashFactory,
    AppStorageDirectoryBridge? bridge,
    Future<void>? cancellation,
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
  }) async {
    final recoveryStoreFactory =
        await AppRecoveryPersistenceStoreFactory.fromNativeAppSupport(
          bridge: bridge,
          cancellation: cancellation,
        );
    if (recoveryStoreFactory == null) return null;

    return AppHoldemProductionSessionConfigurationFactory(
      recoveryStoreFactory: recoveryStoreFactory,
      routePolicyFactory: routePolicyFactory,
      contextRoutePolicyFactory: contextRoutePolicyFactory,
      eventIdFactory: eventIdFactory,
      emittedAtFactory: emittedAtFactory,
      eventHashFactory: eventHashFactory,
      identityProvisioner: identityProvisioner,
      replayAdapter: replayAdapter,
      eventReducer: eventReducer,
      snapshotType: snapshotType,
      snapshotVersion: snapshotVersion,
      sessionFactory: sessionFactory,
      sourceLoadTimeout: sourceLoadTimeout,
      maxRecoveryEvents: maxRecoveryEvents,
      maxPendingCheckpoints: maxPendingCheckpoints,
      maxPendingCheckpointBytes: maxPendingCheckpointBytes,
      initialSnapshotLoader: initialSnapshotLoader,
      contextInitialSnapshotLoader: contextInitialSnapshotLoader,
    );
  }

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
    Future<void>? cancellation,
  }) async {
    await _throwIfCancelled(cancellation);
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
        snapshotType: _snapshotType,
        snapshotVersion: _snapshotVersion,
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
            cancellation: cancellation,
          );
      await _throwIfCancelled(cancellation);
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

  Future<void> _throwIfCancelled(Future<void>? cancellation) async {
    if (cancellation == null) return;
    var cancelled = false;
    cancellation.then<void>(
      (_) => cancelled = true,
      onError: (Object _, StackTrace _) => cancelled = true,
    );
    await Future<void>.value();
    if (cancelled) {
      throw StateError(
        'Holdem production session configuration load cancelled.',
      );
    }
  }
}

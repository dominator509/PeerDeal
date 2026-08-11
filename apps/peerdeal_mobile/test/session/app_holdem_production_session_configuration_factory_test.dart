import 'dart:io';

import 'package:peerdeal_mobile/recovery/app_recovery_persistence_store_factory.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_configuration_factory.dart';
import 'package:peerdeal_mobile/session/app_persisted_holdem_production_session_source.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  test('fails closed when the recovery root is unavailable', () async {
    final result = await _create(rootDirectoryFactory: () => Directory(' '));

    expect(result.isAvailable, isFalse);
    expect(result.configuration, isNull);
    expect(result.warnings, contains('Recovery persistence root is invalid.'));
  });

  test('composes the configured route from the recovery store', () async {
    RecoveryPersistenceStore? capturedStore;
    final result = await _create(
      routePolicyFactory: (store) {
        capturedStore = store;
        return _routePolicy();
      },
    );

    expect(result.isAvailable, isTrue);
    expect(result.configuration, isNotNull);
    expect(result.persistenceWriter, isNotNull);
    expect(result.snapshotWriter, isNotNull);
    expect(capturedStore, isA<JsonFileRecoveryPersistenceStore>());
    expect(result.configuration!.routeRegistration.path, '/holdem-live');
  });

  test(
    'fails closed for an invalid route policy before native identity work',
    () async {
      final result = await _create(
        routePolicyFactory: (_) =>
            AppPersistedHoldemProductionSessionRoutePolicy(
              path: 'holdem-live',
              navigationLabel: 'Live Holdem',
              remotePeerId: 'peer_remote',
              localSeat: 1,
              closeEventAdapterFactory: (_) => throw StateError('unused'),
            ),
      );

      expect(result.isAvailable, isFalse);
      expect(
        result.warnings,
        contains('Holdem production session configuration is unavailable.'),
      );
    },
  );
}

Future<AppHoldemProductionSessionConfigurationLoadResult> _create({
  RecoveryPersistenceRootDirectoryFactory? rootDirectoryFactory,
  AppHoldemProductionSessionRoutePolicyFactory? routePolicyFactory,
}) {
  final factory = AppHoldemProductionSessionConfigurationFactory(
    recoveryStoreFactory: AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: rootDirectoryFactory ?? () => Directory.systemTemp,
    ),
    routePolicyFactory: routePolicyFactory ?? (_) => _routePolicy(),
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-11T00:00:00Z',
    eventHashFactory: (_) => 'hash',
  );
  return factory.create();
}

AppPersistedHoldemProductionSessionRoutePolicy _routePolicy() {
  return AppPersistedHoldemProductionSessionRoutePolicy(
    path: '/holdem-live',
    navigationLabel: 'Live Holdem',
    remotePeerId: 'peer_remote',
    localSeat: 1,
    closeEventAdapterFactory: (_) => throw StateError('unused'),
  );
}

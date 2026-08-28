import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_persistence_store_factory.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_configuration_factory.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_configuration_loader_factory.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_snapshot_coordinator.dart';
import 'package:peerdeal_mobile/session/app_persisted_holdem_production_session_source.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('copies and freezes configuration warning diagnostics', () {
    final warnings = <String>['warning_1'];
    final result =
        AppHoldemProductionSessionConfigurationLoadResult.unavailable(
          warnings: warnings,
        );

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('bounds and scrubs direct configuration warning diagnostics', () {
    final result =
        AppHoldemProductionSessionConfigurationLoadResult.unavailable(
          warnings: <String>[
            'warning_1',
            ' warning_2',
            'line\nfeed',
            'warning_4',
            'warning_5',
          ],
        );

    expect(result.warnings, [
      'warning_1',
      'Holdem production session warning unavailable.',
      'Holdem production session warning unavailable.',
      'Holdem production session warnings truncated.',
    ]);
  });

  test('fails closed when the recovery root is unavailable', () async {
    final result = await _create(rootDirectoryFactory: () => Directory(' '));

    expect(result.isAvailable, isFalse);
    expect(result.configuration, isNull);
    expect(result.warnings, contains('Recovery persistence root is invalid.'));
  });

  test('composes a configuration factory from native app support', () async {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_mobile_native_config_',
    );
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final factory =
        await AppHoldemProductionSessionConfigurationFactory.fromNativeAppSupport(
          bridge: _NativeSupportBridge(directory.path),
          routePolicyFactory: (_) => _routePolicy(),
          eventIdFactory: _eventId,
          emittedAtFactory: _eventTimestamp,
          eventHashFactory: (_) => 'hash',
        );

    expect(factory, isNotNull);
  });

  test(
    'returns no configuration factory when native app support is absent',
    () async {
      final factory =
          await AppHoldemProductionSessionConfigurationFactory.fromNativeAppSupport(
            bridge: const _UnavailableNativeSupportBridge(),
            routePolicyFactory: (_) => _routePolicy(),
            eventIdFactory: _eventId,
            emittedAtFactory: _eventTimestamp,
            eventHashFactory: (_) => 'hash',
          );

      expect(factory, isNull);
    },
  );

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

  test('forwards accepted join context to the configuration loader', () async {
    JoinFlowSessionContext? capturedContext;
    final context = _sessionContext();
    final loader = AppHoldemProductionSessionConfigurationLoaderFactory(
      configurationFactory: _configurationFactory(
        contextRoutePolicyFactory: (_, sessionContext) {
          capturedContext = sessionContext;
          return _routePolicy(
            path: '/holdem-seat-${sessionContext.localSeat}',
            remotePeerId: sessionContext.remotePeerId,
            localSeat: sessionContext.localSeat,
          );
        },
      ),
    );

    final result = await loader.loader(context);

    expect(result.isAvailable, isTrue);
    expect(capturedContext, same(context));
    expect(result.configuration!.routeRegistration.path, '/holdem-seat-2');
  });

  test('fails closed for an invalid recovery event limit', () async {
    final result = await _create(maxRecoveryEvents: 0);

    expect(result.isAvailable, isFalse);
    expect(
      result.warnings,
      contains('Holdem production session configuration is unavailable.'),
    );
  });

  test('fails closed for an invalid pending checkpoint limit', () async {
    final result = await _create(maxPendingCheckpoints: 0);

    expect(result.isAvailable, isFalse);
    expect(
      result.warnings,
      contains('Holdem production session configuration is unavailable.'),
    );
  });

  test('fails closed for an invalid pending checkpoint byte limit', () async {
    final result = await _create(maxPendingCheckpointBytes: 0);

    expect(result.isAvailable, isFalse);
    expect(
      result.warnings,
      contains('Holdem production session configuration is unavailable.'),
    );
  });

  test('fails closed when route policy composition throws', () async {
    final result = await _create(
      routePolicyFactory: (_) => throw StateError('route policy unavailable'),
    );

    expect(result.isAvailable, isFalse);
    expect(
      result.warnings,
      contains('Holdem production session configuration is unavailable.'),
    );
  });

  test(
    'propagates the recovery event limit into the persistence writer',
    () async {
      final result = await _create(maxRecoveryEvents: 1);
      final writer = result.persistenceWriter!;
      final tableState = TableState.initial(
        tableId: 'table_001',
        sessionId: 'session_001',
        protocolVersion: '1.0.0',
      );
      final events = <EventEnvelope>[
        _event(eventSeq: 1),
        _event(eventSeq: 2, prevEventHash: 'hash_1'),
      ];

      final persisted = writer.persist(
        snapshotId: 'snapshot_001',
        tableState: tableState,
        handState: _handState(),
        eventCursor: _cursor(nextEventSeq: 3, previousEventHash: 'hash_2'),
        events: events,
      );

      expect(persisted.isSuccess, isFalse);
      expect(
        persisted.warnings,
        contains(
          'Holdem event-log suffix exceeds the configured recovery event limit.',
        ),
      );
    },
  );

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
              sessionAuthenticator: _authenticator(),
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
  int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  int maxPendingCheckpoints = AppHoldemProductionSessionSnapshotCoordinator
      .defaultMaxPendingCheckpoints,
  int maxPendingCheckpointBytes = AppHoldemProductionSessionSnapshotCoordinator
      .defaultMaxPendingCheckpointBytes,
}) {
  return _configurationFactory(
    rootDirectoryFactory: rootDirectoryFactory,
    routePolicyFactory: routePolicyFactory,
    maxRecoveryEvents: maxRecoveryEvents,
    maxPendingCheckpoints: maxPendingCheckpoints,
    maxPendingCheckpointBytes: maxPendingCheckpointBytes,
  ).create();
}

AppHoldemProductionSessionConfigurationFactory _configurationFactory({
  RecoveryPersistenceRootDirectoryFactory? rootDirectoryFactory,
  AppHoldemProductionSessionRoutePolicyFactory? routePolicyFactory,
  AppHoldemProductionSessionContextRoutePolicyFactory?
  contextRoutePolicyFactory,
  int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  int maxPendingCheckpoints = AppHoldemProductionSessionSnapshotCoordinator
      .defaultMaxPendingCheckpoints,
  int maxPendingCheckpointBytes = AppHoldemProductionSessionSnapshotCoordinator
      .defaultMaxPendingCheckpointBytes,
}) {
  return AppHoldemProductionSessionConfigurationFactory(
    recoveryStoreFactory: AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: rootDirectoryFactory ?? () => Directory.systemTemp,
    ),
    routePolicyFactory: routePolicyFactory ?? (_) => _routePolicy(),
    contextRoutePolicyFactory: contextRoutePolicyFactory,
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-11T00:00:00Z',
    eventHashFactory: (_) => 'hash',
    maxRecoveryEvents: maxRecoveryEvents,
    maxPendingCheckpoints: maxPendingCheckpoints,
    maxPendingCheckpointBytes: maxPendingCheckpointBytes,
  );
}

AppPersistedHoldemProductionSessionRoutePolicy _routePolicy({
  String path = '/holdem-live',
  String remotePeerId = 'peer_remote',
  int localSeat = 1,
}) {
  return AppPersistedHoldemProductionSessionRoutePolicy(
    path: path,
    navigationLabel: 'Live Holdem',
    remotePeerId: remotePeerId,
    localSeat: localSeat,
    sessionAuthenticator: _authenticator(),
    closeEventAdapterFactory: (_) => throw StateError('unused'),
  );
}

HmacSha256SessionMessageAuthenticator _authenticator() {
  return HmacSha256SessionMessageAuthenticator(
    key: List<int>.generate(32, (index) => index),
  );
}

JoinFlowSessionContext _sessionContext() => JoinFlowSessionContext(
  invite: const ResolvedInvite(
    inviteId: 'invite_001',
    tableId: 'table_001',
    sessionId: 'session_001',
    modeType: 'open_table',
    protocolVersion: '1.0.0',
    requiresReceiptAck: false,
    requiresRetentionAck: false,
    requiresCaptureAck: false,
  ),
  remotePeerId: 'peer_context_remote',
  localSeat: 2,
);

HoldemHandState _handState() => HoldemHandState(
  handId: 'hand_001',
  phase: HoldemHandPhase.handIdle,
  bettingRound: HoldemBettingRound.none,
  seats: <HoldemSeatState>[],
  currentActorSeat: 0,
  buttonSeat: 0,
  smallBlindSeat: 0,
  bigBlindSeat: 1,
  currentBetToCall: 0,
  minimumRaiseAmount: 1,
);

HoldemEventCursor _cursor({
  int nextEventSeq = 1,
  String previousEventHash = genesisEventHash,
}) => HoldemEventCursor(
  protocolVersion: '1.0.0',
  tableId: 'table_001',
  sessionId: 'session_001',
  nextEventSeq: nextEventSeq,
  previousEventHash: previousEventHash,
  actorRef: 'peer_local',
  eventIdFactory: _eventId,
  emittedAtFactory: _eventTimestamp,
);

EventEnvelope _event({
  required int eventSeq,
  String prevEventHash = genesisEventHash,
}) => EventEnvelope(
  eventId: 'evt_$eventSeq',
  eventType: 'HoldemActionApplied',
  eventVersion: '1.0',
  protocolVersion: '1.0.0',
  eventSeq: eventSeq,
  tableId: 'table_001',
  sessionId: 'session_001',
  handId: null,
  emittedAt: _eventTimestamp(),
  actorRef: 'peer_local',
  payload: const <String, Object?>{},
  prevEventHash: prevEventHash,
  eventHash: 'hash_$eventSeq',
);

String _eventId(String eventType, int eventSeq) => 'evt_${eventType}_$eventSeq';

String _eventTimestamp() => '2026-08-11T00:00:00Z';

class _NativeSupportBridge implements AppStorageDirectoryBridge {
  const _NativeSupportBridge(this.path);

  final String path;

  @override
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory() async {
    return AppStorageDirectorySnapshot(available: true, directoryPath: path);
  }
}

class _UnavailableNativeSupportBridge implements AppStorageDirectoryBridge {
  const _UnavailableNativeSupportBridge();

  @override
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory() async {
    return const AppStorageDirectorySnapshot.unavailable();
  }
}

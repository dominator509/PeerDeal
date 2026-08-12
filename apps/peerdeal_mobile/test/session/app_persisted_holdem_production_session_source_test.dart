import 'dart:async';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_bootstrap.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_configuration.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_persistence_writer.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_snapshot_coordinator.dart';
import 'package:peerdeal_mobile/session/app_persisted_holdem_production_session_source.dart';
import 'package:peerdeal_mobile/session/native_local_peer_identity_loader.dart';
import 'package:peerdeal_mobile/session/native_local_peer_identity_provisioner.dart';
import 'package:peerdeal_mobile/session/native_local_peer_identity_writer.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test(
    'loads typed persisted state into the production source boundary',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final persisted = _typedSnapshot();
      _persist(store, persisted);

      HoldemStateSnapshot? captured;
      final source = _source(
        store,
        inputFactory: (invite, snapshot) {
          captured = snapshot;
          return AppHoldemProductionSessionInput(
            initialTableState: snapshot.tableState,
            initialHandState: snapshot.handState,
            initialCursor: snapshot.eventCursor,
            closeEventAdapter: _closeAdapter(snapshot.tableState),
            path: '/holdem-live',
            navigationLabel: 'Live Holdem',
            peerId: 'peer_remote',
            localPeerId: 'peer_local',
            localSeat: 1,
          );
        },
      );

      final input = await source.load(_invite());

      expect(captured?.toJson(), persisted.toJson());
      expect(input.initialTableState.toJson(), persisted.tableState.toJson());
      expect(input.initialHandState.toJson(), persisted.handState.toJson());
      expect(input.initialCursor.toJson(), persisted.eventCursor.toJson());
    },
  );

  test('composes provisioned local identity into the production input', () async {
    final store = InMemoryRecoveryPersistenceStore();
    _persist(store, _typedSnapshot());
    final identityBridge = _IdentityBridge();
    final source =
        await AppPersistedHoldemProductionSessionSource.fromProvisionedLocalIdentity(
          store: store,
          identityProvisioner: NativeLocalPeerIdentityProvisioner(
            loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
            writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
            identityFactory: () => 'peer_local',
          ),
          routePolicy: AppPersistedHoldemProductionSessionRoutePolicy(
            path: '/holdem-live',
            navigationLabel: 'Live Holdem',
            remotePeerId: 'peer_remote',
            localSeat: 1,
            closeEventAdapterFactory: (scope) => _closeAdapter(
              TableState.initial(
                tableId: scope.tableId,
                sessionId: scope.sessionId,
                protocolVersion: scope.protocolVersion,
              ),
            ),
          ),
          eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
          emittedAtFactory: () => '2026-08-10T00:00:00Z',
          eventHashFactory: computeCanonicalHash,
        );

    final input = await source.load(_invite());

    expect(input.localPeerId, 'peer_local');
    expect(input.peerId, 'peer_remote');
    expect(input.path, '/holdem-live');
    expect(identityBridge.savedKeys, hasLength(1));
  });

  test(
    'builds a stable production configuration from persisted identity',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final snapshot = _typedSnapshot();
      _persist(
        store,
        HoldemStateSnapshot(
          tableState: snapshot.tableState,
          handState: snapshot.handState.copyWith(
            seats: const <HoldemSeatState>[
              HoldemSeatState(
                seat: 1,
                stack: 100,
                inHand: false,
                folded: false,
                allIn: false,
              ),
            ],
          ),
          eventCursor: snapshot.eventCursor,
        ),
      );
      final identityBridge = _IdentityBridge();
      final configuration =
          await AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(
            store: store,
            identityProvisioner: NativeLocalPeerIdentityProvisioner(
              loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
              writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
              identityFactory: () => 'peer_local',
            ),
            routePolicy: AppPersistedHoldemProductionSessionRoutePolicy(
              path: '/holdem-live',
              navigationLabel: 'Live Holdem',
              remotePeerId: 'peer_default',
              localSeat: 1,
              closeEventAdapterFactory: (scope) => _closeAdapter(
                TableState.initial(
                  tableId: scope.tableId,
                  sessionId: scope.sessionId,
                  protocolVersion: scope.protocolVersion,
                ),
              ),
            ),
            eventIdFactory: (eventType, eventSeq) =>
                'evt_${eventType}_$eventSeq',
            emittedAtFactory: () => '2026-08-10T00:00:00Z',
            eventHashFactory: computeCanonicalHash,
          );

      expect(identityBridge.savedKeys, isEmpty);

      final composition = await configuration.routeRegistration.bootstrap
          .createForSessionContext(
            JoinFlowSessionContext(
              invite: _invite(),
              remotePeerId: 'peer_selected',
              localSeat: 1,
            ),
          );

      expect(composition.route.path, '/holdem-live');
      expect(composition.route.peerId, 'peer_selected');
      expect(identityBridge.savedKeys, hasLength(1));
    },
  );

  test(
    'defers identity provisioning until a persisted snapshot is valid',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final identityBridge = _IdentityBridge();
      final source =
          await AppPersistedHoldemProductionSessionSource.fromLocalIdentityProvisioner(
            store: store,
            identityProvisioner: NativeLocalPeerIdentityProvisioner(
              loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
              writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
              identityFactory: () => 'peer_local',
            ),
            routePolicy: _routePolicy(),
            eventIdFactory: (eventType, eventSeq) =>
                'evt_${eventType}_$eventSeq',
            emittedAtFactory: () => '2026-08-10T00:00:00Z',
            eventHashFactory: computeCanonicalHash,
          );

      expect(identityBridge.savedKeys, isEmpty);

      await expectLater(source.load(_invite()), throwsStateError);

      expect(identityBridge.savedKeys, isEmpty);
    },
  );

  test('fails closed before work begins when the load is cancelled', () async {
    final store = InMemoryRecoveryPersistenceStore();
    final identityBridge = _IdentityBridge();
    final source = await _lazySource(store, identityBridge);
    final cancellation = Completer<void>()..complete();

    await expectLater(
      source.load(_invite(), cancellation: cancellation.future),
      throwsStateError,
    );

    expect(identityBridge.savedKeys, isEmpty);
  });

  test(
    'rejects a non-positive timeout before provisioning persisted identity',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final identityBridge = _IdentityBridge();

      await expectLater(
        AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(
          store: store,
          identityProvisioner: NativeLocalPeerIdentityProvisioner(
            loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
            writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
            identityFactory: () => 'peer_local',
          ),
          routePolicy: AppPersistedHoldemProductionSessionRoutePolicy(
            path: '/holdem-live',
            navigationLabel: 'Live Holdem',
            remotePeerId: 'peer_default',
            localSeat: 1,
            closeEventAdapterFactory: (scope) => _closeAdapter(
              TableState.initial(
                tableId: scope.tableId,
                sessionId: scope.sessionId,
                protocolVersion: scope.protocolVersion,
              ),
            ),
          ),
          eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
          emittedAtFactory: () => '2026-08-10T00:00:00Z',
          eventHashFactory: computeCanonicalHash,
          sourceLoadTimeout: Duration.zero,
        ),
        throwsArgumentError,
      );

      expect(identityBridge.savedKeys, isEmpty);
    },
  );

  test(
    'rejects invalid route policy before provisioning persisted identity',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final identityBridge = _IdentityBridge();

      await expectLater(
        AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(
          store: store,
          identityProvisioner: NativeLocalPeerIdentityProvisioner(
            loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
            writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
            identityFactory: () => 'peer_local',
          ),
          routePolicy: AppPersistedHoldemProductionSessionRoutePolicy(
            path: '/holdem-live/',
            navigationLabel: 'Live Holdem',
            remotePeerId: 'peer_default',
            localSeat: 1,
            closeEventAdapterFactory: (scope) => _closeAdapter(
              TableState.initial(
                tableId: scope.tableId,
                sessionId: scope.sessionId,
                protocolVersion: scope.protocolVersion,
              ),
            ),
          ),
          eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
          emittedAtFactory: () => '2026-08-10T00:00:00Z',
          eventHashFactory: computeCanonicalHash,
        ),
        throwsArgumentError,
      );

      expect(identityBridge.savedKeys, isEmpty);
    },
  );

  test('applies verified join peer and seat to context-aware input', () async {
    final store = InMemoryRecoveryPersistenceStore();
    _persist(store, _typedSnapshot());
    final source = _source(
      store,
      contextInputFactory: (context, snapshot) =>
          AppHoldemProductionSessionInput(
            initialTableState: snapshot.tableState,
            initialHandState: snapshot.handState,
            initialCursor: snapshot.eventCursor,
            closeEventAdapter: _closeAdapter(snapshot.tableState),
            path: '/holdem-live',
            navigationLabel: 'Live Holdem',
            peerId: context.remotePeerId,
            localPeerId: 'peer_local',
            localSeat: context.localSeat,
          ),
    );

    final input = await source.loadForSessionContext(
      JoinFlowSessionContext(
        invite: _invite(),
        remotePeerId: 'peer_selected',
        localSeat: 3,
      ),
    );

    expect(input.peerId, 'peer_selected');
    expect(input.localSeat, 3);
  });

  test(
    'loads a context-aware initial snapshot for a new accepted session',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final context = JoinFlowSessionContext(
        invite: _invite(),
        remotePeerId: 'peer_selected',
        localSeat: 3,
      );
      JoinFlowSessionContext? capturedContext;
      final initial = _typedSnapshot();
      final source = _source(
        store,
        contextInputFactory: (context, snapshot) =>
            AppHoldemProductionSessionInput(
              initialTableState: snapshot.tableState,
              initialHandState: snapshot.handState,
              initialCursor: snapshot.eventCursor,
              closeEventAdapter: _closeAdapter(snapshot.tableState),
              path: '/holdem-live',
              navigationLabel: 'Live Holdem',
              peerId: context.remotePeerId,
              localPeerId: 'peer_local',
              localSeat: context.localSeat,
            ),
        snapshotCoordinator: AppHoldemProductionSessionSnapshotCoordinator(
          persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
            store: store,
          ),
        ),
        contextInitialSnapshotLoader: (sessionContext, {cancellation}) async {
          capturedContext = sessionContext;
          return initial;
        },
        initialSnapshotLoader: (_, {cancellation}) async =>
            throw StateError('invite-only loader should not be used'),
      );

      final input = await source.loadForSessionContext(context);

      expect(capturedContext, same(context));
      expect(input.initialTableState.toJson(), initial.tableState.toJson());
      expect(store.loadWindow(_scope()).snapshot, isNotNull);
    },
  );

  test('rejects an unsafe dynamic peer override before input construction', () {
    for (final peerId in <String>[
      ' peer_selected',
      'peer_${String.fromCharCode(0x85)}',
      'x' * 257,
    ]) {
      expect(
        () => _routePolicy().buildInput(
          snapshot: _typedSnapshot(),
          localPeerId: 'peer_local',
          remotePeerId: peerId,
        ),
        throwsArgumentError,
      );
    }
  });

  test(
    'rejects a non-positive dynamic seat override before input construction',
    () {
      expect(
        () => _routePolicy().buildInput(
          snapshot: _typedSnapshot(),
          localPeerId: 'peer_local',
          localSeat: 0,
        ),
        throwsArgumentError,
      );
    },
  );

  test('fails closed when no typed snapshot is persisted', () {
    final source = _source(InMemoryRecoveryPersistenceStore());

    expect(() => source.load(_invite()), throwsA(isA<StateError>()));
  });

  test('fails closed when recovery loading reports unavailable', () async {
    var initialSnapshotLoaderCalls = 0;
    final source = _source(
      _UnavailableRecoveryLoadStore(),
      initialSnapshotLoader: (_, {cancellation}) async {
        initialSnapshotLoaderCalls += 1;
        return _typedSnapshot();
      },
    );

    await expectLater(source.load(_invite()), throwsStateError);

    expect(initialSnapshotLoaderCalls, 0);
  });

  test(
    'hydrates and checkpoints an injected initial snapshot before first join',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final identityBridge = _IdentityBridge();
      final initial = _typedSnapshot();
      final source =
          await AppPersistedHoldemProductionSessionSource.fromLocalIdentityProvisioner(
            store: store,
            identityProvisioner: NativeLocalPeerIdentityProvisioner(
              loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
              writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
              identityFactory: () => 'peer_local',
            ),
            routePolicy: _routePolicy(),
            eventIdFactory: (eventType, eventSeq) =>
                'evt_${eventType}_$eventSeq',
            emittedAtFactory: () => '2026-08-12T00:00:00Z',
            eventHashFactory: computeCanonicalHash,
            snapshotCoordinator: AppHoldemProductionSessionSnapshotCoordinator(
              persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
                store: store,
              ),
            ),
            initialSnapshotLoader: (invite, {cancellation}) async {
              expect(invite.tableId, _invite().tableId);
              expect(invite.sessionId, _invite().sessionId);
              return initial;
            },
          );

      final input = await source.load(_invite());
      final persisted = store.loadWindow(_scope()).snapshot;

      expect(input.initialTableState.toJson(), initial.tableState.toJson());
      expect(identityBridge.savedKeys, hasLength(1));
      expect(persisted, isNotNull);
      expect(persisted!.snapshotBaseEventSeq, 0);
      expect(persisted.payload, initial.toJson());
    },
  );

  test(
    'rejects orphaned recovery events before initial-state provisioning',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final append = store.appendEvents(
        scope: _scope(),
        events: <EventEnvelope>[_event(1)],
      );
      expect(append.isSuccess, isTrue);

      var identityCalls = 0;
      var initialSnapshotLoaderCalls = 0;
      final source = _source(
        store,
        identityLoader: ({cancellation}) async => identityCalls += 1,
        snapshotCoordinator: AppHoldemProductionSessionSnapshotCoordinator(
          persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
            store: store,
          ),
        ),
        initialSnapshotLoader: (_, {cancellation}) async {
          initialSnapshotLoaderCalls += 1;
          return _typedSnapshot();
        },
      );

      await expectLater(
        source.load(_invite()),
        throwsA(
          predicate(
            (error) =>
                error is StateError &&
                error.message ==
                    'Persisted Holdem recovery events have no snapshot anchor.',
          ),
        ),
      );

      expect(identityCalls, 0);
      expect(initialSnapshotLoaderCalls, 0);
      expect(store.loadWindow(_scope()).snapshot, isNull);
      expect(store.loadWindow(_scope()).events, hasLength(1));
    },
  );

  test(
    'rejects an invalid initial snapshot before identity provisioning',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final identityBridge = _IdentityBridge();
      final source =
          await AppPersistedHoldemProductionSessionSource.fromLocalIdentityProvisioner(
            store: store,
            identityProvisioner: NativeLocalPeerIdentityProvisioner(
              loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
              writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
              identityFactory: () => 'peer_local',
            ),
            routePolicy: _routePolicy(),
            eventIdFactory: (eventType, eventSeq) =>
                'evt_${eventType}_$eventSeq',
            emittedAtFactory: () => '2026-08-12T00:00:00Z',
            eventHashFactory: computeCanonicalHash,
            snapshotCoordinator: AppHoldemProductionSessionSnapshotCoordinator(
              persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
                store: store,
              ),
            ),
            initialSnapshotLoader: (_, {cancellation}) async =>
                _typedSnapshot(tableId: 'table_other'),
          );

      await expectLater(
        source.load(_invite()),
        throwsA(
          predicate(
            (error) =>
                error is StateError &&
                error.message ==
                    'Initial Holdem state does not match the invite.',
          ),
        ),
      );

      expect(identityBridge.savedKeys, isEmpty);
      expect(store.loadWindow(_scope()).snapshot, isNull);
    },
  );

  test(
    'requires initial-state persistence before provisioning identity',
    () async {
      final identityBridge = _IdentityBridge();
      final source =
          await AppPersistedHoldemProductionSessionSource.fromLocalIdentityProvisioner(
            store: InMemoryRecoveryPersistenceStore(),
            identityProvisioner: NativeLocalPeerIdentityProvisioner(
              loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
              writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
              identityFactory: () => 'peer_local',
            ),
            routePolicy: _routePolicy(),
            eventIdFactory: (eventType, eventSeq) =>
                'evt_${eventType}_$eventSeq',
            emittedAtFactory: () => '2026-08-12T00:00:00Z',
            eventHashFactory: computeCanonicalHash,
            initialSnapshotLoader: (_, {cancellation}) async =>
                _typedSnapshot(),
          );

      await expectLater(
        source.load(_invite()),
        throwsA(
          predicate(
            (error) =>
                error is StateError &&
                error.message ==
                    'Initial Holdem state persistence is unavailable.',
          ),
        ),
      );
      expect(identityBridge.savedKeys, isEmpty);
    },
  );

  test(
    'rejects an oversized recovery window before snapshot processing',
    () async {
      final source = _source(_OversizedRecoveryStore(), maxRecoveryEvents: 1);

      await expectLater(
        source.load(_invite()),
        throwsA(
          predicate(
            (error) =>
                error is StateError &&
                error.message ==
                    'Persisted Holdem recovery event window exceeds the configured limit.',
          ),
        ),
      );
    },
  );

  test('fails closed when the initial checkpoint cannot be saved', () async {
    final store = _FailingSnapshotStore();
    final identityBridge = _IdentityBridge();
    final source =
        await AppPersistedHoldemProductionSessionSource.fromLocalIdentityProvisioner(
          store: store,
          identityProvisioner: NativeLocalPeerIdentityProvisioner(
            loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
            writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
            identityFactory: () => 'peer_local',
          ),
          routePolicy: _routePolicy(),
          eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
          emittedAtFactory: () => '2026-08-12T00:00:00Z',
          eventHashFactory: computeCanonicalHash,
          snapshotCoordinator: AppHoldemProductionSessionSnapshotCoordinator(
            persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
              store: store,
            ),
          ),
          initialSnapshotLoader: (_, {cancellation}) async => _typedSnapshot(),
        );

    await expectLater(source.load(_invite()), throwsStateError);
    expect(store.saveSnapshotCalls, 1);
    expect(store.loadWindow(_scope()).snapshot, isNull);
  });

  test('rejects a non-positive recovery event limit', () {
    expect(
      () => _source(_OversizedRecoveryStore(), maxRecoveryEvents: 0),
      throwsArgumentError,
    );
  });

  test('rejects an invalid eager limit before identity provisioning', () async {
    final identityBridge = _IdentityBridge();

    await expectLater(
      AppPersistedHoldemProductionSessionSource.fromProvisionedLocalIdentity(
        store: InMemoryRecoveryPersistenceStore(),
        identityProvisioner: NativeLocalPeerIdentityProvisioner(
          loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
          writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
          identityFactory: () => 'peer_local',
        ),
        routePolicy: _routePolicy(),
        eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
        emittedAtFactory: () => '2026-08-10T00:00:00Z',
        eventHashFactory: computeCanonicalHash,
        maxRecoveryEvents: 0,
      ),
      throwsArgumentError,
    );
    expect(identityBridge.savedKeys, isEmpty);
  });

  test(
    'replays a valid recovery suffix before invoking the input factory',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final persisted = _typedSnapshot();
      _persist(store, persisted);
      final issued = persisted.eventCursor.issue(
        eventType: 'OpenTableSessionOpened',
        eventId: 'evt_open_001',
        emittedAt: '2026-08-10T00:00:01Z',
        actorRef: 'system',
        payload: const <String, Object?>{'mode_type': 'open_table'},
      );
      final append = store.appendEvents(
        scope: _scope(),
        events: <EventEnvelope>[issued.event],
      );
      expect(append.isSuccess, isTrue);

      HoldemStateSnapshot? captured;
      final source = _source(
        store,
        inputFactory: (invite, snapshot) {
          captured = snapshot;
          return AppHoldemProductionSessionInput(
            initialTableState: snapshot.tableState,
            initialHandState: snapshot.handState,
            initialCursor: snapshot.eventCursor,
            closeEventAdapter: _closeAdapter(snapshot.tableState),
            path: '/holdem-live',
            navigationLabel: 'Live Holdem',
            peerId: 'peer_remote',
            localPeerId: 'peer_local',
            localSeat: 1,
          );
        },
      );

      await source.load(_invite());

      expect(captured?.tableState.phase, TablePhase.openReady);
      expect(captured?.tableState.eventSequence, 1);
      expect(captured?.eventCursor.nextEventSeq, 2);
      expect(captured?.eventCursor.previousEventHash, issued.event.eventHash);
    },
  );

  test('fails closed on unsupported snapshot versions', () {
    final store = InMemoryRecoveryPersistenceStore();
    final persisted = _typedSnapshot();
    final scope = _scope();
    final result = store.saveSnapshot(
      scope: scope,
      snapshot: SnapshotEnvelope(
        snapshotId: 'snapshot_001',
        snapshotType: 'OtherSnapshot',
        snapshotVersion: '1.0',
        protocolVersion: scope.protocolVersion,
        tableId: scope.tableId,
        sessionId: scope.sessionId,
        snapshotBaseEventSeq: 0,
        snapshotHash: computeCanonicalHash(persisted.toJson()),
        payload: persisted.toJson(),
      ),
    );
    expect(result.isSuccess, isTrue);

    expect(() => _source(store).load(_invite()), throwsA(isA<StateError>()));
  });

  test(
    'fails closed on a tampered persisted snapshot hash before identity work',
    () async {
      final persisted = _typedSnapshot();
      final store = _SnapshotRecoveryStore(
        _snapshotEnvelope(persisted, snapshotHash: 'tampered_hash'),
      );
      var identityCalls = 0;
      final source = _source(
        store,
        identityLoader: ({cancellation}) async => identityCalls += 1,
      );

      await expectLater(
        source.load(_invite()),
        throwsA(
          predicate(
            (error) =>
                error is StateError &&
                error.message == 'Persisted Holdem snapshot hash is invalid.',
          ),
        ),
      );
      expect(identityCalls, 0);
    },
  );

  test(
    'fails closed on unsafe persisted snapshot metadata before identity work',
    () async {
      final cases =
          <({String id, String type, String version, String warning})>[
            (
              id: 'snapshot_${String.fromCharCode(0x85)}',
              type: 'HoldemStateSnapshot',
              version: '1.0',
              warning: 'Persisted Holdem snapshot identity is invalid.',
            ),
            (
              id: 'snapshot_001',
              type: 'HoldemState${String.fromCharCode(0x85)}',
              version: '1.0',
              warning: 'Persisted Holdem snapshot type is invalid.',
            ),
            (
              id: 'snapshot_001',
              type: 'HoldemStateSnapshot',
              version: '1.${String.fromCharCode(0x85)}',
              warning: 'Persisted Holdem snapshot version is invalid.',
            ),
          ];
      for (final testCase in cases) {
        final store = InMemoryRecoveryPersistenceStore();
        _persist(
          store,
          _typedSnapshot(),
          snapshotId: testCase.id,
          snapshotType: testCase.type,
          snapshotVersion: testCase.version,
        );
        var identityCalls = 0;
        final source = _source(
          store,
          identityLoader: ({cancellation}) async => identityCalls += 1,
        );

        await expectLater(
          source.load(_invite()),
          throwsA(
            predicate(
              (error) =>
                  error is StateError && error.message == testCase.warning,
            ),
          ),
        );
        expect(identityCalls, 0);
      }
    },
  );

  test('fails closed on an unsupported recovery suffix event', () {
    final store = InMemoryRecoveryPersistenceStore();
    _persist(store, _typedSnapshot());
    final append = store.appendEvents(
      scope: _scope(),
      events: <EventEnvelope>[
        EventEnvelope(
          eventId: 'evt_suffix_1',
          eventType: 'RecoveryEventPersisted',
          eventVersion: '1.0',
          protocolVersion: '1.0.0',
          eventSeq: 1,
          tableId: 'table_001',
          sessionId: 'session_001',
          handId: null,
          emittedAt: '2026-08-10T00:00:00Z',
          actorRef: 'system',
          payload: const <String, Object?>{},
          prevEventHash: genesisEventHash,
          eventHash: 'hash_suffix_1',
        ),
      ],
    );
    expect(append.isSuccess, isTrue);

    expect(() => _source(store).load(_invite()), throwsA(isA<StateError>()));
  });
}

AppPersistedHoldemProductionSessionRoutePolicy _routePolicy() {
  return AppPersistedHoldemProductionSessionRoutePolicy(
    path: '/holdem-live',
    navigationLabel: 'Live Holdem',
    remotePeerId: 'peer_remote',
    localSeat: 1,
    closeEventAdapterFactory: (scope) => _closeAdapter(
      TableState.initial(
        tableId: scope.tableId,
        sessionId: scope.sessionId,
        protocolVersion: scope.protocolVersion,
      ),
    ),
  );
}

Future<AppPersistedHoldemProductionSessionSource> _lazySource(
  InMemoryRecoveryPersistenceStore store,
  _IdentityBridge identityBridge,
) {
  return AppPersistedHoldemProductionSessionSource.fromLocalIdentityProvisioner(
    store: store,
    identityProvisioner: NativeLocalPeerIdentityProvisioner(
      loader: NativeLocalPeerIdentityLoader(bridge: identityBridge),
      writer: NativeLocalPeerIdentityWriter(bridge: identityBridge),
      identityFactory: () => 'peer_local',
    ),
    routePolicy: _routePolicy(),
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-10T00:00:00Z',
    eventHashFactory: computeCanonicalHash,
  );
}

AppPersistedHoldemProductionSessionSource _source(
  RecoveryPersistenceStore store, {
  AppHoldemProductionSessionInputFactory? inputFactory,
  AppHoldemProductionSessionContextInputFactory? contextInputFactory,
  Future<void> Function({Future<void>? cancellation})? identityLoader,
  AppHoldemProductionSessionSnapshotCoordinator? snapshotCoordinator,
  AppHoldemProductionSessionInitialSnapshotLoader? initialSnapshotLoader,
  AppHoldemProductionSessionContextInitialSnapshotLoader?
  contextInitialSnapshotLoader,
  int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
}) {
  return AppPersistedHoldemProductionSessionSource(
    store: store,
    inputFactory:
        inputFactory ??
        (invite, snapshot) => AppHoldemProductionSessionInput(
          initialTableState: snapshot.tableState,
          initialHandState: snapshot.handState,
          initialCursor: snapshot.eventCursor,
          closeEventAdapter: _closeAdapter(snapshot.tableState),
          path: '/holdem-live',
          navigationLabel: 'Live Holdem',
          peerId: 'peer_remote',
          localPeerId: 'peer_local',
          localSeat: 1,
        ),
    contextInputFactory: contextInputFactory,
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-10T00:00:00Z',
    eventHashFactory: computeCanonicalHash,
    identityLoader: identityLoader,
    snapshotCoordinator: snapshotCoordinator,
    initialSnapshotLoader: initialSnapshotLoader,
    contextInitialSnapshotLoader: contextInitialSnapshotLoader,
    maxRecoveryEvents: maxRecoveryEvents,
  );
}

class _OversizedRecoveryStore implements RecoveryPersistenceStore {
  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) => RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) => RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) =>
      RecoveryPersistenceResult.success();

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) =>
      PersistedRecoveryWindow(events: <EventEnvelope>[_event(1), _event(2)]);
}

class _SnapshotRecoveryStore extends _OversizedRecoveryStore {
  _SnapshotRecoveryStore(this.snapshot);

  final SnapshotEnvelope snapshot;

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    return PersistedRecoveryWindow(snapshot: snapshot, events: const []);
  }
}

class _UnavailableRecoveryLoadStore extends _OversizedRecoveryStore
    implements RecoveryPersistenceLoadResultStore {
  @override
  RecoveryPersistenceLoadResult loadWindowResult(
    RecoveryPersistenceScope scope,
  ) {
    return RecoveryPersistenceLoadResult.failure(
      conflicts: <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_FILE_CORRUPT',
          message: 'Recovery persistence file could not be decoded.',
          severity: SyncConflictSeverity.fatal,
        ),
      ],
    );
  }
}

class _FailingSnapshotStore extends _OversizedRecoveryStore {
  int saveSnapshotCalls = 0;

  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) {
    saveSnapshotCalls += 1;
    return RecoveryPersistenceResult(
      isSuccess: false,
      warnings: <String>['initial snapshot save failed'],
    );
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    return PersistedRecoveryWindow(events: <EventEnvelope>[]);
  }
}

EventEnvelope _event(int eventSeq) {
  return EventEnvelope(
    eventId: 'evt_$eventSeq',
    eventType: 'RecoveryEventPersisted',
    eventVersion: '1.0',
    protocolVersion: '1.0.0',
    eventSeq: eventSeq,
    tableId: 'table_001',
    sessionId: 'session_001',
    handId: null,
    emittedAt: '2026-08-10T00:00:00Z',
    actorRef: 'system',
    payload: const <String, Object?>{},
    prevEventHash: eventSeq == 1 ? genesisEventHash : 'hash_${eventSeq - 1}',
    eventHash: 'hash_$eventSeq',
  );
}

void _persist(
  RecoveryPersistenceStore store,
  HoldemStateSnapshot state, {
  String? snapshotHash,
  String snapshotId = 'snapshot_001',
  String snapshotType = 'HoldemStateSnapshot',
  String snapshotVersion = '1.0',
}) {
  final scope = _scope();
  final result = store.saveSnapshot(
    scope: scope,
    snapshot: _snapshotEnvelope(
      state,
      snapshotHash: snapshotHash,
      snapshotId: snapshotId,
      snapshotType: snapshotType,
      snapshotVersion: snapshotVersion,
    ),
  );
  expect(result.isSuccess, isTrue);
}

SnapshotEnvelope _snapshotEnvelope(
  HoldemStateSnapshot state, {
  String? snapshotHash,
  String snapshotId = 'snapshot_001',
  String snapshotType = 'HoldemStateSnapshot',
  String snapshotVersion = '1.0',
}) {
  final scope = _scope();
  return SnapshotEnvelope(
    snapshotId: snapshotId,
    snapshotType: snapshotType,
    snapshotVersion: snapshotVersion,
    protocolVersion: scope.protocolVersion,
    tableId: scope.tableId,
    sessionId: scope.sessionId,
    snapshotBaseEventSeq: state.tableState.eventSequence,
    snapshotHash: snapshotHash ?? computeCanonicalHash(state.toJson()),
    payload: state.toJson(),
  );
}

HoldemStateSnapshot _typedSnapshot({
  String tableId = 'table_001',
  String sessionId = 'session_001',
  String protocolVersion = '1.0.0',
}) {
  return HoldemStateSnapshot(
    tableState: TableState.initial(
      tableId: tableId,
      sessionId: sessionId,
      protocolVersion: protocolVersion,
    ),
    handState: HoldemHandState(
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
    ),
    eventCursor: HoldemEventCursor(
      protocolVersion: protocolVersion,
      tableId: tableId,
      sessionId: sessionId,
      nextEventSeq: 1,
      previousEventHash: genesisEventHash,
      actorRef: 'peer_local',
      eventIdFactory: _eventId,
      emittedAtFactory: _eventTimestamp,
    ),
  );
}

String _eventId(String eventType, int eventSeq) => 'evt_${eventType}_$eventSeq';

String _eventTimestamp() => '2026-08-10T00:00:00Z';

ResolvedInvite _invite() => const ResolvedInvite(
  inviteId: 'invite_001',
  tableId: 'table_001',
  sessionId: 'session_001',
  modeType: 'open_table',
  protocolVersion: '1.0.0',
  requiresReceiptAck: false,
  requiresRetentionAck: false,
  requiresCaptureAck: false,
);

RecoveryPersistenceScope _scope() => const RecoveryPersistenceScope(
  tableId: 'table_001',
  sessionId: 'session_001',
  protocolVersion: '1.0.0',
);

AppRecoverySessionCloseEventAdapter _closeAdapter(TableState state) {
  return AppRecoverySessionCloseEventAdapter(
    sessionCloseCoordinator: AppRecoverySessionCloseCoordinator(
      retentionCoordinator: AppRecoveryRetentionCoordinator(
        store: InMemoryRecoveryPersistenceStore(),
      ),
      scope: RecoveryPersistenceScope(
        tableId: state.tableId,
        sessionId: state.sessionId,
        protocolVersion: state.protocolVersion,
      ),
      policy: _policy,
    ),
  );
}

const _policy = RetentionPolicy(
  mode: RetentionMode.timedSandbox,
  wipeSchedule: WipeSchedule(
    mode: 'timed_sandbox',
    timedWipeSeconds: 0,
    durableExportAllowed: true,
    ephemeralExportOnly: false,
  ),
  manualWipeConfirmation: ManualWipeConfirmation(
    requiresSecondConfirmation: true,
    confirmationPhrase: 'WIPE RECEIPT',
  ),
  allowSessionRestore: true,
  allowUserRestore: false,
  disappearingPolicy: DisappearingPolicy(
    disappearingChatEnabled: false,
    disappearingSessionMode: false,
    messageRetentionPolicy: MessageRetentionPolicy.standard,
  ),
  metadataProfile: MetadataMinimizationProfile(
    minimizeMetadata: true,
    exportMinimalIdentity: true,
    allowPseudonymousAliases: true,
    allowDeviceIdentifiers: false,
    allowIpAddressCapture: false,
  ),
);

class _IdentityBridge implements SecureKeyStorageMutationBridge {
  final List<SecureKeyRecord> keys = <SecureKeyRecord>[];
  final List<SecureKeyRecord> savedKeys = <SecureKeyRecord>[];

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({required String namespace}) {
    return Future<SecureKeyStorageSnapshot>.value(
      SecureKeyStorageSnapshot(
        available: true,
        keys: List<SecureKeyRecord>.unmodifiable(keys),
      ),
    );
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
  }) async {
    keys.removeWhere((record) => record.keyId == key.keyId);
    keys.add(key);
    savedKeys.add(key);
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
  }) async {
    keys.removeWhere((record) => record.keyId == keyId);
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }
}

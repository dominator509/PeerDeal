import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_network_confidence_presenter.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_bootstrap_candidate_loader.dart';
import 'package:peerdeal_desktop/demo_slice/scenarios/demo_scenario_snapshots.dart';
import 'package:peerdeal_desktop/demo_slice/screens/demo_table_screen.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_persistence_store_factory.dart';
import 'package:peerdeal_desktop/transport/app_table_session_transport_source.dart';
import 'package:peerdeal_desktop/transport/native_transport_frame_adapter.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

void main() {
  test('snapshots demo recovery warning lists', () {
    final availableWarnings = <String>['available_warning'];
    final available = DemoRecoveryPersistenceLoadResult.available(
      persistedEventCount: 1,
      hasSnapshot: true,
      warnings: availableWarnings,
    );
    final unavailableWarnings = <String>['unavailable_warning'];
    final unavailable = DemoRecoveryPersistenceLoadResult.unavailable(
      warnings: unavailableWarnings,
    );

    availableWarnings.add('later_available_warning');
    unavailableWarnings.add('later_unavailable_warning');

    expect(available.warnings, ['available_warning']);
    expect(unavailable.warnings, ['unavailable_warning']);
    expect(() => available.warnings.add('mutated'), throwsUnsupportedError);
    expect(() => unavailable.warnings.add('mutated'), throwsUnsupportedError);
  });

  testWidgets('scrubs table bootstrap and recovery warnings before rendering', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoTableScreen(
          snapshot: DemoScenarioSnapshots.snapshots.values.first,
          networkConfidence: const DemoNetworkConfidenceVm(
            confidence: NetworkConfidence.stable,
            recoveryRecommended: false,
          ),
          bootstrap: NativeBootstrapCandidateLoadResult(
            discoveryAvailable: true,
            nativeNotes: 'ready',
            candidates: <BootstrapCandidate>[
              BootstrapCandidate(
                peerId: 'peer_1',
                routeClass: NetworkRouteClass.lanDirect,
                reachable: true,
                priority: 0,
              ),
            ],
            warnings: <String>[r'C:\secret\peers.log'],
          ),
          recoveryPersistence: DemoRecoveryPersistenceLoadResult.available(
            persistedEventCount: 1,
            hasSnapshot: false,
            warnings: <String>['token sk-demo-secret'],
          ),
          onOpenChat: null,
          onOpenReceipt: null,
        ),
      ),
    );

    expect(
      find.text(
        'Bootstrap warning: Local network bootstrap warning unavailable.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Recovery persistence warning: '
        'Recovery persistence warning unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('renders safe table warnings unchanged', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoTableScreen(
          snapshot: DemoScenarioSnapshots.snapshots.values.first,
          networkConfidence: const DemoNetworkConfidenceVm(
            confidence: NetworkConfidence.stable,
            recoveryRecommended: false,
          ),
          bootstrap: NativeBootstrapCandidateLoadResult.unavailable(
            nativeNotes: 'unavailable',
            warnings: <String>['Local network bootstrap loader unavailable.'],
          ),
          recoveryPersistence: DemoRecoveryPersistenceLoadResult.unavailable(
            warnings: <String>[
              'Recovery persistence store factory unavailable.',
            ],
          ),
          onOpenChat: null,
          onOpenReceipt: null,
        ),
      ),
    );

    expect(
      find.text(
        'Bootstrap warning: Local network bootstrap loader unavailable.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Recovery persistence warning: '
        'Recovery persistence store factory unavailable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('reloads recovery persistence when runtime scope changes', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_desktop_table_scope_reload_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final factory = AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => directory,
    );
    final store = factory.create().store!;
    const firstScope = RecoveryPersistenceScope(
      tableId: 'prod_table_a',
      sessionId: 'prod_session_a',
      protocolVersion: '1.x',
    );
    const secondScope = RecoveryPersistenceScope(
      tableId: 'prod_table_b',
      sessionId: 'prod_session_b',
      protocolVersion: '1.x',
    );

    expect(
      store
          .appendEvents(
            scope: firstScope,
            events: <EventEnvelope>[
              _recoveryEvent(
                seq: 1,
                prevHash: genesisEventHash,
                hash: 'hash_a_1',
                tableId: firstScope.tableId,
                sessionId: firstScope.sessionId,
              ),
            ],
          )
          .isSuccess,
      isTrue,
    );
    expect(
      store
          .appendEvents(
            scope: secondScope,
            events: <EventEnvelope>[
              _recoveryEvent(
                seq: 1,
                prevHash: genesisEventHash,
                hash: 'hash_b_1',
                tableId: secondScope.tableId,
                sessionId: secondScope.sessionId,
              ),
              _recoveryEvent(
                seq: 2,
                prevHash: 'hash_b_1',
                hash: 'hash_b_2',
                tableId: secondScope.tableId,
                sessionId: secondScope.sessionId,
              ),
            ],
          )
          .isSuccess,
      isTrue,
    );

    await tester.pumpWidget(
      _tableRoute(
        recoveryPersistenceStoreFactory: factory,
        runtimeScopeFactory: (_) => firstScope,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recovery persistence: 1 events'), findsOneWidget);

    await tester.pumpWidget(
      _tableRoute(
        recoveryPersistenceStoreFactory: factory,
        runtimeScopeFactory: (_) => secondScope,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recovery persistence: 2 events'), findsOneWidget);
  });

  testWidgets('mounts and disposes the optional route transport source', (
    tester,
  ) async {
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      drain: () async => NativeTransportFrameDrainResult(
        available: true,
        results: <TransportFrameReceiveResult>[],
      ),
    );

    await tester.pumpWidget(
      _tableRoute(
        recoveryPersistenceStoreFactory: null,
        runtimeScopeFactory: (_) => const RecoveryPersistenceScope(
          tableId: 'table_1',
          sessionId: 'session_1',
          protocolVersion: '1.x',
        ),
        transportSource: source,
      ),
    );
    expect(source.state, AppTableSessionTransportSourceState.running);

    await tester.pumpWidget(const SizedBox());
    expect(source.state, AppTableSessionTransportSourceState.disposed);
  });

  testWidgets('fails closed when recovery loading reports unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tableRoute(
        recoveryPersistenceStoreFactory: _UnavailableRecoveryFactory(),
        runtimeScopeFactory: (_) => const RecoveryPersistenceScope(
          tableId: 'table_1',
          sessionId: 'session_1',
          protocolVersion: '1.x',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recovery persistence: unavailable'), findsOneWidget);
    expect(
      find.text(
        'Recovery persistence warning: '
        'Recovery persistence window unavailable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('cancels bootstrap loaders on replacement and disposal', (
    tester,
  ) async {
    final firstLoader = _TrackingNativeBootstrapCandidateLoader();
    final secondLoader = _TrackingNativeBootstrapCandidateLoader();
    final scope = const RecoveryPersistenceScope(
      tableId: 'table_1',
      sessionId: 'session_1',
      protocolVersion: '1.x',
    );

    await tester.pumpWidget(
      _tableRoute(
        recoveryPersistenceStoreFactory: null,
        runtimeScopeFactory: (_) => scope,
        bootstrapCandidateLoaderFactory: () => firstLoader,
      ),
    );
    expect(firstLoader.cancelled, isFalse);

    await tester.pumpWidget(
      _tableRoute(
        recoveryPersistenceStoreFactory: null,
        runtimeScopeFactory: (_) => scope,
        bootstrapCandidateLoaderFactory: () => secondLoader,
      ),
    );
    expect(firstLoader.cancelled, isTrue);
    expect(secondLoader.cancelled, isFalse);

    await tester.pumpWidget(const SizedBox());
    expect(secondLoader.cancelled, isTrue);
  });
}

Widget _tableRoute({
  required AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory,
  required DemoTableRuntimeScopeFactory runtimeScopeFactory,
  AppTableSessionTransportSource? transportSource,
  NativeBootstrapCandidateLoaderFactory? bootstrapCandidateLoaderFactory,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: DemoTableRoute(
      snapshot: DemoScenarioSnapshots.snapshots.values.first,
      networkConfidence: const DemoNetworkConfidenceVm(
        confidence: NetworkConfidence.stable,
        recoveryRecommended: false,
      ),
      bootstrapCandidateLoaderFactory:
          bootstrapCandidateLoaderFactory ??
          (() => NativeBootstrapCandidateLoader(
            bridge: const _NoDiscoveryBridge(),
          )),
      recoveryPersistenceStoreFactory: recoveryPersistenceStoreFactory,
      transportSource: transportSource,
      runtimeScopeFactory: runtimeScopeFactory,
      onOpenChat: null,
      onOpenReceipt: null,
    ),
  );
}

EventEnvelope _recoveryEvent({
  required int seq,
  required String prevHash,
  required String hash,
  required String tableId,
  required String sessionId,
}) {
  return EventEnvelope(
    eventId: 'evt_$hash',
    eventType: 'RecoveryEventPersisted',
    eventVersion: '1.0',
    protocolVersion: '1.x',
    eventSeq: seq,
    tableId: tableId,
    sessionId: sessionId,
    handId: null,
    emittedAt: '2026-06-08T00:00:00Z',
    actorRef: 'system',
    payload: const <String, Object?>{},
    prevEventHash: prevHash,
    eventHash: hash,
  );
}

class _NoDiscoveryBridge implements LocalNetworkBridge {
  const _NoDiscoveryBridge();

  @override
  Future<LocalNetworkCapability> getCapability() async {
    return const LocalNetworkCapability.unavailable();
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    return const LocalNetworkDiscoverySnapshot.unavailable();
  }
}

class _TrackingNativeBootstrapCandidateLoader
    extends NativeBootstrapCandidateLoader {
  _TrackingNativeBootstrapCandidateLoader()
    : super(bridge: const _NoDiscoveryBridge());

  bool cancelled = false;

  @override
  void cancel() {
    cancelled = true;
    super.cancel();
  }
}

class _UnavailableRecoveryFactory extends AppRecoveryPersistenceStoreFactory {
  _UnavailableRecoveryFactory()
    : super(rootDirectoryFactory: () => Directory.systemTemp);

  @override
  AppRecoveryPersistenceStoreLoadResult create() {
    return AppRecoveryPersistenceStoreLoadResult.available(
      store: _UnavailableRecoveryStore(),
    );
  }
}

class _UnavailableRecoveryStore extends InMemoryRecoveryPersistenceStore {
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

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_network_confidence_presenter.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_bootstrap_candidate_loader.dart';
import 'package:peerdeal_desktop/demo_slice/scenarios/demo_scenario_snapshots.dart';
import 'package:peerdeal_desktop/demo_slice/screens/demo_table_screen.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_persistence_store_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

void main() {
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
          bootstrap: const NativeBootstrapCandidateLoadResult(
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
          recoveryPersistence:
              const DemoRecoveryPersistenceLoadResult.available(
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
          bootstrap: const NativeBootstrapCandidateLoadResult.unavailable(
            nativeNotes: 'unavailable',
            warnings: <String>['Local network bootstrap loader unavailable.'],
          ),
          recoveryPersistence:
              const DemoRecoveryPersistenceLoadResult.unavailable(
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
}

Widget _tableRoute({
  required AppRecoveryPersistenceStoreFactory recoveryPersistenceStoreFactory,
  required DemoTableRuntimeScopeFactory runtimeScopeFactory,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: DemoTableRoute(
      snapshot: DemoScenarioSnapshots.snapshots.values.first,
      networkConfidence: const DemoNetworkConfidenceVm(
        confidence: NetworkConfidence.stable,
        recoveryRecommended: false,
      ),
      bootstrapCandidateLoaderFactory: () =>
          NativeBootstrapCandidateLoader(bridge: const _NoDiscoveryBridge()),
      recoveryPersistenceStoreFactory: recoveryPersistenceStoreFactory,
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

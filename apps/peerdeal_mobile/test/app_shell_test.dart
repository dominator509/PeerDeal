import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_artifact_verifier_factory.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_bootstrap_candidate_loader.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_export_artifact_factory.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_key_ring_provisioner.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_key_ring_writer.dart';
import 'package:peerdeal_mobile/demo_slice/models/demo_scenario_snapshot.dart';
import 'package:peerdeal_mobile/join_flow/demo_join_flow_orchestrator_factory.dart';
import 'package:peerdeal_mobile/join_flow/fakes.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/main.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_persistence_store_factory.dart';
import 'package:peerdeal_mobile/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_wizard/peerdeal_wizard.dart';

import '../../../tools/test_helpers/demo_receipt_route_test_support.dart';

void main() {
  testWidgets('mounts demo home instead of placeholder root', (tester) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
          bootstrapCoordinator: FakeBootstrapCoordinator(),
        ).create,
      ),
    );

    expect(find.byType(Placeholder), findsNothing);
    expect(find.text('PeerDeal demo'), findsOneWidget);
    expect(
      find.textContaining('Verification / Receipt Review'),
      findsOneWidget,
    );
  });

  testWidgets('routes from demo home to receipt surface', (tester) async {
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(
        bridge: RecordingCaptureProtectionBridge(),
      ),
    );

    await tester.pumpWidget(PeerDealMobileApp(presenter: presenter));

    await tester.tap(find.text('Receipt'));
    await tester.pump();
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('routes receipt artifacts through app-owned verifier factory', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final keyBridge = RecordingReceiptKeyStorageBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(
      PeerDealMobileApp(
        presenter: presenter,
        receiptExportArtifact: signedDemoReceiptArtifact(),
        receiptArtifactVerifierFactory: DemoReceiptArtifactVerifierFactory(
          bridge: keyBridge,
        ),
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(keyBridge.namespaces, <String>['peerdeal.receipts']);
    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('exports receipt artifacts through app-owned export factory', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final keyBridge = _RecordingReceiptKeyStorageMutationBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(
      PeerDealMobileApp(
        presenter: presenter,
        receiptExportArtifactFactory: NativeReceiptExportArtifactFactory(
          keyRingProvisioner: NativeReceiptKeyRingProvisioner(
            loader: NativeReceiptKeyRingLoader(bridge: keyBridge),
            writer: NativeReceiptKeyRingWriter(bridge: keyBridge),
          ),
          nonceFactory: () => List<int>.filled(32, 9),
        ).exportSignedEncrypted,
        receiptArtifactVerifierFactory: DemoReceiptArtifactVerifierFactory(
          bridge: keyBridge,
        ),
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(keyBridge.savedKeys.map((saved) => saved.key.purpose), <String>[
      'receipt_signing',
      'receipt_encryption',
    ]);
    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('exports receipts through app-owned receipt factory', (
    tester,
  ) async {
    String? exportedUserId;

    await tester.pumpWidget(
      PeerDealMobileApp(
        receiptFactory: (snapshot) =>
            _receiptForSnapshot(snapshot, pseudonymousUserId: 'user_injected'),
        receiptExportArtifactFactory: (receipt) async {
          exportedUserId = receipt.pseudonymousUserId;
          return const ReceiptExportArtifact.unavailable(
            reason: 'test artifact unavailable',
          );
        },
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(exportedUserId, 'user_injected');
  });

  testWidgets('fails closed when receipt factory has no export path', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(
      PeerDealMobileApp(
        presenter: presenter,
        receiptFactory: (snapshot) =>
            _receiptForSnapshot(snapshot, pseudonymousUserId: 'user_injected'),
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('fails closed when app-owned receipt factory throws', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );
    var exportCalled = false;

    await tester.pumpWidget(
      PeerDealMobileApp(
        presenter: presenter,
        receiptFactory: (_) {
          throw StateError('receipt source unavailable');
        },
        receiptExportArtifactFactory: (receipt) async {
          exportCalled = true;
          return const ReceiptExportArtifact.unavailable(
            reason: 'test artifact unavailable',
          );
        },
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(exportCalled, isFalse);
    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('fails closed when receipt verifier factory throws', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(
      PeerDealMobileApp(
        presenter: presenter,
        receiptExportArtifact: signedDemoReceiptArtifact(),
        receiptArtifactVerifierFactory: _ThrowingVerifierFactory(),
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('routes recovery scenario through mounted receipt recovery', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(PeerDealMobileApp(presenter: presenter));

    await tester.tap(
      find.text('Scenario: Recovery Pause - Primary-Peer Transfer'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(captureBridge.requestCount, 2);
    expect(find.text('Receipt content hidden'), findsOneWidget);
    expect(find.textContaining('ERR_FINAL_EVENT_HASH_MISMATCH'), findsNothing);
    expect(find.textContaining('expected_hash'), findsNothing);
    expect(find.textContaining('actual_hash'), findsNothing);
  });

  testWidgets('routes from demo home through table and chat surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Demo table'), findsOneWidget);
    expect(find.text('Scenario: open_table_live_turn'), findsOneWidget);
    expect(find.text('Network: stable'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Demo chat'), findsOneWidget);
    expect(find.text('Scenario: open_table_live_turn'), findsOneWidget);
    expect(find.text('Unread: 3'), findsOneWidget);
  });

  testWidgets('mounted table loads native bootstrap candidates', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        bootstrapCandidateLoaderFactory: () => NativeBootstrapCandidateLoader(
          bridge: const _StaticLocalNetworkBridge(),
        ),
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Bootstrap: 2 candidates'), findsOneWidget);
    expect(find.text('Bootstrap route: lanDirect'), findsOneWidget);
  });

  testWidgets('routes table dependencies through app runtime object', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        runtime: PeerDealMobileRuntime(
          bootstrapCandidateLoaderFactory: () => NativeBootstrapCandidateLoader(
            bridge: const _StaticLocalNetworkBridge(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Bootstrap: 2 candidates'), findsOneWidget);
    expect(find.text('Bootstrap route: lanDirect'), findsOneWidget);
  });

  testWidgets('constructor dependencies override app runtime object', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        runtime: PeerDealMobileRuntime(
          bootstrapCandidateLoaderFactory: () {
            throw StateError('runtime bootstrap unavailable');
          },
        ),
        bootstrapCandidateLoaderFactory: () => NativeBootstrapCandidateLoader(
          bridge: const _StaticLocalNetworkBridge(),
        ),
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Bootstrap: 2 candidates'), findsOneWidget);
    expect(find.text('Bootstrap route: lanDirect'), findsOneWidget);
  });

  testWidgets('mounted table fails closed when bootstrap factory throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        bootstrapCandidateLoaderFactory: () {
          throw StateError('bootstrap unavailable');
        },
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Bootstrap: unavailable'), findsOneWidget);
    expect(
      find.text(
        'Bootstrap warning: Local network bootstrap loader unavailable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('mounted table fails closed without recovery persistence root', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Recovery persistence: unavailable'), findsOneWidget);
    expect(
      find.text(
        'Recovery persistence warning: '
        'Recovery persistence store factory unavailable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('mounted table loads app-provided recovery persistence window', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_mobile_mounted_recovery_',
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
    final append = store.appendEvents(
      scope: const RecoveryPersistenceScope(
        tableId: 'open_table_live_turn',
        sessionId: 'demo:open_table_live_turn',
        protocolVersion: '1.x',
      ),
      events: <EventEnvelope>[
        _recoveryEvent(seq: 1, prevHash: 'genesis', hash: 'hash_1'),
      ],
    );
    expect(append.isSuccess, isTrue);

    await tester.pumpWidget(
      PeerDealMobileApp(recoveryPersistenceStoreFactory: factory),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Recovery persistence: 1 events'), findsOneWidget);
  });

  testWidgets('mounted table loads app-provided runtime recovery scope', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_mobile_mounted_runtime_scope_',
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
    const scope = RecoveryPersistenceScope(
      tableId: 'prod_table_1',
      sessionId: 'prod_session_1',
      protocolVersion: '1.x',
    );
    final append = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _recoveryEvent(
          seq: 1,
          prevHash: 'genesis',
          hash: 'hash_1',
          tableId: scope.tableId,
          sessionId: scope.sessionId,
        ),
      ],
    );
    expect(append.isSuccess, isTrue);

    await tester.pumpWidget(
      PeerDealMobileApp(
        recoveryPersistenceStoreFactory: factory,
        tableRuntimeScopeFactory: (_) => scope,
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Recovery persistence: 1 events'), findsOneWidget);
  });

  testWidgets('mounted table fails closed when runtime scope throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        bootstrapCandidateLoaderFactory: () => NativeBootstrapCandidateLoader(
          bridge: const _StaticLocalNetworkBridge(),
        ),
        tableRuntimeScopeFactory: (_) {
          throw StateError('runtime scope unavailable');
        },
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Bootstrap: unavailable'), findsOneWidget);
    expect(find.text('Recovery persistence: unavailable'), findsOneWidget);
  });

  testWidgets('routes from demo home to join flow', (tester) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
          bootstrapCoordinator: FakeBootstrapCoordinator(),
        ).create,
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pump();

    expect(find.text('Loading join'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Join flow'), findsOneWidget);
    expect(find.text('State: joined'), findsOneWidget);
    expect(find.text('Result: OK_JOINED'), findsOneWidget);
  });

  testWidgets('routes join through app-owned invite context factory', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
          bootstrapCoordinator: FakeBootstrapCoordinator(),
        ).create,
        joinFlowInviteContextFactory: (_) => const InviteContext(
          inviteCode: 'ABC123',
          requestedRole: RequestedRole.player,
        ),
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run rejoin'));
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_REJOIN_TOKEN_REQUIRED'), findsOneWidget);
  });

  testWidgets('routes from demo home to setup flow', (tester) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    await tester.tap(find.text('Setup'));
    await tester.pump();

    expect(find.text('Loading setup'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Setup flow'), findsOneWidget);
    expect(find.text('Status: compiled'), findsOneWidget);
    expect(find.text('Result: OK_GAME_FILE_COMPILED'), findsOneWidget);
  });

  testWidgets('fails closed when app-owned setup factory throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        setupFlowOrchestratorFactory: () {
          throw StateError('setup flow unavailable');
        },
      ),
    );

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_FLOW_UNAVAILABLE'), findsOneWidget);
  });

  testWidgets('routes setup through app-owned setup intent factory', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        setupFlowIntentFactory: (_) => const SetupIntent(
          intentId: 'intent_shell_invalid',
          sourceType: SetupSurface.simple,
          hostPseudonymousId: 'host_shell',
          modePreference: 'open_table',
          variantPreference: 'holdem_nlhe',
        ),
      ),
    );

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_NOT_BUILD_READY'), findsOneWidget);
    expect(find.text('Error: seat_count_missing'), findsOneWidget);
  });

  testWidgets('fails closed for app-owned setup intent with blank identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        runtime: PeerDealMobileRuntime(
          setupFlowIntentFactory: (_) => const SetupIntent(
            intentId: '   ',
            sourceType: SetupSurface.simple,
            hostPseudonymousId: '   ',
            modePreference: 'open_table',
            variantPreference: 'holdem_nlhe',
            seatCountPreference: 6,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_INTENT_INVALID'), findsOneWidget);
    expect(find.text('Error: setup_intent_id_missing'), findsOneWidget);
    expect(find.text('Error: setup_host_missing'), findsOneWidget);
  });

  testWidgets('fails closed for unknown app routes', (tester) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    Navigator.of(
      tester.element(find.text('PeerDeal demo')),
    ).pushNamed('/unknown-route');
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.text('State: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_ROUTE_UNAVAILABLE'), findsOneWidget);
    expect(find.text('Route: /unknown-route'), findsOneWidget);
  });

  testWidgets('scrubs unknown route diagnostics before rendering', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    Navigator.of(
      tester.element(find.text('PeerDeal demo')),
    ).pushNamed('/unknown-${'route'.padRight(120, 'x')}?token=secret#fragment');
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.textContaining('token=secret'), findsNothing);
    expect(find.textContaining('fragment'), findsNothing);
    final routeText = tester.widget<Text>(find.textContaining('Route: /'));
    expect(routeText.data!.length, lessThanOrEqualTo('Route: '.length + 80));
  });

  testWidgets('fails closed when app-owned join factory throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealMobileApp(
        joinFlowOrchestratorFactory: (_) {
          throw StateError('join flow unavailable');
        },
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_JOIN_FLOW_UNAVAILABLE'), findsOneWidget);
  });

  testWidgets('selected scenario drives mounted demo routes', (tester) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    await tester.tap(find.text('Scenario: Chat-Heavy Table'));
    await tester.pumpAndSettle();

    expect(find.text('Active scenario: Chat-Heavy Table'), findsOneWidget);

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Scenario: chat_heavy_table'), findsOneWidget);
    expect(find.text('Network: stable'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Scenario: chat_heavy_table'), findsOneWidget);
    expect(find.text('Unread: 19'), findsOneWidget);
  });

  testWidgets('mounted table classifies recovery network confidence', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    await tester.tap(
      find.text('Scenario: Recovery Pause - Primary-Peer Transfer'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Network: recoveryRequired'), findsOneWidget);
    expect(find.text('Network action: recovery_required'), findsOneWidget);
  });
}

PeerDealReceipt _receiptForSnapshot(
  DemoScenarioSnapshot snapshot, {
  required String pseudonymousUserId,
}) {
  return PeerDealReceipt(
    receiptId: 'receipt_${snapshot.scenarioId}',
    receiptVersion: '1.0',
    protocolVersion: '1.x',
    modeType: snapshot.mode,
    sessionId: 'session_${snapshot.scenarioId}',
    tableId: 'table_${snapshot.scenarioId}',
    pseudonymousUserId: pseudonymousUserId,
    bindingMode: ReceiptBindingMode.sessionBound,
    wipeState: ReceiptWipeState.live,
    payloadHash: 'hash_${snapshot.scenarioId}',
    opaquePayload: 'opaque_${snapshot.scenarioId}',
  );
}

class _ThrowingVerifierFactory extends DemoReceiptArtifactVerifierFactory {
  _ThrowingVerifierFactory()
    : super(bridge: RecordingReceiptKeyStorageBridge());

  @override
  DemoReceiptArtifactVerifier create() {
    throw StateError('verifier factory unavailable');
  }
}

class _StaticLocalNetworkBridge implements LocalNetworkBridge {
  const _StaticLocalNetworkBridge();

  @override
  Future<LocalNetworkCapability> getCapability() async {
    return const LocalNetworkCapability(
      discoverySupported: true,
      permissionPromptSupported: true,
      broadcastSupported: true,
      notes: 'local-network-ready',
    );
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    return const LocalNetworkDiscoverySnapshot(
      permissionGranted: true,
      foundEndpoints: <String>['peer-a', 'peer-b'],
      interfaceHints: <String>['wifi'],
    );
  }
}

class _RecordingReceiptKeyStorageMutationBridge
    implements SecureKeyStorageMutationBridge {
  final List<_SavedSecureKey> savedKeys = <_SavedSecureKey>[];
  final List<String> namespaces = <String>[];

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    namespaces.add(namespace);
    return SecureKeyStorageSnapshot(
      available: true,
      keys: savedKeys.map((saved) => saved.key).toList(growable: false),
    );
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
  }) async {
    savedKeys.add(_SavedSecureKey(namespace: namespace, key: key));
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
  }) async {
    savedKeys.removeWhere(
      (saved) => saved.namespace == namespace && saved.key.keyId == keyId,
    );
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }
}

class _SavedSecureKey {
  const _SavedSecureKey({required this.namespace, required this.key});

  final String namespace;
  final SecureKeyRecord key;
}

EventEnvelope _recoveryEvent({
  required int seq,
  required String prevHash,
  required String hash,
  String tableId = 'open_table_live_turn',
  String sessionId = 'demo:open_table_live_turn',
}) {
  return EventEnvelope(
    eventId: 'evt_$seq',
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

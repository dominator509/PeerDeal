import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_artifact_verifier_factory.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_bootstrap_candidate_loader.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_export_artifact_factory.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_provisioner.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_writer.dart';
import 'package:peerdeal_desktop/demo_slice/demo_slice_routes.dart';
import 'package:peerdeal_desktop/demo_slice/models/demo_scenario_snapshot.dart';
import 'package:peerdeal_desktop/join_flow/demo_join_flow_orchestrator_factory.dart';
import 'package:peerdeal_desktop/join_flow/fakes.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_models.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_route.dart';
import 'package:peerdeal_desktop/main.dart';
import 'package:peerdeal_desktop/native_readiness/app_native_readiness_loader.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_persistence_store_factory.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_bootstrap.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_bootstrap_route_registration.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_configuration.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_configuration_factory.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_persistence_writer.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_snapshot_writer.dart';
import 'package:peerdeal_desktop/session/app_persisted_holdem_production_session_source.dart';
import 'package:peerdeal_desktop/setup_flow/setup_flow_route.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';
import 'package:peerdeal_wizard/peerdeal_wizard.dart';

import '../../../tools/test_helpers/demo_receipt_route_test_support.dart';

void main() {
  testWidgets('mounts demo home instead of placeholder root', (tester) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
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

  testWidgets('renders app native readiness on default home', (tester) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          nativeReadinessLoader: AppNativeReadinessLoader(
            captureProtectionBridge: const _StaticCaptureProtectionBridge(
              capability: CaptureProtectionCapability(
                blockingSupported: true,
                obscuringSupported: true,
                notes: 'ready',
              ),
            ),
            localNetworkBridge: const _StaticLocalNetworkBridge(),
            nativeTransportBridge: const _StaticNativeTransportBridge(
              capability: NativeTransportCapability(
                available: true,
                sendSupported: true,
                receiveSupported: true,
                maxPayloadBytes: 1024,
                notes: 'ready',
              ),
            ),
            secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
              snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Native ready'), findsOneWidget);
    expect(find.text('Native unavailable'), findsNothing);
  });

  testWidgets('renders scrubbed native readiness warnings on default home', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          nativeReadinessLoader: AppNativeReadinessLoader(
            captureProtectionBridge: const _StaticCaptureProtectionBridge(
              capability: CaptureProtectionCapability.unavailable(
                warning: 'token capture-secret',
              ),
            ),
            localNetworkBridge: const _StaticLocalNetworkBridge(
              capability: LocalNetworkCapability.unavailable(
                warning: r'C:\secret\lan.log',
              ),
            ),
            nativeTransportBridge: const _StaticNativeTransportBridge(
              capability: NativeTransportCapability.unavailable(
                warning: 'password transport-secret',
              ),
            ),
            secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
              snapshot: SecureKeyStorageSnapshot.unavailable(
                warning: 'secret keychain detail',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Native unavailable'), findsOneWidget);
    expect(find.text('native capture protection unavailable'), findsOneWidget);
    expect(
      find.text('native local-network discovery unavailable'),
      findsOneWidget,
    );
    expect(find.text('native transport unavailable'), findsOneWidget);
    expect(find.text('native secure-key storage unavailable'), findsOneWidget);
    expect(find.textContaining('capture-secret'), findsNothing);
    expect(find.textContaining(r'C:\secret'), findsNothing);
    expect(find.textContaining('transport-secret'), findsNothing);
    expect(find.textContaining('keychain detail'), findsNothing);
  });

  testWidgets('routes from demo home to receipt surface', (tester) async {
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(
        bridge: RecordingCaptureProtectionBridge(),
      ),
    );

    await tester.pumpWidget(PeerDealDesktopApp(presenter: presenter));

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
      PeerDealDesktopApp(
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

  testWidgets('fails closed for conflicting receipt export sources', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final keyBridge = RecordingReceiptKeyStorageBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );
    var exportFactoryCalled = false;

    await tester.pumpWidget(
      PeerDealDesktopApp(
        presenter: presenter,
        receiptExportArtifact: signedDemoReceiptArtifact(),
        receiptExportArtifactFactory: (_) async {
          exportFactoryCalled = true;
          return const ReceiptExportArtifact.unavailable(
            reason: 'conflicting export source used',
          );
        },
        receiptArtifactVerifierFactory: DemoReceiptArtifactVerifierFactory(
          bridge: keyBridge,
        ),
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(exportFactoryCalled, isFalse);
    expect(keyBridge.namespaces, isEmpty);
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
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
        presenter: DemoReceiptSurfacePresenter(
          captureCoordinator: CaptureSurfaceCoordinator(
            bridge: RecordingCaptureProtectionBridge(),
          ),
        ),
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
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
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

    await tester.pumpWidget(PeerDealDesktopApp(presenter: presenter));

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
    await tester.pumpWidget(const PeerDealDesktopApp());

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
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
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
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
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
      PeerDealDesktopApp(
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
    await tester.pumpWidget(const PeerDealDesktopApp());

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

  testWidgets('mounted table scrubs injected bootstrap and recovery warnings', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        bootstrapCandidateLoaderFactory: _UnsafeBootstrapLoader.new,
        recoveryPersistenceStoreFactory: _UnsafeRecoveryFactory(),
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

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

  testWidgets('mounted table bounds injected bootstrap candidates', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        bootstrapCandidateLoaderFactory: _OversizedBootstrapLoader.new,
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Bootstrap: 32 candidates'), findsOneWidget);
    expect(
      find.text('Bootstrap warning: Bootstrap candidates truncated.'),
      findsOneWidget,
    );
  });

  testWidgets('mounted table bounds injected recovery persistence events', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        recoveryPersistenceStoreFactory: _OversizedRecoveryFactory(),
      ),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Recovery persistence: 128 events'), findsOneWidget);
    expect(
      find.text(
        'Recovery persistence warning: Recovery persistence events truncated.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('mounted table loads app-provided recovery persistence window', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_desktop_mounted_recovery_',
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
        _recoveryEvent(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );
    expect(append.isSuccess, isTrue);

    await tester.pumpWidget(
      PeerDealDesktopApp(recoveryPersistenceStoreFactory: factory),
    );

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Recovery persistence: 1 events'), findsOneWidget);
  });

  testWidgets('mounted table loads app-provided runtime recovery scope', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_desktop_mounted_runtime_scope_',
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
          prevHash: genesisEventHash,
          hash: 'hash_1',
          tableId: scope.tableId,
          sessionId: scope.sessionId,
        ),
      ],
    );
    expect(append.isSuccess, isTrue);

    await tester.pumpWidget(
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
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

  testWidgets('routes join mode gates through app runtime object', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
            bootstrapCoordinator: FakeBootstrapCoordinator(),
          ).create,
          joinFlowEnabledModes: const <JoinFlowDemoMode>{
            JoinFlowDemoMode.firstJoin,
          },
        ),
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('Run first join'), findsOneWidget);
    expect(find.text('Run rejoin'), findsNothing);
    expect(find.text('State: joined'), findsOneWidget);
  });

  testWidgets('routes from demo home to setup flow', (tester) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    await tester.tap(find.text('Setup'));
    await tester.pump();

    expect(find.text('Loading setup'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Setup flow'), findsOneWidget);
    expect(find.text('Status: compiled'), findsOneWidget);
    expect(find.text('Result: OK_GAME_FILE_COMPILED'), findsOneWidget);
  });

  testWidgets('routes setup mode gates through app runtime object', (
    tester,
  ) async {
    await tester.pumpWidget(
      const PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          setupFlowEnabledModes: <SetupFlowDemoMode>{
            SetupFlowDemoMode.buildReady,
          },
        ),
      ),
    );

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Compile build-ready setup'), findsOneWidget);
    expect(find.text('Compile invalid setup'), findsNothing);
    expect(find.text('Status: compiled'), findsOneWidget);
  });

  testWidgets('fails closed when app-owned setup factory throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
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
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
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
    await tester.pumpWidget(const PeerDealDesktopApp());

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
    await tester.pumpWidget(const PeerDealDesktopApp());

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

  testWidgets('suppresses sensitive unknown route diagnostics', (tester) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    Navigator.of(
      tester.element(find.text('PeerDeal demo')),
    ).pushNamed(r'/unknown-token-C:\secret\route');
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.textContaining('Route: /'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('fails closed when app-owned join factory throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
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
    await tester.pumpWidget(const PeerDealDesktopApp());

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

  testWidgets('routes enabled demo paths through app runtime object', (
    tester,
  ) async {
    await tester.pumpWidget(
      const PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.table,
          },
        ),
      ),
    );

    expect(find.widgetWithText(PeerDealActionButton, 'Table'), findsOneWidget);
    expect(find.widgetWithText(PeerDealActionButton, 'Receipt'), findsNothing);
    expect(find.widgetWithText(PeerDealActionButton, 'Join'), findsNothing);

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Demo table'), findsOneWidget);
    expect(find.widgetWithText(PeerDealActionButton, 'Chat'), findsNothing);
    expect(find.widgetWithText(PeerDealActionButton, 'Receipt'), findsNothing);
  });

  testWidgets('disabled demo paths fail closed through unknown-route surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.table,
          },
        ),
      ),
    );

    Navigator.of(
      tester.element(find.text('PeerDeal demo')),
    ).pushNamed(DemoSliceRoutes.receipt);
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.text('Result: ERR_ROUTE_UNAVAILABLE'), findsOneWidget);
    expect(find.text('Route: ${DemoSliceRoutes.receipt}'), findsOneWidget);
  });

  testWidgets('mounts app-owned production routes outside demo registry', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
        ),
      ),
    );

    Navigator.of(
      tester.element(find.text('PeerDeal demo')),
    ).pushNamed('/table-live');
    await tester.pumpAndSettle();

    expect(find.text('Production table route'), findsOneWidget);
  });

  testWidgets('routes native-ready production routes when readiness passes', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          initialRoute: '/table-live',
          nativeReadinessRequiredRoutePaths: const <String>{'/table-live'},
          nativeReadinessLoader: AppNativeReadinessLoader(
            captureProtectionBridge: const _StaticCaptureProtectionBridge(
              capability: CaptureProtectionCapability(
                blockingSupported: true,
                obscuringSupported: true,
                notes: 'ready',
              ),
            ),
            localNetworkBridge: const _StaticLocalNetworkBridge(),
            nativeTransportBridge: const _StaticNativeTransportBridge(
              capability: NativeTransportCapability(
                available: true,
                sendSupported: true,
                receiveSupported: true,
                maxPayloadBytes: 1024,
                notes: 'ready',
              ),
            ),
            secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
              snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
            ),
          ),
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Native-backed table route'),
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Native-backed table route'), findsOneWidget);
    expect(find.text('Route unavailable'), findsNothing);
  });

  testWidgets(
    'shows native-ready production navigation when readiness passes',
    (tester) async {
      await tester.pumpWidget(
        PeerDealDesktopApp(
          runtime: PeerDealDesktopRuntime(
            enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
            nativeReadinessRequiredRoutePaths: const <String>{'/table-live'},
            nativeReadinessLoader: AppNativeReadinessLoader(
              captureProtectionBridge: const _StaticCaptureProtectionBridge(
                capability: CaptureProtectionCapability(
                  blockingSupported: true,
                  obscuringSupported: true,
                  notes: 'ready',
                ),
              ),
              localNetworkBridge: const _StaticLocalNetworkBridge(),
              nativeTransportBridge: const _StaticNativeTransportBridge(
                capability: NativeTransportCapability(
                  available: true,
                  sendSupported: true,
                  receiveSupported: true,
                  maxPayloadBytes: 1024,
                  notes: 'ready',
                ),
              ),
              secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
                snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
              ),
            ),
            productionRoutes: <String, WidgetBuilder>{
              '/table-live': (_) => const Text('Native-backed table route'),
            },
            productionNavigation: const <PeerDealAppNavigationEntry>[
              PeerDealAppNavigationEntry(
                label: 'Native table',
                path: '/table-live',
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(PeerDealActionButton, 'Native table'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'fails closed for production routes when native readiness fails',
    (tester) async {
      await tester.pumpWidget(
        PeerDealDesktopApp(
          runtime: PeerDealDesktopRuntime(
            enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
            initialRoute: '/table-live',
            nativeReadinessRequiredRoutePaths: const <String>{'/table-live'},
            nativeReadinessLoader: AppNativeReadinessLoader(
              captureProtectionBridge: const _StaticCaptureProtectionBridge(
                capability: CaptureProtectionCapability.unavailable(
                  warning: 'token native-secret',
                ),
              ),
              localNetworkBridge: const _StaticLocalNetworkBridge(
                capability: LocalNetworkCapability.unavailable(
                  warning: r'C:\secret\lan.log',
                ),
              ),
              nativeTransportBridge: const _StaticNativeTransportBridge(
                capability: NativeTransportCapability.unavailable(
                  warning: 'password transport-secret',
                ),
              ),
              secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
                snapshot: SecureKeyStorageSnapshot.unavailable(
                  warning: 'secret keychain detail',
                ),
              ),
            ),
            productionRoutes: <String, WidgetBuilder>{
              '/table-live': (_) => const Text('Native-backed table route'),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Route unavailable'), findsOneWidget);
      expect(find.text('Route: /table-live'), findsOneWidget);
      expect(find.text('Native-backed table route'), findsNothing);
      expect(find.textContaining('native-secret'), findsNothing);
      expect(find.textContaining(r'C:\secret'), findsNothing);
      expect(find.textContaining('transport-secret'), findsNothing);
      expect(find.textContaining('keychain detail'), findsNothing);
    },
  );

  testWidgets('hides native-required production navigation until ready', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          nativeReadinessRequiredRoutePaths: const <String>{'/table-live'},
          nativeReadinessLoader: AppNativeReadinessLoader(
            captureProtectionBridge: const _StaticCaptureProtectionBridge(
              capability: CaptureProtectionCapability.unavailable(
                warning: 'token native-secret',
              ),
            ),
            localNetworkBridge: const _StaticLocalNetworkBridge(
              capability: LocalNetworkCapability.unavailable(),
            ),
            nativeTransportBridge: const _StaticNativeTransportBridge(
              capability: NativeTransportCapability.unavailable(),
            ),
            secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
              snapshot: SecureKeyStorageSnapshot.unavailable(),
            ),
          ),
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Native-backed table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Native table',
              path: '/table-live',
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(PeerDealActionButton, 'Native table'),
      findsNothing,
    );
    expect(find.text('PeerDeal'), findsOneWidget);
    expect(find.text('Production app routes'), findsOneWidget);
    expect(find.text('PeerDeal demo'), findsNothing);
    expect(find.textContaining('Active scenario:'), findsNothing);
    expect(find.text('Demo'), findsNothing);
    expect(find.text('Production'), findsOneWidget);
    expect(find.text('Routes unavailable'), findsOneWidget);
    expect(find.text('Native unavailable'), findsOneWidget);
  });

  testWidgets('rejects native readiness gates for unmounted routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          nativeReadinessRequiredRoutePaths: const <String>{'/missing'},
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('fails closed when app-owned production route builder throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) {
              throw StateError('production route unavailable');
            },
          },
        ),
      ),
    );

    Navigator.of(
      tester.element(find.text('PeerDeal demo')),
    ).pushNamed('/table-live');
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.text('Result: ERR_ROUTE_UNAVAILABLE'), findsOneWidget);
    expect(find.text('Route: /table-live'), findsOneWidget);
  });

  testWidgets('routes production navigation actions through app home', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live table',
              path: '/table-live',
            ),
          ],
        ),
      ),
    );

    expect(
      find.widgetWithText(PeerDealActionButton, 'Live table'),
      findsOneWidget,
    );

    await tester.tap(find.text('Live table'));
    await tester.pumpAndSettle();

    expect(find.text('Production table route'), findsOneWidget);
  });

  testWidgets('forwards production navigation arguments to route settings', (
    tester,
  ) async {
    const invite = ResolvedInvite(
      inviteId: 'inv_001',
      tableId: 'table_001',
      sessionId: 'session_001',
      modeType: 'open_table',
      protocolVersion: '1.0.0',
      requiresReceiptAck: true,
      requiresRetentionAck: true,
      requiresCaptureAck: true,
    );

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (context) {
              final arguments = ModalRoute.of(context)?.settings.arguments;
              return Text(
                arguments is ResolvedInvite ? arguments.inviteId : 'missing',
              );
            },
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live table',
              path: '/table-live',
              arguments: invite,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Live table'));
    await tester.pumpAndSettle();

    expect(find.text('inv_001'), findsOneWidget);
  });

  testWidgets('hands successful join into an injected production route', (
    tester,
  ) async {
    var callbackCalled = false;
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.join,
          },
          joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
            bootstrapCoordinator: FakeBootstrapCoordinator(),
          ).create,
          productionRoutes: <String, WidgetBuilder>{
            '/holdem-live': (context) {
              final arguments = ModalRoute.of(context)?.settings.arguments;
              return Text(
                arguments is ResolvedInvite ? arguments.inviteId : 'missing',
              );
            },
          },
          joinFlowReadyHandler: (context, invite) {
            callbackCalled = true;
            Navigator.of(context).pushNamed('/holdem-live', arguments: invite);
          },
        ),
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(callbackCalled, isTrue);
    expect(find.text('inv_001'), findsOneWidget);
  });

  testWidgets(
    'hands successful join into a configured bootstrap route by default',
    (tester) async {
      await tester.pumpWidget(
        PeerDealDesktopApp(
          runtime: PeerDealDesktopRuntime(
            enabledDemoRoutePaths: const <String>{
              DemoSliceRoutes.home,
              DemoSliceRoutes.join,
            },
            joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
              bootstrapCoordinator: FakeBootstrapCoordinator(),
            ).create,
            nativeReadinessLoader: AppNativeReadinessLoader(
              captureProtectionBridge: const _StaticCaptureProtectionBridge(
                capability: CaptureProtectionCapability(
                  blockingSupported: true,
                  obscuringSupported: true,
                  notes: 'ready',
                ),
              ),
              localNetworkBridge: const _StaticLocalNetworkBridge(),
              nativeTransportBridge: const _StaticNativeTransportBridge(
                capability: NativeTransportCapability(
                  available: true,
                  sendSupported: true,
                  receiveSupported: true,
                  maxPayloadBytes: 1024,
                  notes: 'ready',
                ),
              ),
              secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
                snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
              ),
            ),
            holdemProductionSession:
                AppHoldemProductionSessionConfiguration.fromSource(
                  path: '/holdem-live',
                  source: _FailingProductionSessionSource(),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();

      expect(find.text('Route unavailable'), findsOneWidget);
      expect(find.text('Route: /holdem-live'), findsOneWidget);
    },
  );

  testWidgets('hands successful join through typed configuration loader', (
    tester,
  ) async {
    final store = InMemoryRecoveryPersistenceStore();
    final configuration = AppHoldemProductionSessionConfiguration.fromSource(
      path: '/holdem-loaded',
      source: _FailingProductionSessionSource(),
    );
    final loadResult =
        AppHoldemProductionSessionConfigurationLoadResult.available(
          configuration: configuration,
          persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
            store: store,
          ),
          snapshotWriter: AppHoldemProductionSessionSnapshotWriter(
            store: store,
          ),
        );
    JoinFlowSessionContext? handedOffContext;

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.join,
          },
          joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
            bootstrapCoordinator: FakeBootstrapCoordinator(),
          ).create,
          nativeReadinessLoader: _readyNativeReadinessLoader(),
          holdemProductionSessionConfigurationLoader: (sessionContext) async {
            handedOffContext = sessionContext;
            return loadResult;
          },
        ),
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(handedOffContext, isNotNull);
    expect(handedOffContext!.invite.inviteId, 'inv_001');
    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.text('Route: /holdem-loaded'), findsOneWidget);
  });

  testWidgets('ignores a stale loaded production session after a newer join', (
    tester,
  ) async {
    final staleLoad =
        Completer<AppHoldemProductionSessionConfigurationLoadResult>();
    final currentResult = _availableConfigurationLoadResult('/holdem-current');
    var loadCount = 0;

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.join,
          },
          joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
            bootstrapCoordinator: FakeBootstrapCoordinator(),
          ).create,
          holdemProductionSessionConfigurationLoader: (_) {
            loadCount += 1;
            return loadCount == 1
                ? staleLoad.future
                : Future<
                    AppHoldemProductionSessionConfigurationLoadResult
                  >.value(currentResult);
          },
        ),
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Join flow'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(find.text('Route: /holdem-current'), findsOneWidget);

    staleLoad.complete(_availableConfigurationLoadResult('/holdem-stale'));
    await tester.pumpAndSettle();

    expect(find.text('Route: /holdem-current'), findsOneWidget);
    expect(find.text('Route: /holdem-stale'), findsNothing);
  });

  testWidgets(
    'ignores a stale loaded production session after factory removal',
    (tester) async {
      final staleLoad =
          Completer<AppHoldemProductionSessionConfigurationLoadResult>();

      await tester.pumpWidget(
        PeerDealDesktopApp(
          runtime: PeerDealDesktopRuntime(
            enabledDemoRoutePaths: const <String>{
              DemoSliceRoutes.home,
              DemoSliceRoutes.join,
            },
            joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
              bootstrapCoordinator: FakeBootstrapCoordinator(),
            ).create,
            holdemProductionSessionConfigurationLoader: (_) => staleLoad.future,
          ),
        ),
      );

      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        PeerDealDesktopApp(
          runtime: PeerDealDesktopRuntime(
            enabledDemoRoutePaths: const <String>{
              DemoSliceRoutes.home,
              DemoSliceRoutes.join,
            },
            joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
              bootstrapCoordinator: FakeBootstrapCoordinator(),
            ).create,
          ),
        ),
      );
      await tester.pump();

      staleLoad.complete(_availableConfigurationLoadResult('/holdem-stale'));
      await tester.pumpAndSettle();

      expect(find.text('Route: /holdem-stale'), findsNothing);
    },
  );

  testWidgets('fails closed when typed configuration loader is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.join,
          },
          joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
            bootstrapCoordinator: FakeBootstrapCoordinator(),
          ).create,
          holdemProductionSessionConfigurationLoader: (_) async =>
              AppHoldemProductionSessionConfigurationLoadResult.unavailable(
                warnings: <String>['secret loader detail'],
              ),
        ),
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('adapts a configured session factory to the typed loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.join,
          },
          joinFlowOrchestratorFactory: DemoJoinFlowOrchestratorFactory(
            bootstrapCoordinator: FakeBootstrapCoordinator(),
          ).create,
          nativeReadinessLoader: _readyNativeReadinessLoader(),
          holdemProductionSessionConfigurationFactory:
              _productionConfigurationFactory('/holdem-factory'),
        ),
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.text('Route: /holdem-factory'), findsOneWidget);
  });

  testWidgets('rejects a bootstrap route that collides with a route', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            '/holdem-live': (_) => const Text('Existing route'),
          },
          holdemProductionSessionBootstrapRoute:
              AppHoldemProductionSessionBootstrapRouteRegistration.fromSource(
                path: '/holdem-live',
                source: _FailingProductionSessionSource(),
              ),
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects conflicting production session configurations', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          holdemProductionSessionBootstrapRoute:
              AppHoldemProductionSessionBootstrapRouteRegistration.fromSource(
                path: '/holdem-explicit',
                source: _FailingProductionSessionSource(),
              ),
          holdemProductionSession:
              AppHoldemProductionSessionConfiguration.fromSource(
                path: '/holdem-configured',
                source: _FailingProductionSessionSource(),
              ),
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('separates production and demo navigation on default home', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.table,
          },
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live table',
              path: '/table-live',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Production'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(
      find.widgetWithText(PeerDealActionButton, 'Live table'),
      findsOneWidget,
    );
    expect(find.widgetWithText(PeerDealActionButton, 'Table'), findsOneWidget);
  });

  testWidgets('renders production-only default home without demo scenarios', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live table',
              path: '/table-live',
            ),
          ],
        ),
      ),
    );

    expect(find.text('PeerDeal'), findsOneWidget);
    expect(find.text('Production app routes'), findsOneWidget);
    expect(find.text('PeerDeal demo'), findsNothing);
    expect(find.textContaining('Active scenario:'), findsNothing);
    expect(find.text('Demo'), findsNothing);
    expect(find.text('Production'), findsOneWidget);
    expect(
      find.widgetWithText(PeerDealActionButton, 'Live table'),
      findsOneWidget,
    );
  });

  testWidgets('uses app-owned home surface builder', (tester) async {
    var homePaths = const <String>[];

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.table,
          },
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live table',
              path: '/table-live',
            ),
          ],
          homeSurfaceBuilder: (context, navigation) {
            homePaths = navigation.map((entry) => entry.path).toList();
            return const Text('Production home surface');
          },
        ),
      ),
    );

    expect(find.text('Production home surface'), findsOneWidget);
    expect(find.text('PeerDeal demo'), findsNothing);
    expect(homePaths, <String>[DemoSliceRoutes.table, '/table-live']);
  });

  testWidgets('filters unready native production navigation for custom home', (
    tester,
  ) async {
    var homePaths = const <String>[];

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          nativeReadinessRequiredRoutePaths: const <String>{'/table-live'},
          nativeReadinessLoader: AppNativeReadinessLoader(
            captureProtectionBridge: const _StaticCaptureProtectionBridge(
              capability: CaptureProtectionCapability.unavailable(),
            ),
            localNetworkBridge: const _StaticLocalNetworkBridge(
              capability: LocalNetworkCapability.unavailable(),
            ),
            nativeTransportBridge: const _StaticNativeTransportBridge(
              capability: NativeTransportCapability.unavailable(),
            ),
            secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
              snapshot: SecureKeyStorageSnapshot.unavailable(),
            ),
          ),
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live table',
              path: '/table-live',
            ),
          ],
          homeSurfaceBuilder: (context, navigation) {
            homePaths = navigation.map((entry) => entry.path).toList();
            return const Text('Production home surface');
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Production home surface'), findsOneWidget);
    expect(homePaths, isEmpty);
  });

  testWidgets('passes ready native production navigation to custom home', (
    tester,
  ) async {
    var homePaths = const <String>[];

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          nativeReadinessRequiredRoutePaths: const <String>{'/table-live'},
          nativeReadinessLoader: AppNativeReadinessLoader(
            captureProtectionBridge: const _StaticCaptureProtectionBridge(
              capability: CaptureProtectionCapability(
                blockingSupported: true,
                obscuringSupported: true,
                notes: 'ready',
              ),
            ),
            localNetworkBridge: const _StaticLocalNetworkBridge(),
            nativeTransportBridge: const _StaticNativeTransportBridge(
              capability: NativeTransportCapability(
                available: true,
                sendSupported: true,
                receiveSupported: true,
                maxPayloadBytes: 1024,
                notes: 'ready',
              ),
            ),
            secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
              snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
            ),
          ),
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live table',
              path: '/table-live',
            ),
          ],
          homeSurfaceBuilder: (context, navigation) {
            homePaths = navigation.map((entry) => entry.path).toList();
            return const Text('Production home surface');
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Production home surface'), findsOneWidget);
    expect(homePaths, <String>['/table-live']);
  });

  testWidgets('fails closed when app-owned home surface builder throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          homeSurfaceBuilder: (context, navigation) {
            throw StateError('home surface unavailable');
          },
        ),
      ),
    );

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.text('Result: ERR_ROUTE_UNAVAILABLE'), findsOneWidget);
    expect(find.text('Route: ${DemoSliceRoutes.home}'), findsOneWidget);
  });

  testWidgets('rejects production navigation for unmounted routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionNavigation: <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(label: 'Missing', path: '/missing'),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects production navigation with control metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live\nTable',
              path: '/table-live',
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects production navigation labels that collide with demo', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{
            DemoSliceRoutes.home,
            DemoSliceRoutes.table,
          },
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(label: 'Table', path: '/table-live'),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets(
    'rejects production navigation labels that case-collide with demo',
    (tester) async {
      await tester.pumpWidget(
        PeerDealDesktopApp(
          runtime: PeerDealDesktopRuntime(
            enabledDemoRoutePaths: const <String>{DemoSliceRoutes.table},
            productionRoutes: <String, WidgetBuilder>{
              '/table-live': (_) => const Text('Production table route'),
            },
            productionNavigation: const <PeerDealAppNavigationEntry>[
              PeerDealAppNavigationEntry(label: 'table', path: '/table-live'),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isA<StateError>());
    },
  );

  testWidgets('starts on app-owned production initial route', (tester) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          initialRoute: '/table-live',
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
        ),
      ),
    );

    expect(find.text('Production table route'), findsOneWidget);
    expect(find.text('PeerDeal demo'), findsNothing);
  });

  testWidgets('rejects initial routes that are not mounted', (tester) async {
    await tester.pumpWidget(
      const PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: <String>{DemoSliceRoutes.home},
          initialRoute: DemoSliceRoutes.receipt,
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects initial routes with unsafe characters', (tester) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          initialRoute: '/table live',
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects initial routes with path separators', (tester) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          enabledDemoRoutePaths: const <String>{DemoSliceRoutes.home},
          initialRoute: r'/table\live',
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects production routes that collide with demo namespace', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            '/demo/production': (_) => const Text('bad route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets(
    'rejects production routes that case-collide with demo namespace',
    (tester) async {
      await tester.pumpWidget(
        PeerDealDesktopApp(
          runtime: PeerDealDesktopRuntime(
            productionRoutes: <String, WidgetBuilder>{
              '/Demo/production': (_) => const Text('bad route'),
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<StateError>());
    },
  );

  testWidgets('rejects production routes with unsafe characters', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            '/table live': (_) => const Text('bad route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects production routes with excessive length', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            '/${List.filled(120, 'a').join()}': (_) => const Text('bad route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects production routes with path separators', (tester) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            r'/table\live': (_) => const Text('bad route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects case-colliding production route paths', (tester) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
            '/Table-Live': (_) => const Text('Ambiguous table route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects case-colliding production navigation metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
            '/ledger-live': (_) => const Text('Production ledger route'),
          },
          productionNavigation: const <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: 'Live table',
              path: '/table-live',
            ),
            PeerDealAppNavigationEntry(
              label: 'live table',
              path: '/ledger-live',
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects production navigation labels with excessive length', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            '/table-live': (_) => const Text('Production table route'),
          },
          productionNavigation: <PeerDealAppNavigationEntry>[
            PeerDealAppNavigationEntry(
              label: List.filled(80, 'L').join(),
              path: '/table-live',
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects excessive production route maps', (tester) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            for (var index = 0; index < 25; index++)
              '/production-$index': (_) => const Text('bad route'),
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('rejects excessive production navigation entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          productionRoutes: <String, WidgetBuilder>{
            for (var index = 0; index < 17; index++)
              '/production-$index': (_) => const Text('Production route'),
          },
          productionNavigation: <PeerDealAppNavigationEntry>[
            for (var index = 0; index < 17; index++)
              PeerDealAppNavigationEntry(
                label: 'Production $index',
                path: '/production-$index',
              ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('mounted table classifies recovery network confidence', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

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

AppNativeReadinessLoader _readyNativeReadinessLoader() {
  return AppNativeReadinessLoader(
    captureProtectionBridge: const _StaticCaptureProtectionBridge(
      capability: CaptureProtectionCapability(
        blockingSupported: true,
        obscuringSupported: true,
        notes: 'ready',
      ),
    ),
    localNetworkBridge: const _StaticLocalNetworkBridge(),
    nativeTransportBridge: const _StaticNativeTransportBridge(
      capability: NativeTransportCapability(
        available: true,
        sendSupported: true,
        receiveSupported: true,
        maxPayloadBytes: 1024,
        notes: 'ready',
      ),
    ),
    secureKeyStorageBridge: _StaticSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
    ),
  );
}

AppHoldemProductionSessionConfigurationFactory _productionConfigurationFactory(
  String path,
) {
  return AppHoldemProductionSessionConfigurationFactory(
    recoveryStoreFactory: AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => Directory.systemTemp,
    ),
    routePolicyFactory: (_) => AppPersistedHoldemProductionSessionRoutePolicy(
      path: path,
      navigationLabel: 'Live Holdem',
      remotePeerId: 'peer_remote',
      localSeat: 1,
      closeEventAdapterFactory: (_) => throw StateError('unused'),
    ),
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-11T00:00:00Z',
    eventHashFactory: (_) => 'hash',
  );
}

AppHoldemProductionSessionConfigurationLoadResult
_availableConfigurationLoadResult(String path) {
  final store = InMemoryRecoveryPersistenceStore();
  return AppHoldemProductionSessionConfigurationLoadResult.available(
    configuration: AppHoldemProductionSessionConfiguration.fromSource(
      path: path,
      source: _FailingProductionSessionSource(),
    ),
    persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
      store: store,
    ),
    snapshotWriter: AppHoldemProductionSessionSnapshotWriter(store: store),
  );
}

class _StaticCaptureProtectionBridge implements CaptureProtectionBridge {
  const _StaticCaptureProtectionBridge({required this.capability});

  final CaptureProtectionCapability capability;

  @override
  Future<CaptureProtectionCapability> getCapability() async => capability;
}

class _StaticLocalNetworkBridge implements LocalNetworkBridge {
  const _StaticLocalNetworkBridge({
    this.capability = const LocalNetworkCapability(
      discoverySupported: true,
      permissionPromptSupported: true,
      broadcastSupported: true,
      notes: 'local-network-ready',
    ),
  });

  final LocalNetworkCapability capability;

  @override
  Future<LocalNetworkCapability> getCapability() async {
    return capability;
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    return LocalNetworkDiscoverySnapshot(
      permissionGranted: true,
      foundEndpoints: <String>['peer-a', 'peer-b'],
      interfaceHints: <String>['wifi'],
    );
  }
}

class _StaticNativeTransportBridge implements NativeTransportBridge {
  const _StaticNativeTransportBridge({required this.capability});

  final NativeTransportCapability capability;

  @override
  Future<NativeTransportCapability> getCapability() async => capability;

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    return const NativeTransportSendResult(isSuccess: true);
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    return NativeTransportReceiveSnapshot(available: true, frames: []);
  }
}

class _StaticSecureKeyStorageBridge implements SecureKeyStorageBridge {
  const _StaticSecureKeyStorageBridge({required this.snapshot});

  final SecureKeyStorageSnapshot snapshot;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    return snapshot;
  }
}

class _FailingProductionSessionSource
    implements AppHoldemProductionSessionSource {
  @override
  Future<AppHoldemProductionSessionInput> load(
    ResolvedInvite invite, {
    Future<void>? cancellation,
  }) async {
    throw StateError('production session source failed');
  }
}

class _UnsafeBootstrapLoader extends NativeBootstrapCandidateLoader {
  _UnsafeBootstrapLoader() : super(bridge: const _StaticLocalNetworkBridge());

  @override
  Future<NativeBootstrapCandidateLoadResult> load({
    required String sessionId,
    required String tableId,
  }) async {
    return NativeBootstrapCandidateLoadResult.unavailable(
      nativeNotes: 'unavailable',
      warnings: <String>[
        r'C:\secret\peers.log',
        'token bootstrap-secret',
        'safe warning',
        'extra warning',
        'overflow warning',
      ],
    );
  }
}

class _OversizedBootstrapLoader extends NativeBootstrapCandidateLoader {
  _OversizedBootstrapLoader()
    : super(bridge: const _StaticLocalNetworkBridge());

  @override
  Future<NativeBootstrapCandidateLoadResult> load({
    required String sessionId,
    required String tableId,
  }) async {
    return NativeBootstrapCandidateLoadResult(
      discoveryAvailable: true,
      nativeNotes: 'ready',
      candidates: List<BootstrapCandidate>.generate(
        40,
        (index) => BootstrapCandidate(
          peerId: 'peer_$index',
          routeClass: NetworkRouteClass.lanDirect,
          reachable: true,
          priority: index,
        ),
      ),
      warnings: const <String>[],
    );
  }
}

class _UnsafeRecoveryFactory extends AppRecoveryPersistenceStoreFactory {
  _UnsafeRecoveryFactory()
    : super(rootDirectoryFactory: () => Directory.systemTemp);

  @override
  AppRecoveryPersistenceStoreLoadResult create() {
    return AppRecoveryPersistenceStoreLoadResult.unavailable(
      warnings: <String>[
        'token recovery-secret',
        'safe warning',
        'another warning',
        'more warning',
        'overflow warning',
      ],
    );
  }
}

class _OversizedRecoveryFactory extends AppRecoveryPersistenceStoreFactory {
  _OversizedRecoveryFactory()
    : super(rootDirectoryFactory: () => Directory.systemTemp);

  @override
  AppRecoveryPersistenceStoreLoadResult create() {
    return AppRecoveryPersistenceStoreLoadResult.available(
      store: _OversizedRecoveryStore(),
    );
  }
}

class _OversizedRecoveryStore implements RecoveryPersistenceStore {
  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) {
    return RecoveryPersistenceResult.success();
  }

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) {
    return RecoveryPersistenceResult.success();
  }

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) {
    return RecoveryPersistenceResult.success();
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    return PersistedRecoveryWindow(
      events: List<EventEnvelope>.generate(129, (index) {
        final seq = index + 1;
        return _recoveryEvent(
          seq: seq,
          prevHash: seq == 1 ? genesisEventHash : 'hash_${seq - 1}',
          hash: 'hash_$seq',
        );
      }),
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

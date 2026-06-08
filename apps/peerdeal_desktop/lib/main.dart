import 'package:flutter/widgets.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'demo_slice/controllers/demo_network_confidence_presenter.dart';
import 'demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'demo_slice/controllers/demo_receipt_artifact_verifier_factory.dart';
import 'demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'demo_slice/controllers/demo_recovery_result_factory.dart';
import 'demo_slice/controllers/demo_slice_controller.dart';
import 'demo_slice/controllers/native_bootstrap_candidate_loader.dart';
import 'demo_slice/controllers/native_receipt_export_artifact_factory.dart';
import 'demo_slice/demo_slice_routes.dart';
import 'demo_slice/models/demo_scenario_snapshot.dart';
import 'demo_slice/scenarios/demo_scenario_snapshots.dart';
import 'demo_slice/screens/demo_chat_screen.dart';
import 'demo_slice/screens/demo_home_screen.dart';
import 'demo_slice/screens/demo_receipt_screen.dart';
import 'demo_slice/screens/demo_table_screen.dart';
import 'join_flow/demo_join_flow_orchestrator_factory.dart';
import 'join_flow/join_flow_route.dart';
import 'navigation/app_route_fallback_screen.dart';
import 'recovery/app_recovery_persistence_store_factory.dart';
import 'setup_flow/setup_flow_orchestrator.dart';
import 'setup_flow/setup_flow_route.dart';

typedef DemoReceiptFactory =
    PeerDealReceipt Function(DemoScenarioSnapshot snapshot);

void main() {
  runApp(const PeerDealDesktopApp());
}

class PeerDealDesktopRuntime {
  const PeerDealDesktopRuntime({
    this.receiptPresenter,
    this.receiptArtifactVerifierFactory,
    this.receiptExportArtifact,
    this.receiptExportArtifactFactory,
    this.receiptFactory,
    this.joinFlowOrchestratorFactory,
    this.joinFlowInviteContextFactory,
    this.setupFlowOrchestratorFactory,
    this.setupFlowIntentFactory,
    this.bootstrapCandidateLoaderFactory,
    this.recoveryPersistenceStoreFactory,
    this.tableRuntimeScopeFactory,
  });

  final DemoReceiptSurfacePresenter? receiptPresenter;
  final DemoReceiptArtifactVerifierFactory? receiptArtifactVerifierFactory;
  final ReceiptExportArtifact? receiptExportArtifact;
  final ReceiptExportArtifactBuilder? receiptExportArtifactFactory;
  final DemoReceiptFactory? receiptFactory;
  final JoinFlowOrchestratorFactory? joinFlowOrchestratorFactory;
  final JoinFlowInviteContextFactory? joinFlowInviteContextFactory;
  final SetupFlowOrchestratorFactory? setupFlowOrchestratorFactory;
  final SetupFlowIntentFactory? setupFlowIntentFactory;
  final NativeBootstrapCandidateLoaderFactory? bootstrapCandidateLoaderFactory;
  final AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory;
  final DemoTableRuntimeScopeFactory? tableRuntimeScopeFactory;
}

class PeerDealDesktopApp extends StatefulWidget {
  const PeerDealDesktopApp({
    super.key,
    PeerDealDesktopRuntime? runtime,
    DemoReceiptSurfacePresenter? presenter,
    DemoReceiptArtifactVerifierFactory? receiptArtifactVerifierFactory,
    ReceiptExportArtifact? receiptExportArtifact,
    ReceiptExportArtifactBuilder? receiptExportArtifactFactory,
    DemoReceiptFactory? receiptFactory,
    JoinFlowOrchestratorFactory? joinFlowOrchestratorFactory,
    JoinFlowInviteContextFactory? joinFlowInviteContextFactory,
    SetupFlowOrchestratorFactory? setupFlowOrchestratorFactory,
    SetupFlowIntentFactory? setupFlowIntentFactory,
    NativeBootstrapCandidateLoaderFactory? bootstrapCandidateLoaderFactory,
    AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory,
    DemoTableRuntimeScopeFactory? tableRuntimeScopeFactory,
  }) : _runtime = runtime,
       _receiptPresenter = presenter,
       _receiptArtifactVerifierFactory = receiptArtifactVerifierFactory,
       _receiptExportArtifact = receiptExportArtifact,
       _receiptExportArtifactFactory = receiptExportArtifactFactory,
       _receiptFactory = receiptFactory,
       _joinFlowOrchestratorFactory = joinFlowOrchestratorFactory,
       _joinFlowInviteContextFactory = joinFlowInviteContextFactory,
       _setupFlowOrchestratorFactory = setupFlowOrchestratorFactory,
       _setupFlowIntentFactory = setupFlowIntentFactory,
       _bootstrapCandidateLoaderFactory = bootstrapCandidateLoaderFactory,
       _recoveryPersistenceStoreFactory = recoveryPersistenceStoreFactory,
       _tableRuntimeScopeFactory = tableRuntimeScopeFactory;

  final PeerDealDesktopRuntime? _runtime;
  final DemoReceiptSurfacePresenter? _receiptPresenter;
  final DemoReceiptArtifactVerifierFactory? _receiptArtifactVerifierFactory;
  final ReceiptExportArtifact? _receiptExportArtifact;
  final ReceiptExportArtifactBuilder? _receiptExportArtifactFactory;
  final DemoReceiptFactory? _receiptFactory;
  final JoinFlowOrchestratorFactory? _joinFlowOrchestratorFactory;
  final JoinFlowInviteContextFactory? _joinFlowInviteContextFactory;
  final SetupFlowOrchestratorFactory? _setupFlowOrchestratorFactory;
  final SetupFlowIntentFactory? _setupFlowIntentFactory;
  final NativeBootstrapCandidateLoaderFactory? _bootstrapCandidateLoaderFactory;
  final AppRecoveryPersistenceStoreFactory? _recoveryPersistenceStoreFactory;
  final DemoTableRuntimeScopeFactory? _tableRuntimeScopeFactory;

  @override
  State<PeerDealDesktopApp> createState() => _PeerDealDesktopAppState();
}

class _PeerDealDesktopAppState extends State<PeerDealDesktopApp> {
  final DemoSliceController _controller = DemoSliceController();
  final DemoNetworkConfidencePresenter _networkConfidencePresenter =
      const DemoNetworkConfidencePresenter();
  final DemoRecoveryResultFactory _recoveryResultFactory =
      const DemoRecoveryResultFactory();

  PeerDealDesktopRuntime get _runtime {
    return widget._runtime ??
        PeerDealDesktopRuntime(
          receiptPresenter: widget._receiptPresenter,
          receiptArtifactVerifierFactory:
              widget._receiptArtifactVerifierFactory,
          receiptExportArtifact: widget._receiptExportArtifact,
          receiptExportArtifactFactory: widget._receiptExportArtifactFactory,
          receiptFactory: widget._receiptFactory,
          joinFlowOrchestratorFactory: widget._joinFlowOrchestratorFactory,
          joinFlowInviteContextFactory: widget._joinFlowInviteContextFactory,
          setupFlowOrchestratorFactory: widget._setupFlowOrchestratorFactory,
          setupFlowIntentFactory: widget._setupFlowIntentFactory,
          bootstrapCandidateLoaderFactory:
              widget._bootstrapCandidateLoaderFactory,
          recoveryPersistenceStoreFactory:
              widget._recoveryPersistenceStoreFactory,
          tableRuntimeScopeFactory: widget._tableRuntimeScopeFactory,
        );
  }

  DemoReceiptSurfacePresenter? get _receiptPresenter =>
      _runtime.receiptPresenter;

  DemoScenarioSnapshot get _activeSnapshot {
    return DemoScenarioSnapshots.tryById(_controller.activeScenario.id) ??
        DemoScenarioSnapshots.snapshots.values.first;
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'PeerDeal Desktop',
      color: const Color(0xFF1B5E20),
      initialRoute: DemoSliceRoutes.home,
      pageRouteBuilder: <T>(settings, builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
        );
      },
      routes: DemoSliceRoutes.requireMountedRouteMap(
        <String, WidgetBuilder>{
          Navigator.defaultRouteName: _buildHome,
          DemoSliceRoutes.homeRoute.path: _buildHome,
          DemoSliceRoutes.tableRoute.path: (context) => DemoTableRoute(
            snapshot: _activeSnapshot,
            networkConfidence: _networkConfidencePresenter.present(
              _activeSnapshot,
            ),
            bootstrapCandidateLoaderFactory: _bootstrapCandidateLoaderFactory,
            recoveryPersistenceStoreFactory: _recoveryPersistenceStoreFactory,
            runtimeScopeFactory: _runtime.tableRuntimeScopeFactory,
            onOpenChat: () =>
                Navigator.of(context).pushNamed(DemoSliceRoutes.chatRoute.path),
            onOpenReceipt: () => Navigator.of(
              context,
            ).pushNamed(DemoSliceRoutes.receiptRoute.path),
          ),
          DemoSliceRoutes.chatRoute.path: (context) => DemoChatScreen(
            snapshot: _activeSnapshot,
            onOpenTable: () => Navigator.of(
              context,
            ).pushNamed(DemoSliceRoutes.tableRoute.path),
          ),
          DemoSliceRoutes.receiptRoute.path: (_) => DemoReceiptRoute(
            snapshot: _activeSnapshot,
            presenter: _receiptPresenter ?? DemoReceiptSurfacePresenter(),
            exportArtifact: _runtime.receiptExportArtifact,
            receipt: _safeReceiptFor(_activeSnapshot),
            exportArtifactFactory: _runtime.receiptExportArtifact == null
                ? _runtime.receiptExportArtifactFactory
                : null,
            artifactVerifier:
                _runtime.receiptExportArtifact == null &&
                    _runtime.receiptExportArtifactFactory == null
                ? null
                : _createReceiptArtifactVerifier(),
            recovery: _recoveryResultFactory.createFor(_activeSnapshot),
          ),
          DemoSliceRoutes.joinRoute.path: (_) => JoinFlowRoute(
            orchestratorFactory: _joinFlowOrchestratorFactory,
            inviteContextFactory: _runtime.joinFlowInviteContextFactory,
          ),
          DemoSliceRoutes.setupRoute.path: (_) => SetupFlowRoute(
            orchestratorFactory: _setupFlowOrchestratorFactory,
            setupIntentFactory: _runtime.setupFlowIntentFactory,
          ),
        },
        allowedExtraPaths: const <String>{Navigator.defaultRouteName},
      ),
      onUnknownRoute: _unknownRoute,
    );
  }

  Route<void> _unknownRoute(RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AppRouteFallbackScreen(routeName: settings.name);
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return DemoHomeScreen(
      controller: _controller,
      navigationActions: DemoSliceRoutes.primaryNavigation
          .map(
            (route) => DemoHomeNavigationAction(
              label: route.label,
              onPressed: () => Navigator.of(context).pushNamed(route.path),
            ),
          )
          .toList(growable: false),
      onSelectScenario: _selectScenario,
    );
  }

  void _selectScenario(String scenarioId) {
    if (!_controller.trySelectScenario(scenarioId)) return;
    setState(() {});
  }

  DemoReceiptArtifactVerifierFactory get _receiptArtifactVerifierFactory {
    return _runtime.receiptArtifactVerifierFactory ??
        DemoReceiptArtifactVerifierFactory.methodChannel();
  }

  DemoReceiptArtifactVerifier? _createReceiptArtifactVerifier() {
    try {
      return _receiptArtifactVerifierFactory.create();
    } on Object {
      return null;
    }
  }

  JoinFlowOrchestratorFactory get _joinFlowOrchestratorFactory {
    return _runtime.joinFlowOrchestratorFactory ??
        const DemoJoinFlowOrchestratorFactory().create;
  }

  SetupFlowOrchestratorFactory get _setupFlowOrchestratorFactory {
    return _runtime.setupFlowOrchestratorFactory ??
        () => const SetupFlowOrchestrator();
  }

  NativeBootstrapCandidateLoaderFactory get _bootstrapCandidateLoaderFactory {
    return _runtime.bootstrapCandidateLoaderFactory ??
        NativeBootstrapCandidateLoader.methodChannel;
  }

  AppRecoveryPersistenceStoreFactory? get _recoveryPersistenceStoreFactory {
    return _runtime.recoveryPersistenceStoreFactory ??
        AppRecoveryPersistenceStoreFactory.fromEnvironment();
  }

  PeerDealReceipt? _safeReceiptFor(DemoScenarioSnapshot snapshot) {
    try {
      return (_runtime.receiptFactory ?? _receiptFor)(snapshot);
    } on Object {
      return null;
    }
  }

  PeerDealReceipt _receiptFor(DemoScenarioSnapshot snapshot) {
    return PeerDealReceipt(
      receiptId: 'receipt_${snapshot.scenarioId}',
      receiptVersion: '1.0',
      protocolVersion: '1.x',
      modeType: snapshot.mode,
      sessionId: 'session_${snapshot.scenarioId}',
      tableId: 'table_${snapshot.scenarioId}',
      pseudonymousUserId: 'user_demo',
      bindingMode: _bindingModeFor(snapshot.receipt.bindingMode),
      wipeState: ReceiptWipeState.live,
      payloadHash: 'hash_${snapshot.scenarioId}',
      opaquePayload: 'opaque_${snapshot.scenarioId}',
    );
  }

  ReceiptBindingMode _bindingModeFor(String value) {
    return switch (value) {
      'session_bound' => ReceiptBindingMode.sessionBound,
      'user_bound' => ReceiptBindingMode.userBound,
      'mixed' => ReceiptBindingMode.mixed,
      _ => ReceiptBindingMode.sessionBound,
    };
  }
}

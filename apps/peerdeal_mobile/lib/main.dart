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
  runApp(const PeerDealMobileApp());
}

class PeerDealMobileRuntime {
  const PeerDealMobileRuntime({
    this.receiptPresenter,
    this.receiptArtifactVerifierFactory,
    this.receiptExportArtifact,
    this.receiptExportArtifactFactory,
    this.receiptFactory,
    this.joinFlowOrchestratorFactory,
    this.joinFlowInviteContextFactory,
    this.joinFlowEnabledModes,
    this.setupFlowOrchestratorFactory,
    this.setupFlowIntentFactory,
    this.setupFlowEnabledModes,
    this.bootstrapCandidateLoaderFactory,
    this.recoveryPersistenceStoreFactory,
    this.tableRuntimeScopeFactory,
    this.enabledDemoRoutePaths,
  });

  final DemoReceiptSurfacePresenter? receiptPresenter;
  final DemoReceiptArtifactVerifierFactory? receiptArtifactVerifierFactory;
  final ReceiptExportArtifact? receiptExportArtifact;
  final ReceiptExportArtifactBuilder? receiptExportArtifactFactory;
  final DemoReceiptFactory? receiptFactory;
  final JoinFlowOrchestratorFactory? joinFlowOrchestratorFactory;
  final JoinFlowInviteContextFactory? joinFlowInviteContextFactory;
  final Set<JoinFlowDemoMode>? joinFlowEnabledModes;
  final SetupFlowOrchestratorFactory? setupFlowOrchestratorFactory;
  final SetupFlowIntentFactory? setupFlowIntentFactory;
  final Set<SetupFlowDemoMode>? setupFlowEnabledModes;
  final NativeBootstrapCandidateLoaderFactory? bootstrapCandidateLoaderFactory;
  final AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory;
  final DemoTableRuntimeScopeFactory? tableRuntimeScopeFactory;
  final Set<String>? enabledDemoRoutePaths;

  PeerDealMobileRuntime withOverrides({
    DemoReceiptSurfacePresenter? receiptPresenter,
    DemoReceiptArtifactVerifierFactory? receiptArtifactVerifierFactory,
    ReceiptExportArtifact? receiptExportArtifact,
    ReceiptExportArtifactBuilder? receiptExportArtifactFactory,
    DemoReceiptFactory? receiptFactory,
    JoinFlowOrchestratorFactory? joinFlowOrchestratorFactory,
    JoinFlowInviteContextFactory? joinFlowInviteContextFactory,
    Set<JoinFlowDemoMode>? joinFlowEnabledModes,
    SetupFlowOrchestratorFactory? setupFlowOrchestratorFactory,
    SetupFlowIntentFactory? setupFlowIntentFactory,
    Set<SetupFlowDemoMode>? setupFlowEnabledModes,
    NativeBootstrapCandidateLoaderFactory? bootstrapCandidateLoaderFactory,
    AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory,
    DemoTableRuntimeScopeFactory? tableRuntimeScopeFactory,
    Set<String>? enabledDemoRoutePaths,
  }) {
    return PeerDealMobileRuntime(
      receiptPresenter: receiptPresenter ?? this.receiptPresenter,
      receiptArtifactVerifierFactory:
          receiptArtifactVerifierFactory ?? this.receiptArtifactVerifierFactory,
      receiptExportArtifact:
          receiptExportArtifact ?? this.receiptExportArtifact,
      receiptExportArtifactFactory:
          receiptExportArtifactFactory ?? this.receiptExportArtifactFactory,
      receiptFactory: receiptFactory ?? this.receiptFactory,
      joinFlowOrchestratorFactory:
          joinFlowOrchestratorFactory ?? this.joinFlowOrchestratorFactory,
      joinFlowInviteContextFactory:
          joinFlowInviteContextFactory ?? this.joinFlowInviteContextFactory,
      joinFlowEnabledModes: joinFlowEnabledModes ?? this.joinFlowEnabledModes,
      setupFlowOrchestratorFactory:
          setupFlowOrchestratorFactory ?? this.setupFlowOrchestratorFactory,
      setupFlowIntentFactory:
          setupFlowIntentFactory ?? this.setupFlowIntentFactory,
      setupFlowEnabledModes:
          setupFlowEnabledModes ?? this.setupFlowEnabledModes,
      bootstrapCandidateLoaderFactory:
          bootstrapCandidateLoaderFactory ??
          this.bootstrapCandidateLoaderFactory,
      recoveryPersistenceStoreFactory:
          recoveryPersistenceStoreFactory ??
          this.recoveryPersistenceStoreFactory,
      tableRuntimeScopeFactory:
          tableRuntimeScopeFactory ?? this.tableRuntimeScopeFactory,
      enabledDemoRoutePaths:
          enabledDemoRoutePaths ?? this.enabledDemoRoutePaths,
    );
  }
}

class PeerDealMobileApp extends StatefulWidget {
  const PeerDealMobileApp({
    super.key,
    PeerDealMobileRuntime? runtime,
    DemoReceiptSurfacePresenter? presenter,
    DemoReceiptArtifactVerifierFactory? receiptArtifactVerifierFactory,
    ReceiptExportArtifact? receiptExportArtifact,
    ReceiptExportArtifactBuilder? receiptExportArtifactFactory,
    DemoReceiptFactory? receiptFactory,
    JoinFlowOrchestratorFactory? joinFlowOrchestratorFactory,
    JoinFlowInviteContextFactory? joinFlowInviteContextFactory,
    Set<JoinFlowDemoMode>? joinFlowEnabledModes,
    SetupFlowOrchestratorFactory? setupFlowOrchestratorFactory,
    SetupFlowIntentFactory? setupFlowIntentFactory,
    Set<SetupFlowDemoMode>? setupFlowEnabledModes,
    NativeBootstrapCandidateLoaderFactory? bootstrapCandidateLoaderFactory,
    AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory,
    DemoTableRuntimeScopeFactory? tableRuntimeScopeFactory,
    Set<String>? enabledDemoRoutePaths,
  }) : _runtime = runtime,
       _receiptPresenter = presenter,
       _receiptArtifactVerifierFactory = receiptArtifactVerifierFactory,
       _receiptExportArtifact = receiptExportArtifact,
       _receiptExportArtifactFactory = receiptExportArtifactFactory,
       _receiptFactory = receiptFactory,
       _joinFlowOrchestratorFactory = joinFlowOrchestratorFactory,
       _joinFlowInviteContextFactory = joinFlowInviteContextFactory,
       _joinFlowEnabledModes = joinFlowEnabledModes,
       _setupFlowOrchestratorFactory = setupFlowOrchestratorFactory,
       _setupFlowIntentFactory = setupFlowIntentFactory,
       _setupFlowEnabledModes = setupFlowEnabledModes,
       _bootstrapCandidateLoaderFactory = bootstrapCandidateLoaderFactory,
       _recoveryPersistenceStoreFactory = recoveryPersistenceStoreFactory,
       _tableRuntimeScopeFactory = tableRuntimeScopeFactory,
       _enabledDemoRoutePaths = enabledDemoRoutePaths;

  final PeerDealMobileRuntime? _runtime;
  final DemoReceiptSurfacePresenter? _receiptPresenter;
  final DemoReceiptArtifactVerifierFactory? _receiptArtifactVerifierFactory;
  final ReceiptExportArtifact? _receiptExportArtifact;
  final ReceiptExportArtifactBuilder? _receiptExportArtifactFactory;
  final DemoReceiptFactory? _receiptFactory;
  final JoinFlowOrchestratorFactory? _joinFlowOrchestratorFactory;
  final JoinFlowInviteContextFactory? _joinFlowInviteContextFactory;
  final Set<JoinFlowDemoMode>? _joinFlowEnabledModes;
  final SetupFlowOrchestratorFactory? _setupFlowOrchestratorFactory;
  final SetupFlowIntentFactory? _setupFlowIntentFactory;
  final Set<SetupFlowDemoMode>? _setupFlowEnabledModes;
  final NativeBootstrapCandidateLoaderFactory? _bootstrapCandidateLoaderFactory;
  final AppRecoveryPersistenceStoreFactory? _recoveryPersistenceStoreFactory;
  final DemoTableRuntimeScopeFactory? _tableRuntimeScopeFactory;
  final Set<String>? _enabledDemoRoutePaths;

  @override
  State<PeerDealMobileApp> createState() => _PeerDealMobileAppState();
}

class _PeerDealMobileAppState extends State<PeerDealMobileApp> {
  final DemoSliceController _controller = DemoSliceController();
  final DemoNetworkConfidencePresenter _networkConfidencePresenter =
      const DemoNetworkConfidencePresenter();
  final DemoRecoveryResultFactory _recoveryResultFactory =
      const DemoRecoveryResultFactory();

  PeerDealMobileRuntime get _runtime {
    return (widget._runtime ?? const PeerDealMobileRuntime()).withOverrides(
      receiptPresenter: widget._receiptPresenter,
      receiptArtifactVerifierFactory: widget._receiptArtifactVerifierFactory,
      receiptExportArtifact: widget._receiptExportArtifact,
      receiptExportArtifactFactory: widget._receiptExportArtifactFactory,
      receiptFactory: widget._receiptFactory,
      joinFlowOrchestratorFactory: widget._joinFlowOrchestratorFactory,
      joinFlowInviteContextFactory: widget._joinFlowInviteContextFactory,
      joinFlowEnabledModes: widget._joinFlowEnabledModes,
      setupFlowOrchestratorFactory: widget._setupFlowOrchestratorFactory,
      setupFlowIntentFactory: widget._setupFlowIntentFactory,
      setupFlowEnabledModes: widget._setupFlowEnabledModes,
      bootstrapCandidateLoaderFactory: widget._bootstrapCandidateLoaderFactory,
      recoveryPersistenceStoreFactory: widget._recoveryPersistenceStoreFactory,
      tableRuntimeScopeFactory: widget._tableRuntimeScopeFactory,
      enabledDemoRoutePaths: widget._enabledDemoRoutePaths,
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
    final enabledMountedRoutes = DemoSliceRoutes.enabledMountedRoutes(
      _runtime.enabledDemoRoutePaths,
    );
    final enabledRoutePaths = enabledMountedRoutes
        .map((route) => route.path)
        .toSet();
    return WidgetsApp(
      title: 'PeerDeal Mobile',
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
          if (enabledRoutePaths.contains(DemoSliceRoutes.tableRoute.path))
            DemoSliceRoutes.tableRoute.path: (context) => DemoTableRoute(
              snapshot: _activeSnapshot,
              networkConfidence: _networkConfidencePresenter.present(
                _activeSnapshot,
              ),
              bootstrapCandidateLoaderFactory: _bootstrapCandidateLoaderFactory,
              recoveryPersistenceStoreFactory: _recoveryPersistenceStoreFactory,
              runtimeScopeFactory: _runtime.tableRuntimeScopeFactory,
              onOpenChat:
                  enabledRoutePaths.contains(DemoSliceRoutes.chatRoute.path)
                  ? () => Navigator.of(
                      context,
                    ).pushNamed(DemoSliceRoutes.chatRoute.path)
                  : null,
              onOpenReceipt:
                  enabledRoutePaths.contains(DemoSliceRoutes.receiptRoute.path)
                  ? () => Navigator.of(
                      context,
                    ).pushNamed(DemoSliceRoutes.receiptRoute.path)
                  : null,
            ),
          if (enabledRoutePaths.contains(DemoSliceRoutes.chatRoute.path))
            DemoSliceRoutes.chatRoute.path: (context) => DemoChatScreen(
              snapshot: _activeSnapshot,
              onOpenTable:
                  enabledRoutePaths.contains(DemoSliceRoutes.tableRoute.path)
                  ? () => Navigator.of(
                      context,
                    ).pushNamed(DemoSliceRoutes.tableRoute.path)
                  : null,
            ),
          if (enabledRoutePaths.contains(DemoSliceRoutes.receiptRoute.path))
            DemoSliceRoutes.receiptRoute.path: (_) => DemoReceiptRoute(
              snapshot: _activeSnapshot,
              presenter: _receiptPresenter ?? DemoReceiptSurfacePresenter(),
              exportArtifact: _runtime.receiptExportArtifact,
              receipt: _receiptInputFor(_activeSnapshot),
              exportArtifactFactory: _runtime.receiptExportArtifactFactory,
              artifactVerifier:
                  _runtime.receiptExportArtifact == null &&
                      _runtime.receiptExportArtifactFactory == null
                  ? null
                  : _createReceiptArtifactVerifier(),
              recovery: _recoveryResultFactory.createFor(_activeSnapshot),
            ),
          if (enabledRoutePaths.contains(DemoSliceRoutes.joinRoute.path))
            DemoSliceRoutes.joinRoute.path: (_) => JoinFlowRoute(
              orchestratorFactory: _joinFlowOrchestratorFactory,
              inviteContextFactory: _runtime.joinFlowInviteContextFactory,
              enabledModes: _runtime.joinFlowEnabledModes,
            ),
          if (enabledRoutePaths.contains(DemoSliceRoutes.setupRoute.path))
            DemoSliceRoutes.setupRoute.path: (_) => SetupFlowRoute(
              orchestratorFactory: _setupFlowOrchestratorFactory,
              setupIntentFactory: _runtime.setupFlowIntentFactory,
              enabledModes: _runtime.setupFlowEnabledModes,
            ),
        },
        expectedRoutes: enabledMountedRoutes,
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
      navigationActions:
          DemoSliceRoutes.enabledPrimaryNavigation(
                _runtime.enabledDemoRoutePaths,
              )
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

  PeerDealReceipt? _receiptInputFor(DemoScenarioSnapshot snapshot) {
    if (_runtime.receiptFactory == null &&
        _runtime.receiptExportArtifactFactory == null) {
      return null;
    }

    return _safeReceiptFor(snapshot);
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

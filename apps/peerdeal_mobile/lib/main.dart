import 'package:flutter/widgets.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'demo_slice/controllers/demo_network_confidence_presenter.dart';
import 'demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'demo_slice/controllers/demo_receipt_artifact_verifier_factory.dart';
import 'demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'demo_slice/controllers/demo_recovery_result_factory.dart';
import 'demo_slice/controllers/demo_slice_controller.dart';
import 'demo_slice/controllers/native_bootstrap_candidate_loader.dart';
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
import 'setup_flow/setup_flow_orchestrator.dart';
import 'setup_flow/setup_flow_route.dart';

void main() {
  runApp(const PeerDealMobileApp());
}

class PeerDealMobileApp extends StatefulWidget {
  const PeerDealMobileApp({
    super.key,
    DemoReceiptSurfacePresenter? presenter,
    DemoReceiptArtifactVerifierFactory? receiptArtifactVerifierFactory,
    ReceiptExportArtifact? receiptExportArtifact,
    JoinFlowOrchestratorFactory? joinFlowOrchestratorFactory,
    SetupFlowOrchestratorFactory? setupFlowOrchestratorFactory,
    NativeBootstrapCandidateLoaderFactory? bootstrapCandidateLoaderFactory,
  }) : _receiptPresenter = presenter,
       _receiptArtifactVerifierFactory = receiptArtifactVerifierFactory,
       _receiptExportArtifact = receiptExportArtifact,
       _joinFlowOrchestratorFactory = joinFlowOrchestratorFactory,
       _setupFlowOrchestratorFactory = setupFlowOrchestratorFactory,
       _bootstrapCandidateLoaderFactory = bootstrapCandidateLoaderFactory;

  final DemoReceiptSurfacePresenter? _receiptPresenter;
  final DemoReceiptArtifactVerifierFactory? _receiptArtifactVerifierFactory;
  final ReceiptExportArtifact? _receiptExportArtifact;
  final JoinFlowOrchestratorFactory? _joinFlowOrchestratorFactory;
  final SetupFlowOrchestratorFactory? _setupFlowOrchestratorFactory;
  final NativeBootstrapCandidateLoaderFactory? _bootstrapCandidateLoaderFactory;

  @override
  State<PeerDealMobileApp> createState() => _PeerDealMobileAppState();
}

class _PeerDealMobileAppState extends State<PeerDealMobileApp> {
  final DemoSliceController _controller = DemoSliceController();
  final DemoNetworkConfidencePresenter _networkConfidencePresenter =
      const DemoNetworkConfidencePresenter();
  final DemoRecoveryResultFactory _recoveryResultFactory =
      const DemoRecoveryResultFactory();

  DemoReceiptSurfacePresenter? get _receiptPresenter =>
      widget._receiptPresenter;

  DemoScenarioSnapshot get _activeSnapshot {
    return DemoScenarioSnapshots.tryById(_controller.activeScenario.id) ??
        DemoScenarioSnapshots.snapshots.values.first;
  }

  @override
  Widget build(BuildContext context) {
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
      routes: <String, WidgetBuilder>{
        Navigator.defaultRouteName: _buildHome,
        DemoSliceRoutes.home: _buildHome,
        DemoSliceRoutes.table: (context) => DemoTableRoute(
          snapshot: _activeSnapshot,
          networkConfidence: _networkConfidencePresenter.present(
            _activeSnapshot,
          ),
          bootstrapCandidateLoaderFactory: _bootstrapCandidateLoaderFactory,
          onOpenChat: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.chat),
          onOpenReceipt: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.receipt),
        ),
        DemoSliceRoutes.chat: (context) => DemoChatScreen(
          snapshot: _activeSnapshot,
          onOpenTable: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.table),
        ),
        DemoSliceRoutes.receipt: (_) => DemoReceiptRoute(
          snapshot: _activeSnapshot,
          presenter: _receiptPresenter ?? DemoReceiptSurfacePresenter(),
          exportArtifact: widget._receiptExportArtifact,
          artifactVerifier: widget._receiptExportArtifact == null
              ? null
              : _createReceiptArtifactVerifier(),
          recovery: _recoveryResultFactory.createFor(_activeSnapshot),
        ),
        DemoSliceRoutes.join: (_) =>
            JoinFlowRoute(orchestratorFactory: _joinFlowOrchestratorFactory),
        DemoSliceRoutes.setup: (_) =>
            SetupFlowRoute(orchestratorFactory: _setupFlowOrchestratorFactory),
      },
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
      onOpenTable: () => Navigator.of(context).pushNamed(DemoSliceRoutes.table),
      onOpenChat: () => Navigator.of(context).pushNamed(DemoSliceRoutes.chat),
      onOpenReceipt: () =>
          Navigator.of(context).pushNamed(DemoSliceRoutes.receipt),
      onOpenJoin: () => Navigator.of(context).pushNamed(DemoSliceRoutes.join),
      onOpenSetup: () => Navigator.of(context).pushNamed(DemoSliceRoutes.setup),
      onSelectScenario: _selectScenario,
    );
  }

  void _selectScenario(String scenarioId) {
    if (!_controller.trySelectScenario(scenarioId)) return;
    setState(() {});
  }

  DemoReceiptArtifactVerifierFactory get _receiptArtifactVerifierFactory {
    return widget._receiptArtifactVerifierFactory ??
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
    return widget._joinFlowOrchestratorFactory ??
        const DemoJoinFlowOrchestratorFactory().create;
  }

  SetupFlowOrchestratorFactory get _setupFlowOrchestratorFactory {
    return widget._setupFlowOrchestratorFactory ??
        () => const SetupFlowOrchestrator();
  }

  NativeBootstrapCandidateLoaderFactory get _bootstrapCandidateLoaderFactory {
    return widget._bootstrapCandidateLoaderFactory ??
        NativeBootstrapCandidateLoader.methodChannel;
  }
}

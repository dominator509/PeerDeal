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
import 'native_readiness/app_native_readiness_loader.dart';
import 'navigation/app_route_fallback_screen.dart';
import 'recovery/app_recovery_persistence_store_factory.dart';
import 'setup_flow/setup_flow_orchestrator.dart';
import 'setup_flow/setup_flow_route.dart';

typedef DemoReceiptFactory =
    PeerDealReceipt Function(DemoScenarioSnapshot snapshot);
typedef PeerDealAppRouteMap = Map<String, WidgetBuilder>;
typedef PeerDealHomeSurfaceBuilder =
    Widget Function(
      BuildContext context,
      List<PeerDealAppNavigationEntry> navigation,
    );

const int _maxAppRoutePathLength = 96;
const int _maxAppNavigationLabelLength = 48;
const int _maxAppProductionRoutes = 24;
const int _maxAppProductionNavigationEntries = 16;

class PeerDealAppNavigationEntry {
  const PeerDealAppNavigationEntry({required this.label, required this.path});

  final String label;
  final String path;
}

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
    this.joinFlowEnabledModes,
    this.setupFlowOrchestratorFactory,
    this.setupFlowIntentFactory,
    this.setupFlowEnabledModes,
    this.bootstrapCandidateLoaderFactory,
    this.recoveryPersistenceStoreFactory,
    this.tableRuntimeScopeFactory,
    this.enabledDemoRoutePaths,
    this.productionRoutes,
    this.productionNavigation,
    this.homeSurfaceBuilder,
    this.nativeReadinessLoader,
    this.nativeReadinessRequiredRoutePaths,
    this.initialRoute,
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
  final PeerDealAppRouteMap? productionRoutes;
  final List<PeerDealAppNavigationEntry>? productionNavigation;
  final PeerDealHomeSurfaceBuilder? homeSurfaceBuilder;
  final AppNativeReadinessLoader? nativeReadinessLoader;
  final Set<String>? nativeReadinessRequiredRoutePaths;
  final String? initialRoute;

  PeerDealDesktopRuntime withOverrides({
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
    PeerDealAppRouteMap? productionRoutes,
    List<PeerDealAppNavigationEntry>? productionNavigation,
    PeerDealHomeSurfaceBuilder? homeSurfaceBuilder,
    AppNativeReadinessLoader? nativeReadinessLoader,
    Set<String>? nativeReadinessRequiredRoutePaths,
    String? initialRoute,
  }) {
    return PeerDealDesktopRuntime(
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
      productionRoutes: productionRoutes ?? this.productionRoutes,
      productionNavigation: productionNavigation ?? this.productionNavigation,
      homeSurfaceBuilder: homeSurfaceBuilder ?? this.homeSurfaceBuilder,
      nativeReadinessLoader:
          nativeReadinessLoader ?? this.nativeReadinessLoader,
      nativeReadinessRequiredRoutePaths:
          nativeReadinessRequiredRoutePaths ??
          this.nativeReadinessRequiredRoutePaths,
      initialRoute: initialRoute ?? this.initialRoute,
    );
  }
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
    Set<JoinFlowDemoMode>? joinFlowEnabledModes,
    SetupFlowOrchestratorFactory? setupFlowOrchestratorFactory,
    SetupFlowIntentFactory? setupFlowIntentFactory,
    Set<SetupFlowDemoMode>? setupFlowEnabledModes,
    NativeBootstrapCandidateLoaderFactory? bootstrapCandidateLoaderFactory,
    AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory,
    DemoTableRuntimeScopeFactory? tableRuntimeScopeFactory,
    Set<String>? enabledDemoRoutePaths,
    PeerDealAppRouteMap? productionRoutes,
    List<PeerDealAppNavigationEntry>? productionNavigation,
    PeerDealHomeSurfaceBuilder? homeSurfaceBuilder,
    AppNativeReadinessLoader? nativeReadinessLoader,
    Set<String>? nativeReadinessRequiredRoutePaths,
    String? initialRoute,
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
       _enabledDemoRoutePaths = enabledDemoRoutePaths,
       _productionRoutes = productionRoutes,
       _productionNavigation = productionNavigation,
       _homeSurfaceBuilder = homeSurfaceBuilder,
       _nativeReadinessLoader = nativeReadinessLoader,
       _nativeReadinessRequiredRoutePaths = nativeReadinessRequiredRoutePaths,
       _initialRoute = initialRoute;

  final PeerDealDesktopRuntime? _runtime;
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
  final PeerDealAppRouteMap? _productionRoutes;
  final List<PeerDealAppNavigationEntry>? _productionNavigation;
  final PeerDealHomeSurfaceBuilder? _homeSurfaceBuilder;
  final AppNativeReadinessLoader? _nativeReadinessLoader;
  final Set<String>? _nativeReadinessRequiredRoutePaths;
  final String? _initialRoute;

  @override
  State<PeerDealDesktopApp> createState() => _PeerDealDesktopAppState();
}

class _PeerDealDesktopAppState extends State<PeerDealDesktopApp> {
  final DemoSliceController _controller = DemoSliceController();
  final DemoNetworkConfidencePresenter _networkConfidencePresenter =
      const DemoNetworkConfidencePresenter();
  final DemoRecoveryResultFactory _recoveryResultFactory =
      const DemoRecoveryResultFactory();
  AppNativeReadinessLoader? _nativeReadinessLoaderForFuture;
  Future<AppNativeReadinessSnapshot>? _nativeReadinessFuture;

  PeerDealDesktopRuntime get _runtime {
    return (widget._runtime ?? const PeerDealDesktopRuntime()).withOverrides(
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
      productionRoutes: widget._productionRoutes,
      productionNavigation: widget._productionNavigation,
      homeSurfaceBuilder: widget._homeSurfaceBuilder,
      nativeReadinessLoader: widget._nativeReadinessLoader,
      nativeReadinessRequiredRoutePaths:
          widget._nativeReadinessRequiredRoutePaths,
      initialRoute: widget._initialRoute,
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
    final demoNavigation = DemoSliceRoutes.enabledPrimaryNavigation(
      _runtime.enabledDemoRoutePaths,
    );
    final nativeReadinessRequiredRoutePaths =
        _validatedNativeReadinessRequiredRoutes(
          _runtime.nativeReadinessRequiredRoutePaths,
        );
    final productionRoutes = _validatedProductionRoutes(
      _runtime.productionRoutes,
      nativeReadinessRequiredRoutePaths: nativeReadinessRequiredRoutePaths,
    );
    final productionNavigation = _validatedProductionNavigation(
      _runtime.productionNavigation,
      productionRoutes.keys.toSet(),
      demoNavigationLabels: demoNavigation.map((route) => route.label).toSet(),
      demoNavigationPaths: demoNavigation.map((route) => route.path).toSet(),
    );
    final initialRoute = _validatedInitialRoute(
      enabledRoutePaths: enabledRoutePaths,
      productionRoutePaths: productionRoutes.keys.toSet(),
      initialRoute: _runtime.initialRoute,
    );
    return WidgetsApp(
      title: 'PeerDeal Desktop',
      color: const Color(0xFF1B5E20),
      initialRoute: initialRoute,
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
          Navigator.defaultRouteName: (context) =>
              _buildHome(context, productionNavigation),
          DemoSliceRoutes.homeRoute.path: (context) =>
              _buildHome(context, productionNavigation),
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
          ...productionRoutes,
        },
        expectedRoutes: enabledMountedRoutes,
        allowedExtraPaths: <String>{
          Navigator.defaultRouteName,
          ...productionRoutes.keys,
        },
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

  Widget _buildHome(
    BuildContext context,
    List<PeerDealAppNavigationEntry> productionNavigation,
  ) {
    final demoNavigation = _demoHomeNavigationEntries();
    final homeSurfaceBuilder = _runtime.homeSurfaceBuilder;
    final nativeReadinessLoader = _runtime.nativeReadinessLoader;
    if (nativeReadinessLoader == null) {
      final readyProductionNavigation = _homeNavigationForReadiness(
        productionNavigation,
        nativeReadiness: null,
      );
      if (homeSurfaceBuilder != null) {
        return _buildCustomHome(
          context,
          homeSurfaceBuilder,
          demoNavigation,
          readyProductionNavigation,
        );
      }
      return _buildDefaultHome(
        context,
        demoNavigation,
        readyProductionNavigation,
        hasProductionNavigation: productionNavigation.isNotEmpty,
        nativeReadiness: null,
      );
    }
    return FutureBuilder<AppNativeReadinessSnapshot>(
      future: _nativeReadinessFor(nativeReadinessLoader),
      builder: (context, snapshot) {
        final nativeReadiness = snapshot.data;
        final readyProductionNavigation = _homeNavigationForReadiness(
          productionNavigation,
          nativeReadiness: nativeReadiness,
        );
        if (homeSurfaceBuilder != null) {
          return _buildCustomHome(
            context,
            homeSurfaceBuilder,
            demoNavigation,
            readyProductionNavigation,
          );
        }
        return _buildDefaultHome(
          context,
          demoNavigation,
          readyProductionNavigation,
          hasProductionNavigation: productionNavigation.isNotEmpty,
          nativeReadiness: nativeReadiness,
        );
      },
    );
  }

  Widget _buildCustomHome(
    BuildContext context,
    PeerDealHomeSurfaceBuilder homeSurfaceBuilder,
    List<PeerDealAppNavigationEntry> demoNavigation,
    List<PeerDealAppNavigationEntry> productionNavigation,
  ) {
    try {
      return homeSurfaceBuilder(
        context,
        _homeNavigationEntries(
          demoNavigation: demoNavigation,
          productionNavigation: productionNavigation,
        ),
      );
    } catch (_) {
      return const AppRouteFallbackScreen(routeName: DemoSliceRoutes.home);
    }
  }

  Widget _buildDefaultHome(
    BuildContext context,
    List<PeerDealAppNavigationEntry> demoNavigation,
    List<PeerDealAppNavigationEntry> productionNavigation, {
    required bool hasProductionNavigation,
    required AppNativeReadinessSnapshot? nativeReadiness,
  }) {
    final productionOnly = demoNavigation.isEmpty && hasProductionNavigation;
    return DemoHomeScreen(
      controller: _controller,
      title: productionOnly ? 'PeerDeal' : 'PeerDeal demo',
      subtitle: productionOnly
          ? 'Production app routes'
          : 'Fixture-backed app orchestration',
      showDemoScenarios: !productionOnly,
      hasProductionNavigation: hasProductionNavigation,
      demoNavigationActions: demoNavigation
          .map(
            (route) => DemoHomeNavigationAction(
              label: route.label,
              onPressed: () => Navigator.of(context).pushNamed(route.path),
            ),
          )
          .toList(growable: false),
      productionNavigationActions: productionNavigation
          .map(
            (route) => DemoHomeNavigationAction(
              label: route.label,
              onPressed: () => Navigator.of(context).pushNamed(route.path),
            ),
          )
          .toList(growable: false),
      nativeReadiness: nativeReadiness,
      onSelectScenario: _selectScenario,
    );
  }

  List<PeerDealAppNavigationEntry> _homeNavigationForReadiness(
    List<PeerDealAppNavigationEntry> navigation, {
    required AppNativeReadinessSnapshot? nativeReadiness,
  }) {
    final protectedPaths = _runtime.nativeReadinessRequiredRoutePaths;
    if (protectedPaths == null || protectedPaths.isEmpty) return navigation;
    if (nativeReadiness == null || !nativeReadiness.allCapabilitiesReady) {
      return List<PeerDealAppNavigationEntry>.unmodifiable(
        navigation.where((entry) => !protectedPaths.contains(entry.path)),
      );
    }
    return navigation;
  }

  Future<AppNativeReadinessSnapshot> _nativeReadinessFor(
    AppNativeReadinessLoader loader,
  ) {
    if (!identical(_nativeReadinessLoaderForFuture, loader)) {
      _nativeReadinessLoaderForFuture = loader;
      _nativeReadinessFuture = loader.load().catchError(
        (_) => const AppNativeReadinessSnapshot(
          captureProtectionReady: false,
          localNetworkDiscoveryReady: false,
          nativeTransportReady: false,
          secureKeyStorageReady: false,
          warnings: <String>['native readiness unavailable'],
        ),
      );
    }
    return _nativeReadinessFuture!;
  }

  List<PeerDealAppNavigationEntry> _homeNavigationEntries({
    required List<PeerDealAppNavigationEntry> demoNavigation,
    required List<PeerDealAppNavigationEntry> productionNavigation,
  }) {
    final labels = <String>{};
    final paths = <String>{};
    final combined = <PeerDealAppNavigationEntry>[];

    for (final entry in <PeerDealAppNavigationEntry>[
      ...demoNavigation,
      ...productionNavigation,
    ]) {
      if (!labels.add(entry.label) || !paths.add(entry.path)) {
        throw StateError('Home navigation contains duplicate metadata.');
      }
      combined.add(entry);
    }

    return List<PeerDealAppNavigationEntry>.unmodifiable(combined);
  }

  List<PeerDealAppNavigationEntry> _demoHomeNavigationEntries() {
    return List<PeerDealAppNavigationEntry>.unmodifiable(
      DemoSliceRoutes.enabledPrimaryNavigation(
        _runtime.enabledDemoRoutePaths,
      ).map(
        (route) =>
            PeerDealAppNavigationEntry(label: route.label, path: route.path),
      ),
    );
  }

  void _selectScenario(String scenarioId) {
    if (!_controller.trySelectScenario(scenarioId)) return;
    setState(() {});
  }

  PeerDealAppRouteMap _validatedProductionRoutes(
    PeerDealAppRouteMap? routes, {
    required Set<String> nativeReadinessRequiredRoutePaths,
  }) {
    if (routes == null || routes.isEmpty) {
      if (nativeReadinessRequiredRoutePaths.isNotEmpty) {
        throw StateError(
          'Native readiness route gate references invalid path.',
        );
      }
      return const <String, WidgetBuilder>{};
    }
    if (routes.length > _maxAppProductionRoutes) {
      throw StateError('Production route map contains too many routes.');
    }

    final mountedDemoPaths = DemoSliceRoutes.mountedRoutes
        .map((route) => route.path)
        .toSet();
    final validated = <String, WidgetBuilder>{};
    final lowerPaths = <String>{};

    for (final entry in routes.entries) {
      final path = entry.key.trim();
      final lowerPath = path.toLowerCase();
      if (path != entry.key ||
          path.isEmpty ||
          !path.startsWith('/') ||
          path == Navigator.defaultRouteName ||
          path.length > _maxAppRoutePathLength ||
          lowerPath.startsWith('/demo') ||
          path.endsWith('/') ||
          path.contains('?') ||
          path.contains('#') ||
          path.contains('//') ||
          path.contains(r'\') ||
          _containsUnsafeRoutePathCharacter(path) ||
          mountedDemoPaths.contains(path)) {
        throw StateError('Production route map contains an invalid path.');
      }
      if (validated.containsKey(path)) {
        throw StateError('Production route map contains duplicate paths.');
      }
      if (!lowerPaths.add(lowerPath)) {
        throw StateError('Production route map contains duplicate paths.');
      }
      validated[path] = nativeReadinessRequiredRoutePaths.contains(path)
          ? (context) => _buildNativeReadyProductionRoute(
              context: context,
              path: path,
              builder: entry.value,
            )
          : (context) => _buildProductionRoute(
              context: context,
              path: path,
              builder: entry.value,
            );
    }

    for (final path in nativeReadinessRequiredRoutePaths) {
      if (!validated.containsKey(path)) {
        throw StateError(
          'Native readiness route gate references invalid path.',
        );
      }
    }

    return Map<String, WidgetBuilder>.unmodifiable(validated);
  }

  Set<String> _validatedNativeReadinessRequiredRoutes(Set<String>? paths) {
    if (paths == null || paths.isEmpty) return const <String>{};
    if (paths.length > _maxAppProductionRoutes) {
      throw StateError('Native readiness route gate contains too many paths.');
    }

    final validated = <String>{};
    final lowerPaths = <String>{};
    for (final path in paths) {
      final lowerPath = path.toLowerCase();
      if (path.trim() != path ||
          path.isEmpty ||
          !path.startsWith('/') ||
          path == Navigator.defaultRouteName ||
          path.length > _maxAppRoutePathLength ||
          lowerPath.startsWith('/demo') ||
          path.endsWith('/') ||
          path.contains('?') ||
          path.contains('#') ||
          path.contains('//') ||
          path.contains(r'\') ||
          _containsUnsafeRoutePathCharacter(path) ||
          !validated.add(path) ||
          !lowerPaths.add(lowerPath)) {
        throw StateError('Native readiness route gate contains invalid path.');
      }
    }
    return Set<String>.unmodifiable(validated);
  }

  Widget _buildNativeReadyProductionRoute({
    required BuildContext context,
    required String path,
    required WidgetBuilder builder,
  }) {
    final nativeReadinessLoader = _runtime.nativeReadinessLoader;
    if (nativeReadinessLoader == null) {
      return AppRouteFallbackScreen(routeName: path);
    }
    return FutureBuilder<AppNativeReadinessSnapshot>(
      future: _nativeReadinessFor(nativeReadinessLoader),
      builder: (context, snapshot) {
        final readiness = snapshot.data;
        if (readiness == null || !readiness.allCapabilitiesReady) {
          return AppRouteFallbackScreen(routeName: path);
        }
        return _buildProductionRoute(
          context: context,
          path: path,
          builder: builder,
        );
      },
    );
  }

  Widget _buildProductionRoute({
    required BuildContext context,
    required String path,
    required WidgetBuilder builder,
  }) {
    try {
      return builder(context);
    } on Object {
      return AppRouteFallbackScreen(routeName: path);
    }
  }

  List<PeerDealAppNavigationEntry> _validatedProductionNavigation(
    List<PeerDealAppNavigationEntry>? navigation,
    Set<String> productionRoutePaths, {
    required Set<String> demoNavigationLabels,
    required Set<String> demoNavigationPaths,
  }) {
    if (navigation == null || navigation.isEmpty) {
      return const <PeerDealAppNavigationEntry>[];
    }
    if (navigation.length > _maxAppProductionNavigationEntries) {
      throw StateError('Production navigation contains too many entries.');
    }

    final lowerDemoNavigationLabels = demoNavigationLabels
        .map((label) => label.toLowerCase())
        .toSet();
    final lowerDemoNavigationPaths = demoNavigationPaths
        .map((path) => path.toLowerCase())
        .toSet();
    final labels = <String>{};
    final paths = <String>{};
    final lowerLabels = <String>{};
    final lowerPaths = <String>{};
    final validated = <PeerDealAppNavigationEntry>[];

    for (final entry in navigation) {
      final label = entry.label.trim();
      final path = entry.path.trim();
      final lowerLabel = label.toLowerCase();
      final lowerPath = path.toLowerCase();
      if (label.isEmpty ||
          label != entry.label ||
          label.length > _maxAppNavigationLabelLength ||
          _containsUnsafeLabelCharacter(label) ||
          path != entry.path ||
          !productionRoutePaths.contains(path) ||
          demoNavigationLabels.contains(label) ||
          demoNavigationPaths.contains(path) ||
          lowerDemoNavigationLabels.contains(lowerLabel) ||
          lowerDemoNavigationPaths.contains(lowerPath) ||
          !labels.add(label) ||
          !paths.add(path) ||
          !lowerLabels.add(lowerLabel) ||
          !lowerPaths.add(lowerPath)) {
        throw StateError('Production navigation contains invalid metadata.');
      }
      validated.add(entry);
    }

    return List<PeerDealAppNavigationEntry>.unmodifiable(validated);
  }

  String _validatedInitialRoute({
    required Set<String> enabledRoutePaths,
    required Set<String> productionRoutePaths,
    required String? initialRoute,
  }) {
    final route = initialRoute ?? DemoSliceRoutes.home;
    if (route.trim() != route ||
        route.isEmpty ||
        route.length > _maxAppRoutePathLength ||
        route.contains('?') ||
        route.contains('#') ||
        route.contains('//') ||
        route.contains(r'\') ||
        _containsUnsafeRoutePathCharacter(route)) {
      throw StateError('Initial app route is invalid.');
    }
    if (route == Navigator.defaultRouteName ||
        enabledRoutePaths.contains(route) ||
        productionRoutePaths.contains(route)) {
      return route;
    }
    throw StateError('Initial app route is not mounted.');
  }

  bool _containsUnsafeRoutePathCharacter(String value) =>
      value.codeUnits.any((codeUnit) => codeUnit <= 0x20 || codeUnit == 0x7F);

  bool _containsUnsafeLabelCharacter(String value) =>
      value.codeUnits.any((codeUnit) => codeUnit < 0x20 || codeUnit == 0x7F);

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

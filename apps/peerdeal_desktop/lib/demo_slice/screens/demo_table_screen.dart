import 'package:flutter/widgets.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

import '../../recovery/app_recovery_persistence_store_factory.dart';
import '../controllers/demo_network_confidence_presenter.dart';
import '../controllers/native_bootstrap_candidate_loader.dart';
import '../models/demo_scenario_snapshot.dart';
import '../widgets/demo_status_banner.dart';

typedef DemoTableRuntimeScopeFactory =
    RecoveryPersistenceScope Function(DemoScenarioSnapshot snapshot);

class DemoTableRoute extends StatefulWidget {
  const DemoTableRoute({
    super.key,
    required this.snapshot,
    required this.networkConfidence,
    required this.bootstrapCandidateLoaderFactory,
    this.recoveryPersistenceStoreFactory,
    DemoTableRuntimeScopeFactory? runtimeScopeFactory,
    this.onOpenChat,
    this.onOpenReceipt,
  }) : _runtimeScopeFactory = runtimeScopeFactory ?? _defaultRuntimeScopeFor;

  final DemoScenarioSnapshot snapshot;
  final DemoNetworkConfidenceVm networkConfidence;
  final NativeBootstrapCandidateLoaderFactory bootstrapCandidateLoaderFactory;
  final AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory;
  final DemoTableRuntimeScopeFactory _runtimeScopeFactory;
  final VoidCallback? onOpenChat;
  final VoidCallback? onOpenReceipt;

  @override
  State<DemoTableRoute> createState() => _DemoTableRouteState();
}

class _DemoTableRouteState extends State<DemoTableRoute> {
  late Future<NativeBootstrapCandidateLoadResult> _bootstrapFuture;
  late Future<DemoRecoveryPersistenceLoadResult> _recoveryPersistenceFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _loadBootstrapCandidates();
    _recoveryPersistenceFuture = _loadRecoveryPersistence();
  }

  @override
  void didUpdateWidget(DemoTableRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.scenarioId != widget.snapshot.scenarioId ||
        oldWidget.bootstrapCandidateLoaderFactory !=
            widget.bootstrapCandidateLoaderFactory) {
      _bootstrapFuture = _loadBootstrapCandidates();
    }
    if (oldWidget.snapshot.scenarioId != widget.snapshot.scenarioId ||
        oldWidget.recoveryPersistenceStoreFactory !=
            widget.recoveryPersistenceStoreFactory) {
      _recoveryPersistenceFuture = _loadRecoveryPersistence();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NativeBootstrapCandidateLoadResult>(
      future: _bootstrapFuture,
      builder: (context, bootstrap) {
        return FutureBuilder<DemoRecoveryPersistenceLoadResult>(
          future: _recoveryPersistenceFuture,
          builder: (context, recoveryPersistence) {
            return DemoTableScreen(
              snapshot: widget.snapshot,
              networkConfidence: widget.networkConfidence,
              bootstrap: bootstrap.data,
              bootstrapLoading:
                  bootstrap.connectionState != ConnectionState.done,
              recoveryPersistence: recoveryPersistence.data,
              recoveryPersistenceLoading:
                  recoveryPersistence.connectionState != ConnectionState.done,
              onOpenChat: widget.onOpenChat,
              onOpenReceipt: widget.onOpenReceipt,
            );
          },
        );
      },
    );
  }

  Future<NativeBootstrapCandidateLoadResult> _loadBootstrapCandidates() async {
    try {
      final scope = widget._runtimeScopeFactory(widget.snapshot);
      return _safeBootstrapLoadResult(
        await widget.bootstrapCandidateLoaderFactory().load(
          sessionId: scope.sessionId,
          tableId: scope.tableId,
        ),
      );
    } on Object {
      return const NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: 'unavailable',
        warnings: <String>['Local network bootstrap loader unavailable.'],
      );
    }
  }

  Future<DemoRecoveryPersistenceLoadResult> _loadRecoveryPersistence() async {
    final factory = widget.recoveryPersistenceStoreFactory;
    if (factory == null) {
      return const DemoRecoveryPersistenceLoadResult.unavailable(
        warnings: <String>['Recovery persistence store factory unavailable.'],
      );
    }

    try {
      final scope = widget._runtimeScopeFactory(widget.snapshot);
      final result = factory.create();
      final store = result.store;
      if (store == null) {
        return DemoRecoveryPersistenceLoadResult.unavailable(
          warnings: _safeTableWarnings(
            result.warnings,
            fallback: 'Recovery persistence warning unavailable.',
          ),
        );
      }

      final window = store.loadWindow(scope);
      final persistedEventCount = _safePersistedEventCount(window);
      return DemoRecoveryPersistenceLoadResult.available(
        persistedEventCount: persistedEventCount,
        hasSnapshot: window.snapshot != null,
        warnings: <String>[
          ..._safeTableWarnings(
            result.warnings,
            fallback: 'Recovery persistence warning unavailable.',
          ),
          if (window.events.length > persistedEventCount)
            'Recovery persistence events truncated.',
        ],
      );
    } on Object {
      return const DemoRecoveryPersistenceLoadResult.unavailable(
        warnings: <String>['Recovery persistence window unavailable.'],
      );
    }
  }
}

RecoveryPersistenceScope _defaultRuntimeScopeFor(
  DemoScenarioSnapshot snapshot,
) {
  return RecoveryPersistenceScope(
    tableId: snapshot.scenarioId,
    sessionId: 'demo:${snapshot.scenarioId}',
    protocolVersion: '1.x',
  );
}

int _safePersistedEventCount(PersistedRecoveryWindow window) {
  const maxRecoveryPersistenceDisplayEvents = 128;
  return window.events.length > maxRecoveryPersistenceDisplayEvents
      ? maxRecoveryPersistenceDisplayEvents
      : window.events.length;
}

NativeBootstrapCandidateLoadResult _safeBootstrapLoadResult(
  NativeBootstrapCandidateLoadResult result,
) {
  const maxBootstrapCandidates = 32;
  final candidates = result.candidates
      .take(maxBootstrapCandidates)
      .toList(growable: false);
  return NativeBootstrapCandidateLoadResult(
    discoveryAvailable: result.discoveryAvailable,
    nativeNotes: result.nativeNotes,
    candidates: candidates,
    warnings: <String>[
      ..._safeTableWarnings(
        result.warnings,
        fallback: 'Local network bootstrap warning unavailable.',
      ),
      if (result.candidates.length > maxBootstrapCandidates)
        'Bootstrap candidates truncated.',
    ],
  );
}

List<String> _safeTableWarnings(
  List<String> warnings, {
  required String fallback,
}) {
  const maxWarnings = 4;
  if (warnings.isEmpty) {
    return const <String>[];
  }
  return <String>[
    for (final warning in warnings.take(maxWarnings))
      _safeTableWarning(warning, fallback: fallback),
    if (warnings.length > maxWarnings) 'Table warnings truncated.',
  ];
}

class DemoTableScreen extends StatelessWidget {
  const DemoTableScreen({
    super.key,
    required this.snapshot,
    required this.networkConfidence,
    this.bootstrap,
    this.bootstrapLoading = false,
    this.recoveryPersistence,
    this.recoveryPersistenceLoading = false,
    required this.onOpenChat,
    required this.onOpenReceipt,
  });

  final DemoScenarioSnapshot snapshot;
  final DemoNetworkConfidenceVm networkConfidence;
  final NativeBootstrapCandidateLoadResult? bootstrap;
  final bool bootstrapLoading;
  final DemoRecoveryPersistenceLoadResult? recoveryPersistence;
  final bool recoveryPersistenceLoading;
  final VoidCallback? onOpenChat;
  final VoidCallback? onOpenReceipt;

  @override
  Widget build(BuildContext context) {
    return PeerDealAppScaffold(
      title: 'Demo table',
      subtitle: 'Mounted table orchestration',
      actions: <Widget>[
        if (onOpenChat != null)
          PeerDealActionButton(label: 'Chat', onPressed: onOpenChat!),
        if (onOpenReceipt != null)
          PeerDealActionButton(label: 'Receipt', onPressed: onOpenReceipt!),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DemoStatusBanner(vm: snapshot.statusBanner),
          const SizedBox(height: 12),
          PeerDealInfoRow(label: 'Scenario', value: snapshot.scenarioId),
          Text('Scenario: ${snapshot.scenarioId}'),
          PeerDealInfoRow(label: 'Mode', value: snapshot.mode),
          Text('Mode: ${snapshot.mode}'),
          PeerDealInfoRow(label: 'Variant', value: snapshot.variant),
          Text('Variant: ${snapshot.variant}'),
          PeerDealInfoRow(
            label: 'Network',
            value: networkConfidence.confidence.name,
          ),
          Text('Network: ${networkConfidence.confidence.name}'),
          if (networkConfidence.recoveryRecommended)
            const Text('Network action: recovery_required'),
          if (bootstrapLoading)
            const Text('Bootstrap: loading')
          else if (bootstrap == null || !bootstrap!.discoveryAvailable)
            const Text('Bootstrap: unavailable')
          else
            Text('Bootstrap: ${bootstrap!.candidates.length} candidates'),
          if (bootstrap != null && bootstrap!.hasCandidates)
            Text(
              'Bootstrap route: ${bootstrap!.candidates.first.routeClass.name}',
            ),
          if (bootstrap != null && bootstrap!.warnings.isNotEmpty)
            Text(
              'Bootstrap warning: ${_safeTableWarning(bootstrap!.warnings.first, fallback: 'Local network bootstrap warning unavailable.')}',
            ),
          if (recoveryPersistenceLoading)
            const Text('Recovery persistence: loading')
          else if (recoveryPersistence == null ||
              !recoveryPersistence!.isAvailable)
            const Text('Recovery persistence: unavailable')
          else
            Text(
              'Recovery persistence: '
              '${recoveryPersistence!.persistedEventCount} events',
            ),
          if (recoveryPersistence != null &&
              recoveryPersistence!.warnings.isNotEmpty)
            Text(
              'Recovery persistence warning: '
              '${_safeTableWarning(recoveryPersistence!.warnings.first, fallback: 'Recovery persistence warning unavailable.')}',
            ),
          PeerDealInfoRow(
            label: 'Receipt',
            value: snapshot.receipt.verificationState,
          ),
          Text('Receipt: ${snapshot.receipt.verificationState}'),
        ],
      ),
    );
  }
}

String _safeTableWarning(String warning, {required String fallback}) {
  if (warning.trim() != warning || warning.isEmpty || warning.length > 96) {
    return fallback;
  }
  final lower = warning.toLowerCase();
  if (lower.contains('secret') || lower.contains('token')) {
    return fallback;
  }
  final isPrintable = warning.codeUnits.every(
    (codeUnit) => codeUnit >= 0x20 && codeUnit != 0x5C && codeUnit != 0x7F,
  );
  return isPrintable ? warning : fallback;
}

class DemoRecoveryPersistenceLoadResult {
  const DemoRecoveryPersistenceLoadResult.available({
    required this.persistedEventCount,
    required this.hasSnapshot,
    this.warnings = const <String>[],
  }) : isAvailable = true;

  const DemoRecoveryPersistenceLoadResult.unavailable({required this.warnings})
    : isAvailable = false,
      persistedEventCount = 0,
      hasSnapshot = false;

  final bool isAvailable;
  final int persistedEventCount;
  final bool hasSnapshot;
  final List<String> warnings;
}

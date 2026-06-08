import 'package:flutter/widgets.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

import '../../recovery/app_recovery_persistence_store_factory.dart';
import '../controllers/demo_network_confidence_presenter.dart';
import '../controllers/native_bootstrap_candidate_loader.dart';
import '../models/demo_scenario_snapshot.dart';
import '../widgets/demo_status_banner.dart';

class DemoTableRoute extends StatefulWidget {
  const DemoTableRoute({
    super.key,
    required this.snapshot,
    required this.networkConfidence,
    required this.bootstrapCandidateLoaderFactory,
    this.recoveryPersistenceStoreFactory,
    required this.onOpenChat,
    required this.onOpenReceipt,
  });

  final DemoScenarioSnapshot snapshot;
  final DemoNetworkConfidenceVm networkConfidence;
  final NativeBootstrapCandidateLoaderFactory bootstrapCandidateLoaderFactory;
  final AppRecoveryPersistenceStoreFactory? recoveryPersistenceStoreFactory;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenReceipt;

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
      return await widget.bootstrapCandidateLoaderFactory().load(
        sessionId: 'demo:${widget.snapshot.scenarioId}',
        tableId: widget.snapshot.scenarioId,
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
      final result = factory.create();
      final store = result.store;
      if (store == null) {
        return DemoRecoveryPersistenceLoadResult.unavailable(
          warnings: result.warnings,
        );
      }

      final window = store.loadWindow(
        RecoveryPersistenceScope(
          tableId: widget.snapshot.scenarioId,
          sessionId: 'demo:${widget.snapshot.scenarioId}',
          protocolVersion: '1.x',
        ),
      );
      return DemoRecoveryPersistenceLoadResult.available(
        persistedEventCount: window.events.length,
        hasSnapshot: window.snapshot != null,
        warnings: result.warnings,
      );
    } on Object {
      return const DemoRecoveryPersistenceLoadResult.unavailable(
        warnings: <String>['Recovery persistence window unavailable.'],
      );
    }
  }
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
  final VoidCallback onOpenChat;
  final VoidCallback onOpenReceipt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Demo table'),
          DemoStatusBanner(vm: snapshot.statusBanner),
          Text('Scenario: ${snapshot.scenarioId}'),
          Text('Mode: ${snapshot.mode}'),
          Text('Variant: ${snapshot.variant}'),
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
            Text('Bootstrap warning: ${bootstrap!.warnings.first}'),
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
              '${recoveryPersistence!.warnings.first}',
            ),
          Text('Receipt: ${snapshot.receipt.verificationState}'),
          _DemoRouteAction(label: 'Chat', onTap: onOpenChat),
          _DemoRouteAction(label: 'Receipt', onTap: onOpenReceipt),
        ],
      ),
    );
  }
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

class _DemoRouteAction extends StatelessWidget {
  const _DemoRouteAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

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
    required this.onOpenChat,
    required this.onOpenReceipt,
  });

  final DemoScenarioSnapshot snapshot;
  final DemoNetworkConfidenceVm networkConfidence;
  final NativeBootstrapCandidateLoaderFactory bootstrapCandidateLoaderFactory;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenReceipt;

  @override
  State<DemoTableRoute> createState() => _DemoTableRouteState();
}

class _DemoTableRouteState extends State<DemoTableRoute> {
  late Future<NativeBootstrapCandidateLoadResult> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _loadBootstrapCandidates();
  }

  @override
  void didUpdateWidget(DemoTableRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.scenarioId != widget.snapshot.scenarioId) {
      _bootstrapFuture = _loadBootstrapCandidates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NativeBootstrapCandidateLoadResult>(
      future: _bootstrapFuture,
      builder: (context, bootstrap) {
        return DemoTableScreen(
          snapshot: widget.snapshot,
          networkConfidence: widget.networkConfidence,
          bootstrap: bootstrap.data,
          bootstrapLoading: bootstrap.connectionState != ConnectionState.done,
          onOpenChat: widget.onOpenChat,
          onOpenReceipt: widget.onOpenReceipt,
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
}

class DemoTableScreen extends StatelessWidget {
  const DemoTableScreen({
    super.key,
    required this.snapshot,
    required this.networkConfidence,
    this.bootstrap,
    this.bootstrapLoading = false,
    required this.onOpenChat,
    required this.onOpenReceipt,
  });

  final DemoScenarioSnapshot snapshot;
  final DemoNetworkConfidenceVm networkConfidence;
  final NativeBootstrapCandidateLoadResult? bootstrap;
  final bool bootstrapLoading;
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
          Text('Receipt: ${snapshot.receipt.verificationState}'),
          _DemoRouteAction(label: 'Chat', onTap: onOpenChat),
          _DemoRouteAction(label: 'Receipt', onTap: onOpenReceipt),
        ],
      ),
    );
  }
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

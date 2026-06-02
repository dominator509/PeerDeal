import 'package:flutter/widgets.dart';

import '../controllers/demo_network_confidence_presenter.dart';
import '../models/demo_scenario_snapshot.dart';
import '../widgets/demo_status_banner.dart';

class DemoTableScreen extends StatelessWidget {
  const DemoTableScreen({
    super.key,
    required this.snapshot,
    required this.networkConfidence,
    required this.onOpenChat,
    required this.onOpenReceipt,
  });

  final DemoScenarioSnapshot snapshot;
  final DemoNetworkConfidenceVm networkConfidence;
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

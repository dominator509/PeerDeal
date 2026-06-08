import 'package:flutter/widgets.dart';

import '../controllers/demo_slice_controller.dart';
import '../models/demo_scenario.dart';

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({
    super.key,
    required this.controller,
    required this.onOpenTable,
    required this.onOpenChat,
    required this.onOpenReceipt,
    required this.onOpenJoin,
    required this.onOpenSetup,
    required this.onSelectScenario,
  });

  final DemoSliceController controller;
  final VoidCallback onOpenTable;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenReceipt;
  final VoidCallback onOpenJoin;
  final VoidCallback onOpenSetup;
  final ValueChanged<String> onSelectScenario;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('PeerDeal demo'),
          const SizedBox(height: 16),
          Text('Active scenario: ${controller.activeScenario.title}'),
          for (final scenario in controller.scenarios)
            _ScenarioSummary(
              scenario: scenario,
              selected: scenario.id == controller.activeScenario.id,
              onTap: () => onSelectScenario(scenario.id),
            ),
          _DemoRouteAction(label: 'Table', onTap: onOpenTable),
          _DemoRouteAction(label: 'Chat', onTap: onOpenChat),
          _DemoRouteAction(label: 'Receipt', onTap: onOpenReceipt),
          _DemoRouteAction(label: 'Join', onTap: onOpenJoin),
          _DemoRouteAction(label: 'Setup', onTap: onOpenSetup),
        ],
      ),
    );
  }
}

class _ScenarioSummary extends StatelessWidget {
  const _ScenarioSummary({
    required this.scenario,
    required this.selected,
    required this.onTap,
  });

  final DemoScenario scenario;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${selected ? 'Selected' : 'Scenario'}: ${scenario.title}'),
            Text(scenario.description),
          ],
        ),
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

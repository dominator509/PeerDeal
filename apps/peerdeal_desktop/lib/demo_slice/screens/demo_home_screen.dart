import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

import '../controllers/demo_slice_controller.dart';
import '../models/demo_scenario.dart';

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({
    super.key,
    required this.controller,
    required this.navigationActions,
    required this.onSelectScenario,
  });

  final DemoSliceController controller;
  final List<DemoHomeNavigationAction> navigationActions;
  final ValueChanged<String> onSelectScenario;

  @override
  Widget build(BuildContext context) {
    return PeerDealAppScaffold(
      title: 'PeerDeal demo',
      subtitle: 'Fixture-backed app orchestration',
      actions: navigationActions
          .map(
            (action) => PeerDealActionButton(
              label: action.label,
              onPressed: action.onPressed,
            ),
          )
          .toList(growable: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Active scenario: ${controller.activeScenario.title}'),
          const SizedBox(height: 12),
          for (final scenario in controller.scenarios)
            _ScenarioSummary(
              scenario: scenario,
              selected: scenario.id == controller.activeScenario.id,
              onTap: () => onSelectScenario(scenario.id),
            ),
        ],
      ),
    );
  }
}

class DemoHomeNavigationAction {
  const DemoHomeNavigationAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
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

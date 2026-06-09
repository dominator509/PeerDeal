import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

import '../../native_readiness/app_native_readiness_loader.dart';
import '../controllers/demo_slice_controller.dart';
import '../models/demo_scenario.dart';

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({
    super.key,
    required this.controller,
    required this.demoNavigationActions,
    required this.productionNavigationActions,
    required this.onSelectScenario,
    this.nativeReadiness,
  });

  final DemoSliceController controller;
  final List<DemoHomeNavigationAction> demoNavigationActions;
  final List<DemoHomeNavigationAction> productionNavigationActions;
  final ValueChanged<String> onSelectScenario;
  final AppNativeReadinessSnapshot? nativeReadiness;

  @override
  Widget build(BuildContext context) {
    return PeerDealAppScaffold(
      title: 'PeerDeal demo',
      subtitle: 'Fixture-backed app orchestration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (nativeReadiness != null) ...<Widget>[
            PeerDealStatusPill(
              label: nativeReadiness!.allCapabilitiesReady
                  ? 'Native ready'
                  : 'Native unavailable',
              severity: nativeReadiness!.allCapabilitiesReady
                  ? 'success'
                  : 'warning',
            ),
            for (final warning in nativeReadiness!.warnings)
              PeerDealInfoRow(label: 'Native', value: warning),
            const SizedBox(height: 12),
          ],
          if (productionNavigationActions.isNotEmpty) ...<Widget>[
            _NavigationSection(
              title: 'Production',
              actions: productionNavigationActions,
            ),
            const SizedBox(height: 12),
          ],
          if (demoNavigationActions.isNotEmpty) ...<Widget>[
            _NavigationSection(title: 'Demo', actions: demoNavigationActions),
            const SizedBox(height: 12),
          ],
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

class _NavigationSection extends StatelessWidget {
  const _NavigationSection({required this.title, required this.actions});

  final String title;
  final List<DemoHomeNavigationAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map(
                (action) => PeerDealActionButton(
                  label: action.label,
                  onPressed: action.onPressed,
                ),
              )
              .toList(growable: false),
        ),
      ],
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

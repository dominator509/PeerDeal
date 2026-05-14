import '../models/demo_scenario.dart';
import '../scenarios/demo_scenario_catalog.dart';

class DemoSliceController {
  DemoScenario _active = DemoScenarioCatalog.scenarios.first;

  DemoScenario get activeScenario => _active;

  List<DemoScenario> get scenarios => DemoScenarioCatalog.scenarios;

  void selectScenario(String scenarioId) {
    _active = scenarios.firstWhere((s) => s.id == scenarioId);
  }

  bool trySelectScenario(String scenarioId) {
    for (final scenario in scenarios) {
      if (scenario.id == scenarioId) {
        _active = scenario;
        return true;
      }
    }

    return false;
  }
}

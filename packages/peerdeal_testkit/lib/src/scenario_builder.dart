class ScenarioBuilder {
  const ScenarioBuilder();

  List<String> orderedSteps(String name, List<String> steps) {
    return ['scenario:$name', ...steps];
  }
}

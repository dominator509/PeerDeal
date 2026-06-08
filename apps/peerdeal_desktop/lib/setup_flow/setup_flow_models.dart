enum SetupFlowStatus { compiled, rejected }

class SetupFlowOutcome {
  const SetupFlowOutcome({
    required this.status,
    required this.resultCode,
    this.gameFile,
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  final SetupFlowStatus status;
  final String resultCode;
  final Map<String, Object?>? gameFile;
  final List<String> errors;
  final List<String> warnings;
}

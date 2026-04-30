import 'package:meta/meta.dart';

@immutable
class ReconciliationResult {
  const ReconciliationResult({
    required this.canResume,
    required this.requiresRecovery,
    required this.recommendedAction,
    this.notes = const <String>[],
  });

  final bool canResume;
  final bool requiresRecovery;
  final String recommendedAction;
  final List<String> notes;
}

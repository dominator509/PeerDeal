import 'package:meta/meta.dart';

@immutable
class ReconciliationResult {
  ReconciliationResult({
    required this.canResume,
    required this.requiresRecovery,
    required this.recommendedAction,
    List<String> notes = const <String>[],
  }) : notes = List<String>.unmodifiable(notes);

  final bool canResume;
  final bool requiresRecovery;
  final String recommendedAction;
  final List<String> notes;
}

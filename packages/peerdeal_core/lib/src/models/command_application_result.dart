import 'package:meta/meta.dart';

import 'core_event.dart';
import 'invariant_violation.dart';
import 'table_state.dart';

@immutable
class CommandApplicationResult {
  const CommandApplicationResult({
    required this.state,
    required this.emittedEvents,
    required this.violations,
  });

  final TableState state;
  final List<CoreEvent> emittedEvents;
  final List<InvariantViolation> violations;

  bool get isSuccess => violations.isEmpty;
}

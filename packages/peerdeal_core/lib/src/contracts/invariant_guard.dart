import '../models/invariant_violation.dart';
import '../models/table_state.dart';

abstract interface class InvariantGuard {
  Iterable<InvariantViolation> evaluate(TableState state);
}

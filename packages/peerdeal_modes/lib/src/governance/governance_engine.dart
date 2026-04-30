import 'governance_action.dart';
import 'governance_context.dart';
import 'governance_decision.dart';

abstract interface class GovernanceEngine {
  GovernanceDecision evaluate({
    required GovernanceContext context,
    required GovernanceAction action,
  });
}

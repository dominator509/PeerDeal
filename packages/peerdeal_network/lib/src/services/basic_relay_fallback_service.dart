import '../contracts/relay_fallback_service.dart';
import '../models/direct_relay_transition_plan.dart';
import '../models/session_path_descriptor.dart';

class BasicRelayFallbackService implements RelayFallbackService {
  const BasicRelayFallbackService();

  @override
  DirectRelayTransitionPlan planTransition({
    required SessionPathDescriptor currentPath,
    required SessionPathDescriptor fallbackPath,
    required bool liveHandInProgress,
  }) {
    final transitionNeeded = currentPath.routeClass != fallbackPath.routeClass;

    return DirectRelayTransitionPlan(
      transitionNeeded: transitionNeeded,
      pauseRecommended: transitionNeeded && liveHandInProgress,
      fromLabel: currentPath.routeClass.name,
      toLabel: fallbackPath.routeClass.name,
      reason: transitionNeeded
          ? 'route_class_changed'
          : 'route_class_unchanged',
    );
  }
}

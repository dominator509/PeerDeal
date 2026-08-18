import '../contracts/relay_fallback_service.dart';
import '../models/direct_relay_transition_plan.dart';
import '../models/network_input_limits.dart';
import '../models/session_path_descriptor.dart';

class BasicRelayFallbackService implements RelayFallbackService {
  const BasicRelayFallbackService();

  @override
  DirectRelayTransitionPlan planTransition({
    required SessionPathDescriptor currentPath,
    required SessionPathDescriptor fallbackPath,
    required bool liveHandInProgress,
  }) {
    if (!_isOperationalPeerId(currentPath.primaryPeerId) ||
        !_isOperationalPeerId(fallbackPath.primaryPeerId)) {
      return DirectRelayTransitionPlan(
        transitionNeeded: false,
        pauseRecommended: false,
        fromLabel: currentPath.routeClass.name,
        toLabel: fallbackPath.routeClass.name,
        reason: 'invalid_peer_identity',
      );
    }

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

  bool _isOperationalPeerId(String peerId) {
    if (!NetworkInputLimits.isSafePeerIdentity(peerId)) return false;
    if (peerId == 'none' || peerId == 'unresolved') return false;
    if (peerId.contains('::')) return false;
    return true;
  }
}

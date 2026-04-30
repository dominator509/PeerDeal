import '../models/direct_relay_transition_plan.dart';
import '../models/session_path_descriptor.dart';

abstract interface class RelayFallbackService {
  DirectRelayTransitionPlan planTransition({
    required SessionPathDescriptor currentPath,
    required SessionPathDescriptor fallbackPath,
    required bool liveHandInProgress,
  });
}

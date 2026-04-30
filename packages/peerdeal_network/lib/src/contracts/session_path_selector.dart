import '../models/bootstrap_candidate.dart';
import '../models/session_path_descriptor.dart';

abstract interface class SessionPathSelector {
  SessionPathDescriptor selectPath({
    required List<BootstrapCandidate> candidates,
    required bool preferLan,
    required bool relayAllowed,
    String? electedPrimaryPeerId,
  });
}

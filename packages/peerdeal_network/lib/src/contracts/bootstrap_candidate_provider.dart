import '../models/bootstrap_candidate.dart';
import '../models/bootstrap_resolution_request.dart';

abstract interface class BootstrapCandidateProvider {
  Future<List<BootstrapCandidate>> resolveCandidates(
    BootstrapResolutionRequest request,
  );
}

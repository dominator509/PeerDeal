import '../contracts/bootstrap_candidate_provider.dart';
import '../models/bootstrap_candidate.dart';
import '../models/bootstrap_resolution_request.dart';
import '../models/network_route_class.dart';

class BasicBootstrapCandidateProvider implements BootstrapCandidateProvider {
  const BasicBootstrapCandidateProvider();

  @override
  Future<List<BootstrapCandidate>> resolveCandidates(
    BootstrapResolutionRequest request,
  ) async {
    return request.peerIds.asMap().entries.map((entry) {
      final index = entry.key;
      final peerId = entry.value;
      return BootstrapCandidate(
        peerId: peerId,
        routeClass: request.preferLan && index == 0
            ? NetworkRouteClass.lanDirect
            : NetworkRouteClass.p2pRemote,
        reachable: true,
        priority: request.peerIds.length - index,
        reason: request.preferLan && index == 0
            ? 'preferred_lan_candidate'
            : 'fallback_remote_candidate',
      );
    }).toList(growable: false);
  }
}

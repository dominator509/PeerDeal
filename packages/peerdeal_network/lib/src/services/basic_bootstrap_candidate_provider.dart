import '../contracts/bootstrap_candidate_provider.dart';
import '../models/bootstrap_candidate.dart';
import '../models/bootstrap_resolution_request.dart';
import '../models/network_input_limits.dart';
import '../models/network_route_class.dart';

class BasicBootstrapCandidateProvider implements BootstrapCandidateProvider {
  const BasicBootstrapCandidateProvider({
    this.maxPeerIds = NetworkInputLimits.defaultMaxPeerIds,
  }) : assert(maxPeerIds > 0, 'maxPeerIds must be positive');

  final int maxPeerIds;

  @override
  Future<List<BootstrapCandidate>> resolveCandidates(
    BootstrapResolutionRequest request,
  ) async {
    if (request.peerIds.length > maxPeerIds) {
      return const <BootstrapCandidate>[];
    }
    final peerIds = _validatedPeerIds(request.peerIds);
    return peerIds
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final peerId = entry.value;
          return BootstrapCandidate(
            peerId: peerId,
            routeClass: request.preferLan && index == 0
                ? NetworkRouteClass.lanDirect
                : NetworkRouteClass.p2pRemote,
            reachable: true,
            priority: peerIds.length - index,
            reason: request.preferLan && index == 0
                ? 'preferred_lan_candidate'
                : 'fallback_remote_candidate',
          );
        })
        .toList(growable: false);
  }

  List<String> _validatedPeerIds(List<String> peerIds) {
    final seen = <String>{};
    final result = <String>[];
    for (final peerId in peerIds) {
      if (!_isValidPeerId(peerId) || !seen.add(peerId)) continue;
      result.add(peerId);
    }
    return result;
  }

  bool _isValidPeerId(String peerId) {
    if (peerId.isEmpty || peerId.trim() != peerId) return false;
    return peerId.runes.every((rune) => rune > 0x1f && rune != 0x7f);
  }
}

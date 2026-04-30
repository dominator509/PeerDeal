import '../contracts/session_path_selector.dart';
import '../models/bootstrap_candidate.dart';
import '../models/network_route_class.dart';
import '../models/session_path_descriptor.dart';

class BasicSessionPathSelector implements SessionPathSelector {
  const BasicSessionPathSelector();

  @override
  SessionPathDescriptor selectPath({
    required List<BootstrapCandidate> candidates,
    required bool preferLan,
    required bool relayAllowed,
    String? electedPrimaryPeerId,
  }) {
    final reachable = candidates.where((c) => c.reachable).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final lanCandidate = reachable.where((c) => c.routeClass == NetworkRouteClass.lanDirect).cast<BootstrapCandidate?>().firstWhere(
      (c) => c != null,
      orElse: () => null,
    );

    if (preferLan && lanCandidate != null) {
      return SessionPathDescriptor(
        routeClass: NetworkRouteClass.lanDirect,
        primaryPeerId: electedPrimaryPeerId ?? lanCandidate.peerId,
        usesRelay: false,
        transportAgnostic: true,
        reason: 'selected_lan_direct_path',
      );
    }

    final remoteCandidate = reachable.where((c) => c.routeClass == NetworkRouteClass.p2pRemote).cast<BootstrapCandidate?>().firstWhere(
      (c) => c != null,
      orElse: () => null,
    );

    if (remoteCandidate != null) {
      return SessionPathDescriptor(
        routeClass: NetworkRouteClass.p2pRemote,
        primaryPeerId: electedPrimaryPeerId ?? remoteCandidate.peerId,
        usesRelay: false,
        transportAgnostic: true,
        reason: 'selected_remote_p2p_path',
      );
    }

    if (relayAllowed && reachable.isNotEmpty) {
      return SessionPathDescriptor(
        routeClass: NetworkRouteClass.relay,
        primaryPeerId: electedPrimaryPeerId ?? reachable.first.peerId,
        usesRelay: true,
        transportAgnostic: true,
        reason: 'selected_relay_fallback_path',
      );
    }

    return SessionPathDescriptor(
      routeClass: NetworkRouteClass.relay,
      primaryPeerId: electedPrimaryPeerId ?? 'unresolved',
      usesRelay: relayAllowed,
      transportAgnostic: true,
      reason: 'no_direct_candidate_available',
    );
  }
}

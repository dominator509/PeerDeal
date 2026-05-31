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
      ..sort(_compareCandidates);

    final lanCandidate = _firstWhere(
      reachable,
      (candidate) => candidate.routeClass.isLanDirect,
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

    final remoteCandidate = _firstWhere(
      reachable,
      (candidate) => candidate.routeClass.isRemoteDirect,
    );

    if (remoteCandidate != null) {
      return SessionPathDescriptor(
        routeClass: remoteCandidate.routeClass,
        primaryPeerId: electedPrimaryPeerId ?? remoteCandidate.peerId,
        usesRelay: false,
        transportAgnostic: true,
        reason: 'selected_remote_p2p_path',
      );
    }

    if (lanCandidate != null) {
      return SessionPathDescriptor(
        routeClass: NetworkRouteClass.lanDirect,
        primaryPeerId: electedPrimaryPeerId ?? lanCandidate.peerId,
        usesRelay: false,
        transportAgnostic: true,
        reason: 'selected_lan_direct_path',
      );
    }

    final relayCandidate = _firstWhere(
      reachable,
      (candidate) => candidate.routeClass.isRelay,
    );

    if (relayAllowed && relayCandidate != null) {
      return SessionPathDescriptor(
        routeClass: relayCandidate.routeClass,
        primaryPeerId: electedPrimaryPeerId ?? relayCandidate.peerId,
        usesRelay: true,
        transportAgnostic: true,
        reason: 'selected_relay_fallback_path',
      );
    }

    return SessionPathDescriptor(
      routeClass: NetworkRouteClass.relay,
      primaryPeerId: electedPrimaryPeerId ?? 'unresolved',
      usesRelay: false,
      transportAgnostic: true,
      reason: 'no_direct_candidate_available',
    );
  }

  static int _compareCandidates(BootstrapCandidate a, BootstrapCandidate b) {
    final priorityCmp = b.priority.compareTo(a.priority);
    if (priorityCmp != 0) return priorityCmp;

    final routeCmp = a.routeClass.selectionRank.compareTo(
      b.routeClass.selectionRank,
    );
    if (routeCmp != 0) return routeCmp;

    return a.peerId.compareTo(b.peerId);
  }

  static BootstrapCandidate? _firstWhere(
    List<BootstrapCandidate> candidates,
    bool Function(BootstrapCandidate candidate) test,
  ) {
    for (final candidate in candidates) {
      if (test(candidate)) return candidate;
    }
    return null;
  }
}

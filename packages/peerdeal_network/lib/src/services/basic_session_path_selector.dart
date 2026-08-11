import '../contracts/session_path_selector.dart';
import '../models/bootstrap_candidate.dart';
import '../models/network_input_limits.dart';
import '../models/network_route_class.dart';
import '../models/session_path_descriptor.dart';

class BasicSessionPathSelector implements SessionPathSelector {
  const BasicSessionPathSelector({
    this.maxCandidates = NetworkInputLimits.defaultMaxCandidates,
  }) : assert(maxCandidates > 0, 'maxCandidates must be positive');

  final int maxCandidates;

  @override
  SessionPathDescriptor selectPath({
    required List<BootstrapCandidate> candidates,
    required bool preferLan,
    required bool relayAllowed,
    String? electedPrimaryPeerId,
  }) {
    final primaryPeerId = _validPeerIdOrNull(electedPrimaryPeerId);
    if (candidates.length > maxCandidates) {
      return SessionPathDescriptor(
        routeClass: NetworkRouteClass.relay,
        primaryPeerId: primaryPeerId ?? 'unresolved',
        usesRelay: false,
        transportAgnostic: true,
        reason: 'candidate_window_too_large',
      );
    }
    final reachable =
        candidates
            .where((c) => c.reachable && _isValidPeerId(c.peerId))
            .toList()
          ..sort(_compareCandidates);

    final lanCandidate = _firstWhere(
      reachable,
      (candidate) => candidate.routeClass.isLanDirect,
    );

    if (preferLan && lanCandidate != null) {
      return SessionPathDescriptor(
        routeClass: NetworkRouteClass.lanDirect,
        primaryPeerId: primaryPeerId ?? lanCandidate.peerId,
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
        primaryPeerId: primaryPeerId ?? remoteCandidate.peerId,
        usesRelay: false,
        transportAgnostic: true,
        reason: 'selected_remote_p2p_path',
      );
    }

    if (lanCandidate != null) {
      return SessionPathDescriptor(
        routeClass: NetworkRouteClass.lanDirect,
        primaryPeerId: primaryPeerId ?? lanCandidate.peerId,
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
        primaryPeerId: primaryPeerId ?? relayCandidate.peerId,
        usesRelay: true,
        transportAgnostic: true,
        reason: 'selected_relay_fallback_path',
      );
    }

    return SessionPathDescriptor(
      routeClass: NetworkRouteClass.relay,
      primaryPeerId: primaryPeerId ?? 'unresolved',
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

  static String? _validPeerIdOrNull(String? peerId) {
    if (peerId == null || !_isValidPeerId(peerId)) return null;
    return peerId;
  }

  static bool _isValidPeerId(String peerId) {
    if (peerId.isEmpty || peerId.trim() != peerId) return false;
    return peerId.runes.every((rune) => rune > 0x1f && rune != 0x7f);
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

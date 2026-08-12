import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

import 'join_flow_adapters.dart';
import 'join_flow_models.dart';

class NativeJoinBootstrapCoordinator
    implements BootstrapCoordinator, CancellableBootstrapCoordinator {
  const NativeJoinBootstrapCoordinator({
    required LocalNetworkBridge bridge,
    BootstrapCandidateProvider provider =
        const BasicBootstrapCandidateProvider(),
    int maxPeerCandidates = 32,
  }) : _bridge = bridge,
       _provider = provider,
       _maxPeerCandidates = maxPeerCandidates;

  factory NativeJoinBootstrapCoordinator.methodChannel() {
    return NativeJoinBootstrapCoordinator(
      bridge: MethodChannelLocalNetworkBridge(),
    );
  }

  final LocalNetworkBridge _bridge;
  final BootstrapCandidateProvider _provider;
  final int _maxPeerCandidates;

  @override
  Future<BootstrapPlan> buildPlan({
    required ResolvedInvite resolvedInvite,
    required RoleGrant roleGrant,
    Future<void>? cancellation,
  }) async {
    if (!_isValidScope(resolvedInvite.sessionId) ||
        !_isValidScope(resolvedInvite.tableId)) {
      return BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    if (_maxPeerCandidates < 1) {
      return BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    final capability = await _safeCapability(cancellation: cancellation);
    if (!capability.discoverySupported) {
      return BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    final discovery = await _safeDiscovery(cancellation: cancellation);
    if (!discovery.permissionGranted) {
      return BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    final endpoints = DiscoveredPeerEndpointParser.parseAll(
      discovery.foundEndpoints,
      maxValues: _maxPeerCandidates,
    );
    final peerIds = endpoints
        .map((endpoint) => endpoint.peerId)
        .toList(growable: false);
    if (peerIds.isEmpty) {
      return BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    final List<BootstrapCandidate> candidates;
    try {
      candidates = await _provider.resolveCandidates(
        BootstrapResolutionRequest(
          sessionId: resolvedInvite.sessionId,
          tableId: resolvedInvite.tableId,
          preferLan: true,
          relayAllowed: true,
          peerIds: peerIds,
        ),
      );
    } on Object {
      return BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    final projectedCandidates = DiscoveredPeerEndpointParser.projectCandidates(
      candidates,
      endpoints,
    );
    final reachableCandidates = <BootstrapCandidate>[];
    final seenPeerIds = <String>{};
    for (final candidate in projectedCandidates) {
      if (!candidate.reachable) continue;
      if (reachableCandidates.length == _maxPeerCandidates) break;
      final peerId = _safeNativeText(candidate.peerId);
      if (peerId.isEmpty || !seenPeerIds.add(peerId)) continue;
      reachableCandidates.add(
        peerId == candidate.peerId
            ? candidate
            : BootstrapCandidate(
                peerId: peerId,
                routeClass: candidate.routeClass,
                reachable: candidate.reachable,
                priority: candidate.priority,
                host: candidate.host,
                port: candidate.port,
                reason: candidate.reason,
              ),
      );
    }
    final reachablePeerIds = reachableCandidates
        .map((candidate) => candidate.peerId)
        .toList(growable: false);
    return BootstrapPlan(
      requiresBootstrap: true,
      peerCandidates: reachablePeerIds,
      relayFallbackAllowed: true,
      selectedPeerId: reachablePeerIds.isEmpty ? null : reachablePeerIds.first,
      selectedCandidate: reachableCandidates.isEmpty
          ? null
          : reachableCandidates.first,
    );
  }

  Future<LocalNetworkCapability> _safeCapability({
    Future<void>? cancellation,
  }) async {
    try {
      final cancellableBridge = _bridge;
      if (cancellableBridge is CancellableLocalNetworkBridge) {
        final bridge = cancellableBridge as CancellableLocalNetworkBridge;
        return await bridge.getCapability(cancellation: cancellation);
      }
      return await _bridge.getCapability();
    } on Object {
      return const LocalNetworkCapability.unavailable(
        warning: 'Local network capability could not be loaded.',
      );
    }
  }

  Future<LocalNetworkDiscoverySnapshot> _safeDiscovery({
    Future<void>? cancellation,
  }) async {
    try {
      final cancellableBridge = _bridge;
      if (cancellableBridge is CancellableLocalNetworkBridge) {
        final bridge = cancellableBridge as CancellableLocalNetworkBridge;
        return await bridge.discoverPeers(cancellation: cancellation);
      }
      return await _bridge.discoverPeers();
    } on Object {
      return const LocalNetworkDiscoverySnapshot.unavailable(
        warning: 'Local network discovery could not be loaded.',
      );
    }
  }

  static bool _isValidScope(String value) {
    return NativeBridgePayloadLimits.isSafeUtf8Text(
      value,
      NativeBridgePayloadLimits.maxTransportIdentityBytes,
    );
  }

  static String _safeNativeText(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (_looksSensitive(normalized)) {
      return '';
    }
    const maxLength = 96;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  static bool _looksSensitive(String value) {
    final lower = value.toLowerCase();
    return lower.contains('secret') ||
        lower.contains('token') ||
        lower.contains('password') ||
        value.contains('\\');
  }
}

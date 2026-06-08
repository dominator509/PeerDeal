import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

import 'join_flow_adapters.dart';
import 'join_flow_models.dart';

class NativeJoinBootstrapCoordinator implements BootstrapCoordinator {
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
  }) async {
    if (_maxPeerCandidates < 1) {
      return const BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    final capability = await _safeCapability();
    if (!capability.discoverySupported) {
      return const BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    final discovery = await _safeDiscovery();
    if (!discovery.permissionGranted) {
      return const BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    final peerIds = _normalizedUnique(
      discovery.foundEndpoints,
    ).take(_maxPeerCandidates).toList();
    if (peerIds.isEmpty) {
      return const BootstrapPlan(
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
      return const BootstrapPlan(
        requiresBootstrap: true,
        peerCandidates: <String>[],
        relayFallbackAllowed: true,
      );
    }

    return BootstrapPlan(
      requiresBootstrap: true,
      peerCandidates: candidates
          .where((candidate) => candidate.reachable)
          .map((candidate) => candidate.peerId)
          .toList(growable: false),
      relayFallbackAllowed: true,
    );
  }

  Future<LocalNetworkCapability> _safeCapability() async {
    try {
      return await _bridge.getCapability();
    } on Object {
      return const LocalNetworkCapability.unavailable(
        warning: 'Local network capability could not be loaded.',
      );
    }
  }

  Future<LocalNetworkDiscoverySnapshot> _safeDiscovery() async {
    try {
      return await _bridge.discoverPeers();
    } on Object {
      return const LocalNetworkDiscoverySnapshot.unavailable(
        warning: 'Local network discovery could not be loaded.',
      );
    }
  }

  static List<String> _normalizedUnique(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = _safeNativeText(value);
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }

  static String _safeNativeText(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return '';
    }
    const maxLength = 96;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }
}

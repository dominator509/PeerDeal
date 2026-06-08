import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

typedef NativeBootstrapCandidateLoaderFactory =
    NativeBootstrapCandidateLoader Function();

class NativeBootstrapCandidateLoadResult {
  const NativeBootstrapCandidateLoadResult({
    required this.discoveryAvailable,
    required this.nativeNotes,
    required this.candidates,
    required this.warnings,
  });

  const NativeBootstrapCandidateLoadResult.unavailable({
    required this.nativeNotes,
    this.warnings = const <String>[],
  }) : discoveryAvailable = false,
       candidates = const <BootstrapCandidate>[];

  final bool discoveryAvailable;
  final String nativeNotes;
  final List<BootstrapCandidate> candidates;
  final List<String> warnings;

  bool get hasCandidates => candidates.isNotEmpty;
}

class NativeBootstrapCandidateLoader {
  const NativeBootstrapCandidateLoader({
    required LocalNetworkBridge bridge,
    BootstrapCandidateProvider provider =
        const BasicBootstrapCandidateProvider(),
    int maxPeerCandidates = 32,
  }) : _bridge = bridge,
       _provider = provider,
       _maxPeerCandidates = maxPeerCandidates;

  factory NativeBootstrapCandidateLoader.methodChannel() {
    return NativeBootstrapCandidateLoader(
      bridge: MethodChannelLocalNetworkBridge(),
    );
  }

  final LocalNetworkBridge _bridge;
  final BootstrapCandidateProvider _provider;
  final int _maxPeerCandidates;

  Future<NativeBootstrapCandidateLoadResult> load({
    required String sessionId,
    required String tableId,
  }) async {
    final LocalNetworkCapability capability;
    try {
      capability = await _bridge.getCapability();
    } catch (_) {
      return const NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: 'unavailable',
        warnings: <String>['Local network capability could not be loaded.'],
      );
    }

    final warnings = <String>[
      if (_hasText(capability.warning)) capability.warning!,
    ];

    if (!capability.discoverySupported) {
      return NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: capability.notes,
        warnings: warnings,
      );
    }

    final LocalNetworkDiscoverySnapshot discovery;
    try {
      discovery = await _bridge.discoverPeers();
    } catch (_) {
      return NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: capability.notes,
        warnings: <String>[
          ...warnings,
          'Local network discovery could not be loaded.',
        ],
      );
    }

    final discoveryWarnings = <String>[
      ...warnings,
      if (_hasText(discovery.warning)) discovery.warning!,
    ];
    if (_maxPeerCandidates < 1) {
      return NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: _nativeNotes(capability, discovery),
        warnings: <String>[
          ...discoveryWarnings,
          'Local network peer candidate limit is invalid.',
        ],
      );
    }
    if (!discovery.permissionGranted) {
      return NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: _nativeNotes(capability, discovery),
        warnings: discoveryWarnings,
      );
    }

    final normalizedPeerIds = _normalizedUnique(discovery.foundEndpoints);
    final peerIds = normalizedPeerIds.take(_maxPeerCandidates).toList();
    final peerWarnings = <String>[
      ...discoveryWarnings,
      if (normalizedPeerIds.length > peerIds.length)
        'Local network discovery peer candidate limit reached.',
    ];
    if (peerIds.isEmpty) {
      return NativeBootstrapCandidateLoadResult(
        discoveryAvailable: true,
        nativeNotes: _nativeNotes(capability, discovery),
        candidates: const <BootstrapCandidate>[],
        warnings: peerWarnings,
      );
    }

    try {
      final candidates = await _provider.resolveCandidates(
        BootstrapResolutionRequest(
          sessionId: sessionId,
          tableId: tableId,
          preferLan: true,
          relayAllowed: true,
          peerIds: peerIds,
        ),
      );
      return NativeBootstrapCandidateLoadResult(
        discoveryAvailable: true,
        nativeNotes: _nativeNotes(capability, discovery),
        candidates: candidates,
        warnings: peerWarnings,
      );
    } catch (_) {
      return NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: _nativeNotes(capability, discovery),
        warnings: <String>[
          ...peerWarnings,
          'Local network bootstrap candidates could not be resolved.',
        ],
      );
    }
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _nativeNotes(
    LocalNetworkCapability capability,
    LocalNetworkDiscoverySnapshot discovery,
  ) {
    final hints = _normalizedUnique(discovery.interfaceHints);
    if (hints.isEmpty) {
      return capability.notes;
    }
    return '${capability.notes}; interfaces=${hints.join(",")}';
  }

  static List<String> _normalizedUnique(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }
}

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
    if (!_isValidScope(sessionId) || !_isValidScope(tableId)) {
      return const NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: 'unavailable',
        warnings: <String>['Local network bootstrap scope is invalid.'],
      );
    }

    if (_maxPeerCandidates < 1) {
      return const NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: 'unavailable',
        warnings: <String>['Local network peer candidate limit is invalid.'],
      );
    }

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
      if (_hasText(capability.warning))
        'Local network reported a platform warning.',
    ];

    if (!capability.discoverySupported) {
      return NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: _safeNativeText(capability.notes),
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
      if (_hasText(discovery.warning))
        'Local network reported a platform warning.',
    ];
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

  static bool _isValidScope(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed == value;
  }

  static String _nativeNotes(
    LocalNetworkCapability capability,
    LocalNetworkDiscoverySnapshot discovery,
  ) {
    final hints = _normalizedUnique(discovery.interfaceHints);
    final notes = hints.isEmpty
        ? capability.notes
        : '${capability.notes}; interfaces=${hints.join(",")}';
    return _safeNativeText(notes);
  }

  static String _safeNativeText(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return 'unavailable';
    }
    const maxLength = 96;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  static List<String> _normalizedUnique(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = _safePeerId(value);
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }

  static String _safePeerId(String value) {
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

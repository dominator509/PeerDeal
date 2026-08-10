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
        nativeNotes: _safeNativeText(capability.notes),
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

    final normalizedPeerEndpoints = _normalizedPeerEndpoints(
      discovery.foundEndpoints,
    );
    final peerEndpoints = normalizedPeerEndpoints
        .take(_maxPeerCandidates)
        .toList(growable: false);
    final peerIds = peerEndpoints
        .map((endpoint) => endpoint.peerId)
        .toList(growable: false);
    final peerWarnings = <String>[
      ...discoveryWarnings,
      if (normalizedPeerEndpoints.length > peerIds.length)
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
        candidates: _projectEndpointMetadata(candidates, peerEndpoints),
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
    if (_looksSensitive(normalized)) {
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

  static List<_NativePeerEndpoint> _normalizedPeerEndpoints(
    List<String> values,
  ) {
    final seen = <String>{};
    final result = <_NativePeerEndpoint>[];
    for (final value in values) {
      final endpoint = _parsePeerEndpoint(value);
      if (endpoint == null || !seen.add(endpoint.peerId)) continue;
      result.add(endpoint);
    }
    return result;
  }

  static _NativePeerEndpoint? _parsePeerEndpoint(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty || _looksSensitive(normalized)) return null;

    final separator = normalized.indexOf('@');
    if (separator < 0) {
      final peerId = _safePeerId(normalized);
      return peerId.isEmpty ? null : _NativePeerEndpoint(peerId: peerId);
    }
    if (separator == 0 || separator == normalized.length - 1) return null;

    final peerId = _safePeerId(normalized.substring(0, separator));
    final hostPort = _parseHostPort(normalized.substring(separator + 1));
    if (peerId.isEmpty || hostPort == null) return null;
    return _NativePeerEndpoint(
      peerId: peerId,
      host: hostPort.host,
      port: hostPort.port,
    );
  }

  static _NativeHostPort? _parseHostPort(String value) {
    final location = value.trim();
    if (location.isEmpty || location.length > 253) return null;

    String host;
    int? port;
    if (location.startsWith('[')) {
      final closingBracket = location.indexOf(']');
      if (closingBracket <= 1) return null;
      host = location.substring(1, closingBracket);
      final suffix = location.substring(closingBracket + 1);
      if (suffix.isNotEmpty) {
        if (!suffix.startsWith(':')) return null;
        port = _parsePort(suffix.substring(1));
        if (port == null) return null;
      }
    } else {
      final colonCount = ':'.allMatches(location).length;
      if (colonCount == 1) {
        final separator = location.lastIndexOf(':');
        host = location.substring(0, separator);
        port = _parsePort(location.substring(separator + 1));
        if (port == null) return null;
      } else {
        host = location;
      }
    }

    if (!_isSafeHost(host)) return null;
    return _NativeHostPort(host: host, port: port);
  }

  static int? _parsePort(String value) {
    final port = int.tryParse(value);
    return port != null && port > 0 && port <= 65535 ? port : null;
  }

  static bool _isSafeHost(String host) {
    if (host.isEmpty || host.length > 253 || _looksSensitive(host)) {
      return false;
    }
    if (host.contains(':')) {
      return RegExp(r'^[0-9A-Fa-f:]+$').hasMatch(host);
    }
    return RegExp(r'^[A-Za-z0-9.-]+$').hasMatch(host) &&
        !host.startsWith('.') &&
        !host.endsWith('.') &&
        !host.startsWith('-') &&
        !host.endsWith('-');
  }

  static List<BootstrapCandidate> _projectEndpointMetadata(
    List<BootstrapCandidate> candidates,
    List<_NativePeerEndpoint> endpoints,
  ) {
    final byPeerId = <String, _NativePeerEndpoint>{
      for (final endpoint in endpoints) endpoint.peerId: endpoint,
    };
    return candidates
        .map((candidate) {
          final endpoint = byPeerId[candidate.peerId];
          if (endpoint == null || endpoint.host == null) return candidate;
          return BootstrapCandidate(
            peerId: candidate.peerId,
            routeClass: candidate.routeClass,
            reachable: candidate.reachable,
            priority: candidate.priority,
            host: candidate.host ?? endpoint.host,
            port: candidate.port ?? endpoint.port,
            reason: candidate.reason,
          );
        })
        .toList(growable: false);
  }

  static String _safePeerId(String value) {
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

class _NativePeerEndpoint {
  const _NativePeerEndpoint({required this.peerId, this.host, this.port});

  final String peerId;
  final String? host;
  final int? port;
}

class _NativeHostPort {
  const _NativeHostPort({required this.host, this.port});

  final String host;
  final int? port;
}

import 'dart:async';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

typedef NativeBootstrapCandidateLoaderFactory =
    NativeBootstrapCandidateLoader Function();

class NativeBootstrapCandidateLoadResult {
  static const maxCandidateCount = 32;
  static const maxWarningCount = 8;

  NativeBootstrapCandidateLoadResult({
    required this.discoveryAvailable,
    required this.nativeNotes,
    required List<BootstrapCandidate> candidates,
    required List<String> warnings,
  }) : candidates = _boundedCandidates(candidates),
       warnings = _boundedWarnings(
         warnings,
         candidatesTruncated: candidates.length > maxCandidateCount,
       );

  NativeBootstrapCandidateLoadResult.unavailable({
    required this.nativeNotes,
    List<String> warnings = const <String>[],
  }) : discoveryAvailable = false,
       candidates = const <BootstrapCandidate>[],
       warnings = _boundedWarnings(warnings);

  final bool discoveryAvailable;
  final String nativeNotes;
  final List<BootstrapCandidate> candidates;
  final List<String> warnings;

  bool get hasCandidates => candidates.isNotEmpty;

  static List<BootstrapCandidate> _boundedCandidates(
    List<BootstrapCandidate> candidates,
  ) =>
      List<BootstrapCandidate>.unmodifiable(candidates.take(maxCandidateCount));

  static List<String> _boundedWarnings(
    List<String> warnings, {
    bool candidatesTruncated = false,
  }) {
    final warningsTruncated = warnings.length > maxWarningCount;
    final markerCount =
        (candidatesTruncated ? 1 : 0) + (warningsTruncated ? 1 : 0);
    final result = warnings
        .take(maxWarningCount - markerCount)
        .toList(growable: true);
    if (candidatesTruncated) {
      result.insert(0, 'Bootstrap candidates truncated.');
    }
    if (warningsTruncated) {
      result.add('Bootstrap warnings truncated.');
    }
    return List<String>.unmodifiable(result);
  }
}

class NativeBootstrapCandidateLoader {
  const NativeBootstrapCandidateLoader({
    required LocalNetworkBridge bridge,
    BootstrapCandidateProvider provider =
        const BasicBootstrapCandidateProvider(),
    int maxPeerCandidates = 32,
  }) : _bridge = bridge,
       _provider = provider,
       _maxPeerCandidates = maxPeerCandidates,
       _cancellation = null;

  factory NativeBootstrapCandidateLoader.methodChannel() {
    final cancellation = Completer<void>();
    return NativeBootstrapCandidateLoader._methodChannel(
      cancellation: cancellation,
      bridge: MethodChannelLocalNetworkBridge(
        cancellation: cancellation.future,
      ),
    );
  }

  NativeBootstrapCandidateLoader._methodChannel({
    required LocalNetworkBridge bridge,
    required Completer<void> cancellation,
  }) : _bridge = bridge,
       _provider = const BasicBootstrapCandidateProvider(),
       _maxPeerCandidates = 32,
       _cancellation = cancellation;

  final LocalNetworkBridge _bridge;
  final BootstrapCandidateProvider _provider;
  final int _maxPeerCandidates;
  final Completer<void>? _cancellation;

  void cancel() {
    final cancellation = _cancellation;
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
  }

  Future<NativeBootstrapCandidateLoadResult> load({
    required String sessionId,
    required String tableId,
  }) async {
    if (!_isValidScope(sessionId) || !_isValidScope(tableId)) {
      return NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: 'unavailable',
        warnings: <String>['Local network bootstrap scope is invalid.'],
      );
    }

    if (_maxPeerCandidates < 1) {
      return NativeBootstrapCandidateLoadResult.unavailable(
        nativeNotes: 'unavailable',
        warnings: <String>['Local network peer candidate limit is invalid.'],
      );
    }

    final LocalNetworkCapability capability;
    try {
      capability = await _bridge.getCapability();
    } catch (_) {
      return NativeBootstrapCandidateLoadResult.unavailable(
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

    final normalizedPeerEndpoints = DiscoveredPeerEndpointParser.parseAll(
      discovery.foundEndpoints,
      maxValues: NativeBridgePayloadLimits.maxDiscoveryEntries,
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
        candidates: DiscoveredPeerEndpointParser.projectCandidates(
          candidates,
          peerEndpoints,
          maxValues: NativeBridgePayloadLimits.maxDiscoveryEntries,
        ),
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
    return NativeBridgePayloadLimits.isSafeUtf8Text(
      value,
      NativeBridgePayloadLimits.maxTransportIdentityBytes,
    );
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
    var inspectedValues = 0;
    for (final value in values) {
      if (inspectedValues == NativeBridgePayloadLimits.maxDiscoveryEntries) {
        break;
      }
      inspectedValues += 1;
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

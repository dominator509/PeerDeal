import 'package:peerdeal_mobile/demo_slice/controllers/native_bootstrap_candidate_loader.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('maps native discovery endpoints into bootstrap candidates', () async {
    final bridge = _FakeLocalNetworkBridge(
      capability: const LocalNetworkCapability(
        discoverySupported: true,
        permissionPromptSupported: true,
        broadcastSupported: true,
        notes: 'local-network-ready',
      ),
      discovery: const LocalNetworkDiscoverySnapshot(
        permissionGranted: true,
        foundEndpoints: <String>[' peer-a ', 'peer-b', 'peer-a', ''],
        interfaceHints: <String>['wifi', ' wifi ', ''],
      ),
    );

    final result = await NativeBootstrapCandidateLoader(
      bridge: bridge,
      provider: const BasicBootstrapCandidateProvider(),
    ).load(sessionId: 'session-1', tableId: 'table-1');

    expect(result.discoveryAvailable, isTrue);
    expect(result.hasCandidates, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.nativeNotes, 'local-network-ready; interfaces=wifi');
    expect(result.candidates, hasLength(2));
    expect(result.candidates.first.peerId, 'peer-a');
    expect(result.candidates.first.routeClass, NetworkRouteClass.lanDirect);
    expect(result.candidates.last.peerId, 'peer-b');
    expect(result.candidates.last.routeClass, NetworkRouteClass.p2pRemote);
  });

  test(
    'caps normalized native discovery endpoints before resolution',
    () async {
      final provider = _RecordingBootstrapCandidateProvider();
      final result = await NativeBootstrapCandidateLoader(
        bridge: const _FakeLocalNetworkBridge(
          capability: LocalNetworkCapability(
            discoverySupported: true,
            permissionPromptSupported: true,
            broadcastSupported: true,
            notes: 'local-network-ready',
          ),
          discovery: LocalNetworkDiscoverySnapshot(
            permissionGranted: true,
            foundEndpoints: <String>[
              'peer-a',
              'peer-b',
              'peer-c',
              'peer-a',
              ' ',
            ],
            interfaceHints: <String>[],
          ),
        ),
        provider: provider,
        maxPeerCandidates: 2,
      ).load(sessionId: 'session-1', tableId: 'table-1');

      expect(result.discoveryAvailable, isTrue);
      expect(provider.request!.peerIds, <String>['peer-a', 'peer-b']);
      expect(result.candidates.map((candidate) => candidate.peerId), <String>[
        'peer-a',
        'peer-b',
      ]);
      expect(result.warnings, <String>[
        'Local network discovery peer candidate limit reached.',
      ]);
    },
  );

  test(
    'scrubs native discovery endpoints before candidate resolution',
    () async {
      final provider = _RecordingBootstrapCandidateProvider();
      final result = await NativeBootstrapCandidateLoader(
        bridge: _FakeLocalNetworkBridge(
          capability: const LocalNetworkCapability(
            discoverySupported: true,
            permissionPromptSupported: true,
            broadcastSupported: true,
            notes: 'local-network-ready',
          ),
          discovery: LocalNetworkDiscoverySnapshot(
            permissionGranted: true,
            foundEndpoints: <String>[
              '${'peer'.padRight(120, 'x')}\nsecret',
              r'peer-token-C:\secret\peer.log',
              'peer-safe',
              '',
            ],
            interfaceHints: const <String>[],
          ),
        ),
        provider: provider,
      ).load(sessionId: 'session-1', tableId: 'table-1');

      expect(result.discoveryAvailable, isTrue);
      expect(provider.request!.peerIds, <String>['peer-safe']);
      expect(result.candidates.single.peerId, 'peer-safe');
    },
  );

  test(
    'fails closed when local network peer candidate limit is invalid',
    () async {
      final bridge = _CountingLocalNetworkBridge();
      final result = await NativeBootstrapCandidateLoader(
        bridge: bridge,
        maxPeerCandidates: 0,
      ).load(sessionId: 'session-1', tableId: 'table-1');

      expect(result.discoveryAvailable, isFalse);
      expect(result.candidates, isEmpty);
      expect(result.nativeNotes, 'unavailable');
      expect(result.warnings, <String>[
        'Local network peer candidate limit is invalid.',
      ]);
      expect(bridge.capabilityLookups, 0);
      expect(bridge.discoveryLookups, 0);
    },
  );

  test(
    'fails closed before native lookup when bootstrap scope is invalid',
    () async {
      final bridge = _CountingLocalNetworkBridge();
      final provider = _RecordingBootstrapCandidateProvider();

      final result = await NativeBootstrapCandidateLoader(
        bridge: bridge,
        provider: provider,
      ).load(sessionId: ' ', tableId: 'table-1');

      expect(result.discoveryAvailable, isFalse);
      expect(result.candidates, isEmpty);
      expect(result.nativeNotes, 'unavailable');
      expect(result.warnings, <String>[
        'Local network bootstrap scope is invalid.',
      ]);
      expect(bridge.capabilityLookups, 0);
      expect(bridge.discoveryLookups, 0);
      expect(provider.request, isNull);
    },
  );

  test(
    'fails closed before native lookup when bootstrap scope is padded',
    () async {
      final bridge = _CountingLocalNetworkBridge();
      final provider = _RecordingBootstrapCandidateProvider();

      final result = await NativeBootstrapCandidateLoader(
        bridge: bridge,
        provider: provider,
      ).load(sessionId: ' session-1', tableId: 'table-1');

      expect(result.discoveryAvailable, isFalse);
      expect(result.candidates, isEmpty);
      expect(result.nativeNotes, 'unavailable');
      expect(result.warnings, <String>[
        'Local network bootstrap scope is invalid.',
      ]);
      expect(bridge.capabilityLookups, 0);
      expect(bridge.discoveryLookups, 0);
      expect(provider.request, isNull);
    },
  );

  test('fails closed when local network discovery is unsupported', () async {
    final result = await NativeBootstrapCandidateLoader(
      bridge: _FakeLocalNetworkBridge(
        capability: const LocalNetworkCapability.unavailable(
          warning: 'permission unavailable',
        ),
        discovery: const LocalNetworkDiscoverySnapshot(
          permissionGranted: true,
          foundEndpoints: <String>['peer-a'],
          interfaceHints: <String>[],
        ),
      ),
    ).load(sessionId: 'session-1', tableId: 'table-1');

    expect(result.discoveryAvailable, isFalse);
    expect(result.candidates, isEmpty);
    expect(result.nativeNotes, 'unavailable');
    expect(result.warnings, ['Local network reported a platform warning.']);
  });

  test('scrubs native local-network warning and notes', () async {
    final result = await NativeBootstrapCandidateLoader(
      bridge: _FakeLocalNetworkBridge(
        capability: LocalNetworkCapability(
          discoverySupported: true,
          permissionPromptSupported: true,
          broadcastSupported: true,
          notes: '${'local '.padRight(120, 'x')}\nsecret',
          warning: 'permission_failed: C:\\secret\\network.log',
        ),
        discovery: const LocalNetworkDiscoverySnapshot(
          permissionGranted: true,
          foundEndpoints: <String>[],
          interfaceHints: <String>['wifi\nsecret'],
          warning: 'discovery_failed: C:\\secret\\peers.log',
        ),
      ),
    ).load(sessionId: 'session-1', tableId: 'table-1');

    expect(result.discoveryAvailable, isTrue);
    expect(result.warnings, <String>[
      'Local network reported a platform warning.',
      'Local network reported a platform warning.',
    ]);
    expect(result.warnings.join(' '), isNot(contains('network.log')));
    expect(result.warnings.join(' '), isNot(contains('peers.log')));
    expect(result.nativeNotes, 'unavailable');
    expect(result.nativeNotes, isNot(contains('secret')));
  });

  test('fails closed when local network bridge throws', () async {
    final result = await NativeBootstrapCandidateLoader(
      bridge: _ThrowingLocalNetworkBridge(),
    ).load(sessionId: 'session-1', tableId: 'table-1');

    expect(result.discoveryAvailable, isFalse);
    expect(result.candidates, isEmpty);
    expect(result.warnings, ['Local network capability could not be loaded.']);
  });

  test('fails closed when bootstrap provider throws', () async {
    final result = await NativeBootstrapCandidateLoader(
      bridge: _FakeLocalNetworkBridge(
        capability: const LocalNetworkCapability(
          discoverySupported: true,
          permissionPromptSupported: true,
          broadcastSupported: true,
          notes: 'local-network-ready',
        ),
        discovery: const LocalNetworkDiscoverySnapshot(
          permissionGranted: true,
          foundEndpoints: <String>['peer-a'],
          interfaceHints: <String>[],
        ),
      ),
      provider: _ThrowingBootstrapCandidateProvider(),
    ).load(sessionId: 'session-1', tableId: 'table-1');

    expect(result.discoveryAvailable, isFalse);
    expect(result.candidates, isEmpty);
    expect(result.nativeNotes, 'local-network-ready');
    expect(result.warnings, [
      'Local network bootstrap candidates could not be resolved.',
    ]);
  });
}

class _FakeLocalNetworkBridge implements LocalNetworkBridge {
  const _FakeLocalNetworkBridge({
    required this.capability,
    required this.discovery,
  });

  final LocalNetworkCapability capability;
  final LocalNetworkDiscoverySnapshot discovery;

  @override
  Future<LocalNetworkCapability> getCapability() async => capability;

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async => discovery;
}

class _ThrowingLocalNetworkBridge implements LocalNetworkBridge {
  @override
  Future<LocalNetworkCapability> getCapability() async {
    throw StateError('local network unavailable');
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    throw StateError('not reached');
  }
}

class _CountingLocalNetworkBridge implements LocalNetworkBridge {
  int capabilityLookups = 0;
  int discoveryLookups = 0;

  @override
  Future<LocalNetworkCapability> getCapability() async {
    capabilityLookups += 1;
    return const LocalNetworkCapability(
      discoverySupported: true,
      permissionPromptSupported: true,
      broadcastSupported: true,
      notes: 'local-network-ready',
    );
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    discoveryLookups += 1;
    return const LocalNetworkDiscoverySnapshot(
      permissionGranted: true,
      foundEndpoints: <String>['peer-a'],
      interfaceHints: <String>[],
    );
  }
}

class _ThrowingBootstrapCandidateProvider
    implements BootstrapCandidateProvider {
  @override
  Future<List<BootstrapCandidate>> resolveCandidates(
    BootstrapResolutionRequest request,
  ) async {
    throw StateError('bootstrap failed');
  }
}

class _RecordingBootstrapCandidateProvider
    implements BootstrapCandidateProvider {
  BootstrapResolutionRequest? request;

  @override
  Future<List<BootstrapCandidate>> resolveCandidates(
    BootstrapResolutionRequest request,
  ) async {
    this.request = request;
    return request.peerIds
        .map(
          (peerId) => BootstrapCandidate(
            peerId: peerId,
            routeClass: NetworkRouteClass.lanDirect,
            reachable: true,
            priority: request.peerIds.length,
          ),
        )
        .toList(growable: false);
  }
}

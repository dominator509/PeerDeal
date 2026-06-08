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
    expect(result.warnings, ['permission unavailable']);
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

class _ThrowingBootstrapCandidateProvider
    implements BootstrapCandidateProvider {
  @override
  Future<List<BootstrapCandidate>> resolveCandidates(
    BootstrapResolutionRequest request,
  ) async {
    throw StateError('bootstrap failed');
  }
}

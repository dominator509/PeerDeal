import 'dart:async';

import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/join_flow/native_join_bootstrap_coordinator.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('forwards per-run cancellation to cancellable native bridge', () async {
    final cancellation = Completer<void>();
    final bridge = _RecordingCancellableLocalNetworkBridge();
    final coordinator = NativeJoinBootstrapCoordinator(bridge: bridge);

    await coordinator.buildPlan(
      resolvedInvite: _resolvedInvite,
      roleGrant: _roleGrant,
      cancellation: cancellation.future,
    );

    expect(bridge.capabilityCancellation, same(cancellation.future));
    expect(bridge.discoveryCancellation, same(cancellation.future));
  });

  test('maps native discovery endpoints into join bootstrap plan', () async {
    final provider = _RecordingBootstrapCandidateProvider();
    final coordinator = NativeJoinBootstrapCoordinator(
      bridge: _StaticLocalNetworkBridge(
        capability: LocalNetworkCapability(
          discoverySupported: true,
          permissionPromptSupported: true,
          broadcastSupported: true,
          notes: 'local-network-ready',
        ),
        discovery: LocalNetworkDiscoverySnapshot(
          permissionGranted: true,
          foundEndpoints: <String>[' peer-a ', 'peer-b', 'peer-a', ''],
          interfaceHints: <String>['wifi'],
        ),
      ),
      provider: provider,
    );

    final plan = await coordinator.buildPlan(
      resolvedInvite: _resolvedInvite,
      roleGrant: _roleGrant,
    );

    expect(plan.requiresBootstrap, isTrue);
    expect(plan.peerCandidates, <String>['peer-a', 'peer-b']);
    expect(plan.relayFallbackAllowed, isTrue);
    expect(provider.request!.sessionId, 'sess-1');
    expect(provider.request!.tableId, 'table-1');
    expect(provider.request!.peerIds, <String>['peer-a', 'peer-b']);
  });

  test(
    'caps normalized native discovery endpoints before join bootstrap',
    () async {
      final provider = _RecordingBootstrapCandidateProvider();
      final coordinator = NativeJoinBootstrapCoordinator(
        bridge: _StaticLocalNetworkBridge(
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
      );

      final plan = await coordinator.buildPlan(
        resolvedInvite: _resolvedInvite,
        roleGrant: _roleGrant,
      );

      expect(plan.peerCandidates, <String>['peer-a', 'peer-b']);
      expect(provider.request!.peerIds, <String>['peer-a', 'peer-b']);
    },
  );

  test(
    'caps and normalizes provider candidates before join bootstrap',
    () async {
      final coordinator = NativeJoinBootstrapCoordinator(
        bridge: _StaticLocalNetworkBridge(
          capability: LocalNetworkCapability(
            discoverySupported: true,
            permissionPromptSupported: true,
            broadcastSupported: true,
            notes: 'local-network-ready',
          ),
          discovery: LocalNetworkDiscoverySnapshot(
            permissionGranted: true,
            foundEndpoints: <String>['peer-a'],
            interfaceHints: <String>[],
          ),
        ),
        provider: _StaticBootstrapCandidateProvider(
          candidates: <BootstrapCandidate>[
            BootstrapCandidate(
              peerId: ' peer-a ',
              routeClass: NetworkRouteClass.lanDirect,
              reachable: true,
              priority: 3,
            ),
            BootstrapCandidate(
              peerId: 'peer-b',
              routeClass: NetworkRouteClass.p2pRemote,
              reachable: true,
              priority: 2,
            ),
            BootstrapCandidate(
              peerId: 'peer-c',
              routeClass: NetworkRouteClass.p2pRemote,
              reachable: true,
              priority: 1,
            ),
          ],
        ),
        maxPeerCandidates: 2,
      );

      final plan = await coordinator.buildPlan(
        resolvedInvite: _resolvedInvite,
        roleGrant: _roleGrant,
      );

      expect(plan.peerCandidates, <String>['peer-a', 'peer-b']);
      expect(plan.selectedPeerId, 'peer-a');
    },
  );

  test('scrubs native discovery endpoints before join bootstrap', () async {
    final provider = _RecordingBootstrapCandidateProvider();
    final coordinator = NativeJoinBootstrapCoordinator(
      bridge: _StaticLocalNetworkBridge(
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
    );

    final plan = await coordinator.buildPlan(
      resolvedInvite: _resolvedInvite,
      roleGrant: _roleGrant,
    );

    expect(provider.request!.peerIds, <String>['peer-safe']);
    expect(plan.peerCandidates.single, 'peer-safe');
  });

  test('keeps relay fallback when peer candidate limit is invalid', () async {
    final provider = _RecordingBootstrapCandidateProvider();
    final bridge = _CountingLocalNetworkBridge();
    final coordinator = NativeJoinBootstrapCoordinator(
      bridge: bridge,
      provider: provider,
      maxPeerCandidates: 0,
    );

    final plan = await coordinator.buildPlan(
      resolvedInvite: _resolvedInvite,
      roleGrant: _roleGrant,
    );

    expect(plan.requiresBootstrap, isTrue);
    expect(plan.peerCandidates, isEmpty);
    expect(plan.relayFallbackAllowed, isTrue);
    expect(provider.request, isNull);
    expect(bridge.capabilityLookups, 0);
    expect(bridge.discoveryLookups, 0);
  });

  test(
    'keeps relay fallback before native lookup when scope is invalid',
    () async {
      final provider = _RecordingBootstrapCandidateProvider();
      final bridge = _CountingLocalNetworkBridge();
      final coordinator = NativeJoinBootstrapCoordinator(
        bridge: bridge,
        provider: provider,
      );

      final plan = await coordinator.buildPlan(
        resolvedInvite: const ResolvedInvite(
          inviteId: 'invite-1',
          tableId: 'table-1',
          sessionId: ' ',
          modeType: 'open_table',
          protocolVersion: '1.0.0',
          requiresReceiptAck: true,
          requiresRetentionAck: true,
          requiresCaptureAck: true,
        ),
        roleGrant: _roleGrant,
      );

      expect(plan.requiresBootstrap, isTrue);
      expect(plan.peerCandidates, isEmpty);
      expect(plan.relayFallbackAllowed, isTrue);
      expect(provider.request, isNull);
      expect(bridge.capabilityLookups, 0);
      expect(bridge.discoveryLookups, 0);
    },
  );

  test(
    'keeps relay fallback before native lookup when scope is padded',
    () async {
      final provider = _RecordingBootstrapCandidateProvider();
      final bridge = _CountingLocalNetworkBridge();
      final coordinator = NativeJoinBootstrapCoordinator(
        bridge: bridge,
        provider: provider,
      );

      final plan = await coordinator.buildPlan(
        resolvedInvite: const ResolvedInvite(
          inviteId: 'invite-1',
          tableId: 'table-1 ',
          sessionId: 'sess-1',
          modeType: 'open_table',
          protocolVersion: '1.0.0',
          requiresReceiptAck: true,
          requiresRetentionAck: true,
          requiresCaptureAck: true,
        ),
        roleGrant: _roleGrant,
      );

      expect(plan.requiresBootstrap, isTrue);
      expect(plan.peerCandidates, isEmpty);
      expect(plan.relayFallbackAllowed, isTrue);
      expect(provider.request, isNull);
      expect(bridge.capabilityLookups, 0);
      expect(bridge.discoveryLookups, 0);
    },
  );

  test('keeps relay fallback when local discovery is unavailable', () async {
    final coordinator = NativeJoinBootstrapCoordinator(
      bridge: _ThrowingLocalNetworkBridge(),
    );

    final plan = await coordinator.buildPlan(
      resolvedInvite: _resolvedInvite,
      roleGrant: _roleGrant,
    );

    expect(plan.requiresBootstrap, isTrue);
    expect(plan.peerCandidates, isEmpty);
    expect(plan.relayFallbackAllowed, isTrue);
  });

  test('keeps relay fallback when provider resolution fails', () async {
    final coordinator = NativeJoinBootstrapCoordinator(
      bridge: _StaticLocalNetworkBridge(
        capability: LocalNetworkCapability(
          discoverySupported: true,
          permissionPromptSupported: true,
          broadcastSupported: true,
          notes: 'local-network-ready',
        ),
        discovery: LocalNetworkDiscoverySnapshot(
          permissionGranted: true,
          foundEndpoints: <String>['peer-a'],
          interfaceHints: <String>[],
        ),
      ),
      provider: _ThrowingBootstrapCandidateProvider(),
    );

    final plan = await coordinator.buildPlan(
      resolvedInvite: _resolvedInvite,
      roleGrant: _roleGrant,
    );

    expect(plan.requiresBootstrap, isTrue);
    expect(plan.peerCandidates, isEmpty);
    expect(plan.relayFallbackAllowed, isTrue);
  });
}

const _resolvedInvite = ResolvedInvite(
  inviteId: 'invite-1',
  tableId: 'table-1',
  sessionId: 'sess-1',
  modeType: 'open_table',
  protocolVersion: '1.0.0',
  requiresReceiptAck: true,
  requiresRetentionAck: true,
  requiresCaptureAck: true,
);

final _roleGrant = RoleGrant(
  grantedRole: RequestedRole.player,
  permissions: <String>['participate'],
);

class _StaticLocalNetworkBridge implements LocalNetworkBridge {
  const _StaticLocalNetworkBridge({
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
    return LocalNetworkDiscoverySnapshot(
      permissionGranted: true,
      foundEndpoints: <String>['peer-a'],
      interfaceHints: <String>[],
    );
  }
}

class _RecordingCancellableLocalNetworkBridge
    implements LocalNetworkBridge, CancellableLocalNetworkBridge {
  Future<void>? capabilityCancellation;
  Future<void>? discoveryCancellation;

  @override
  Future<LocalNetworkCapability> getCapability({
    Future<void>? cancellation,
  }) async {
    capabilityCancellation = cancellation;
    return const LocalNetworkCapability(
      discoverySupported: true,
      permissionPromptSupported: true,
      broadcastSupported: true,
      notes: 'local-network-ready',
    );
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers({
    Future<void>? cancellation,
  }) async {
    discoveryCancellation = cancellation;
    return LocalNetworkDiscoverySnapshot(
      permissionGranted: true,
      foundEndpoints: <String>['peer-a'],
      interfaceHints: <String>[],
    );
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

class _StaticBootstrapCandidateProvider implements BootstrapCandidateProvider {
  const _StaticBootstrapCandidateProvider({required this.candidates});

  final List<BootstrapCandidate> candidates;

  @override
  Future<List<BootstrapCandidate>> resolveCandidates(
    BootstrapResolutionRequest request,
  ) async => candidates;
}

class _ThrowingBootstrapCandidateProvider
    implements BootstrapCandidateProvider {
  @override
  Future<List<BootstrapCandidate>> resolveCandidates(
    BootstrapResolutionRequest request,
  ) async {
    throw StateError('bootstrap unavailable');
  }
}

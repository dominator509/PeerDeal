import 'local_network_bridge_models.dart';

abstract interface class LocalNetworkBridge {
  Future<LocalNetworkCapability> getCapability();
  Future<LocalNetworkDiscoverySnapshot> discoverPeers();
}

/// Optional generic endpoint-announcement capability for native discovery.
///
/// This carries only a peer identity and transport port. Session policy,
/// authentication, and route selection remain outside the native bridge.
abstract interface class LocalNetworkPeerAnnouncer {
  Future<LocalNetworkAnnouncementResult> announcePeer({
    required String peerId,
    required int port,
  });
}

abstract interface class CancellableLocalNetworkPeerAnnouncer {
  Future<LocalNetworkAnnouncementResult> announcePeer({
    required String peerId,
    required int port,
    Future<void>? cancellation,
  });
}

/// Optional per-call cancellation capability for app-owned lifecycles.
abstract interface class CancellableLocalNetworkBridge {
  Future<LocalNetworkCapability> getCapability({Future<void>? cancellation});

  Future<LocalNetworkDiscoverySnapshot> discoverPeers({
    Future<void>? cancellation,
  });
}

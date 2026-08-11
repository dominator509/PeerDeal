import 'local_network_bridge_models.dart';

abstract interface class LocalNetworkBridge {
  Future<LocalNetworkCapability> getCapability();
  Future<LocalNetworkDiscoverySnapshot> discoverPeers();
}

/// Optional per-call cancellation capability for app-owned lifecycles.
abstract interface class CancellableLocalNetworkBridge {
  Future<LocalNetworkCapability> getCapability({Future<void>? cancellation});

  Future<LocalNetworkDiscoverySnapshot> discoverPeers({
    Future<void>? cancellation,
  });
}

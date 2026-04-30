import 'local_network_bridge_models.dart';

abstract interface class LocalNetworkBridge {
  Future<LocalNetworkCapability> getCapability();
  Future<LocalNetworkDiscoverySnapshot> discoverPeers();
}

import '../models/lan_discovery_result.dart';

abstract interface class LanDiscoveryService {
  Future<LanDiscoveryResult> discoverPeers();
}

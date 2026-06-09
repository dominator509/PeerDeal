import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

const _defaultSecureKeyNamespace = 'peerdeal.receipts';

class AppNativeReadinessSnapshot {
  const AppNativeReadinessSnapshot({
    required this.captureProtectionReady,
    required this.localNetworkDiscoveryReady,
    required this.nativeTransportReady,
    required this.secureKeyStorageReady,
    required this.warnings,
  });

  final bool captureProtectionReady;
  final bool localNetworkDiscoveryReady;
  final bool nativeTransportReady;
  final bool secureKeyStorageReady;
  final List<String> warnings;

  bool get allCapabilitiesReady =>
      captureProtectionReady &&
      localNetworkDiscoveryReady &&
      nativeTransportReady &&
      secureKeyStorageReady;
}

class AppNativeReadinessLoader {
  const AppNativeReadinessLoader({
    required CaptureProtectionBridge captureProtectionBridge,
    required LocalNetworkBridge localNetworkBridge,
    required NativeTransportBridge nativeTransportBridge,
    required SecureKeyStorageBridge secureKeyStorageBridge,
    String secureKeyNamespace = _defaultSecureKeyNamespace,
  }) : _captureProtectionBridge = captureProtectionBridge,
       _localNetworkBridge = localNetworkBridge,
       _nativeTransportBridge = nativeTransportBridge,
       _secureKeyStorageBridge = secureKeyStorageBridge,
       _secureKeyNamespace = secureKeyNamespace;

  factory AppNativeReadinessLoader.methodChannel({
    String secureKeyNamespace = _defaultSecureKeyNamespace,
  }) {
    return AppNativeReadinessLoader(
      captureProtectionBridge: MethodChannelCaptureProtectionBridge(),
      localNetworkBridge: MethodChannelLocalNetworkBridge(),
      nativeTransportBridge: MethodChannelNativeTransportBridge(),
      secureKeyStorageBridge: MethodChannelSecureKeyStorageBridge(),
      secureKeyNamespace: secureKeyNamespace,
    );
  }

  final CaptureProtectionBridge _captureProtectionBridge;
  final LocalNetworkBridge _localNetworkBridge;
  final NativeTransportBridge _nativeTransportBridge;
  final SecureKeyStorageBridge _secureKeyStorageBridge;
  final String _secureKeyNamespace;

  Future<AppNativeReadinessSnapshot> load() async {
    final warnings = <String>[];

    final captureProtectionReady = await _loadCaptureProtection(warnings);
    final localNetworkDiscoveryReady = await _loadLocalNetwork(warnings);
    final nativeTransportReady = await _loadNativeTransport(warnings);
    final secureKeyStorageReady = await _loadSecureKeyStorage(warnings);

    return AppNativeReadinessSnapshot(
      captureProtectionReady: captureProtectionReady,
      localNetworkDiscoveryReady: localNetworkDiscoveryReady,
      nativeTransportReady: nativeTransportReady,
      secureKeyStorageReady: secureKeyStorageReady,
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  Future<bool> _loadCaptureProtection(List<String> warnings) async {
    try {
      final capability = await _captureProtectionBridge.getCapability();
      final ready =
          capability.blockingSupported && capability.obscuringSupported;
      if (!ready) warnings.add('native capture protection unavailable');
      return ready;
    } on Object {
      warnings.add('native capture protection unavailable');
      return false;
    }
  }

  Future<bool> _loadLocalNetwork(List<String> warnings) async {
    try {
      final capability = await _localNetworkBridge.getCapability();
      if (!capability.discoverySupported) {
        warnings.add('native local-network discovery unavailable');
        return false;
      }
      return true;
    } on Object {
      warnings.add('native local-network discovery unavailable');
      return false;
    }
  }

  Future<bool> _loadNativeTransport(List<String> warnings) async {
    try {
      final capability = await _nativeTransportBridge.getCapability();
      final ready =
          capability.available &&
          capability.sendSupported &&
          capability.receiveSupported &&
          capability.maxPayloadBytes > 0;
      if (!ready) warnings.add('native transport unavailable');
      return ready;
    } on Object {
      warnings.add('native transport unavailable');
      return false;
    }
  }

  Future<bool> _loadSecureKeyStorage(List<String> warnings) async {
    if (_secureKeyNamespace.trim() != _secureKeyNamespace ||
        _secureKeyNamespace.isEmpty) {
      warnings.add('native secure-key storage unavailable');
      return false;
    }
    try {
      final snapshot = await _secureKeyStorageBridge.loadKeyRing(
        namespace: _secureKeyNamespace,
      );
      if (!snapshot.available) {
        warnings.add('native secure-key storage unavailable');
        return false;
      }
      return true;
    } on Object {
      warnings.add('native secure-key storage unavailable');
      return false;
    }
  }
}

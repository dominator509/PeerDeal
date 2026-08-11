import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

const _defaultSecureKeyNamespace = 'peerdeal.receipts';
const _defaultNativeTransportMaxPayloadBytes = 64 * 1024;

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
    int nativeTransportMaxPayloadBytes = _defaultNativeTransportMaxPayloadBytes,
  }) : _captureProtectionBridge = captureProtectionBridge,
       _localNetworkBridge = localNetworkBridge,
       _nativeTransportBridge = nativeTransportBridge,
       _secureKeyStorageBridge = secureKeyStorageBridge,
       _secureKeyNamespace = secureKeyNamespace,
       _nativeTransportMaxPayloadBytes = nativeTransportMaxPayloadBytes;

  factory AppNativeReadinessLoader.methodChannel({
    String secureKeyNamespace = _defaultSecureKeyNamespace,
    int nativeTransportMaxPayloadBytes = _defaultNativeTransportMaxPayloadBytes,
  }) {
    return AppNativeReadinessLoader(
      captureProtectionBridge: MethodChannelCaptureProtectionBridge(),
      localNetworkBridge: MethodChannelLocalNetworkBridge(),
      nativeTransportBridge: MethodChannelNativeTransportBridge(),
      secureKeyStorageBridge: MethodChannelSecureKeyStorageBridge(),
      secureKeyNamespace: secureKeyNamespace,
      nativeTransportMaxPayloadBytes: nativeTransportMaxPayloadBytes,
    );
  }

  final CaptureProtectionBridge _captureProtectionBridge;
  final LocalNetworkBridge _localNetworkBridge;
  final NativeTransportBridge _nativeTransportBridge;
  final SecureKeyStorageBridge _secureKeyStorageBridge;
  final String _secureKeyNamespace;
  final int _nativeTransportMaxPayloadBytes;

  Future<AppNativeReadinessSnapshot> load({Future<void>? cancellation}) async {
    final warnings = <String>[];

    final captureProtectionReady = await _loadCaptureProtection(
      warnings,
      cancellation: cancellation,
    );
    final localNetworkDiscoveryReady = await _loadLocalNetwork(
      warnings,
      cancellation: cancellation,
    );
    final nativeTransportReady = await _loadNativeTransport(
      warnings,
      cancellation: cancellation,
    );
    final secureKeyStorageReady = await _loadSecureKeyStorage(
      warnings,
      cancellation: cancellation,
    );

    return AppNativeReadinessSnapshot(
      captureProtectionReady: captureProtectionReady,
      localNetworkDiscoveryReady: localNetworkDiscoveryReady,
      nativeTransportReady: nativeTransportReady,
      secureKeyStorageReady: secureKeyStorageReady,
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  Future<bool> _loadCaptureProtection(
    List<String> warnings, {
    Future<void>? cancellation,
  }) async {
    try {
      final capability =
          _captureProtectionBridge is CancellableCaptureProtectionBridge
          ? await (_captureProtectionBridge
                    as CancellableCaptureProtectionBridge)
                .getCapability(cancellation: cancellation)
          : await _captureProtectionBridge.getCapability();
      final ready =
          capability.blockingSupported && capability.obscuringSupported;
      if (!ready) warnings.add('native capture protection unavailable');
      return ready;
    } on Object {
      warnings.add('native capture protection unavailable');
      return false;
    }
  }

  Future<bool> _loadLocalNetwork(
    List<String> warnings, {
    Future<void>? cancellation,
  }) async {
    try {
      final capability = _localNetworkBridge is CancellableLocalNetworkBridge
          ? await (_localNetworkBridge as CancellableLocalNetworkBridge)
                .getCapability(cancellation: cancellation)
          : await _localNetworkBridge.getCapability();
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

  Future<bool> _loadNativeTransport(
    List<String> warnings, {
    Future<void>? cancellation,
  }) async {
    if (_nativeTransportMaxPayloadBytes < 1) {
      warnings.add('native transport unavailable');
      return false;
    }
    try {
      final capability =
          _nativeTransportBridge is CancellableNativeTransportBridge
          ? await (_nativeTransportBridge as CancellableNativeTransportBridge)
                .getCapability(cancellation: cancellation)
          : await _nativeTransportBridge.getCapability();
      final ready =
          capability.available &&
          capability.sendSupported &&
          capability.receiveSupported &&
          capability.maxPayloadBytes > 0 &&
          capability.maxPayloadBytes <= _nativeTransportMaxPayloadBytes;
      if (!ready) warnings.add('native transport unavailable');
      return ready;
    } on Object {
      warnings.add('native transport unavailable');
      return false;
    }
  }

  Future<bool> _loadSecureKeyStorage(
    List<String> warnings, {
    Future<void>? cancellation,
  }) async {
    if (!_isValidSecureKeyNamespace(_secureKeyNamespace)) {
      warnings.add('native secure-key storage unavailable');
      return false;
    }
    try {
      final snapshot =
          _secureKeyStorageBridge is CancellableSecureKeyStorageBridge
          ? await (_secureKeyStorageBridge as CancellableSecureKeyStorageBridge)
                .loadKeyRing(
                  namespace: _secureKeyNamespace,
                  cancellation: cancellation,
                )
          : await _secureKeyStorageBridge.loadKeyRing(
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

  bool _isValidSecureKeyNamespace(String namespace) {
    if (namespace.isEmpty || namespace.trim() != namespace) return false;
    if (namespace.contains('::')) return false;

    for (final codeUnit in namespace.codeUnits) {
      if (codeUnit < 0x20 || codeUnit == 0x7f) return false;
    }

    return true;
  }
}

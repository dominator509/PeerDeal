import 'package:peerdeal_desktop/native_readiness/app_native_readiness_loader.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test('reports ready when all native capabilities are available', () async {
    final secureStorage = _FakeSecureKeyStorageBridge(
      snapshot: const SecureKeyStorageSnapshot(available: true, keys: []),
    );
    final loader = AppNativeReadinessLoader(
      captureProtectionBridge: _FakeCaptureProtectionBridge(
        capability: const CaptureProtectionCapability(
          blockingSupported: true,
          obscuringSupported: true,
          notes: 'ready',
        ),
      ),
      localNetworkBridge: _FakeLocalNetworkBridge(
        capability: const LocalNetworkCapability(
          discoverySupported: true,
          permissionPromptSupported: true,
          broadcastSupported: false,
          notes: 'ready',
        ),
      ),
      nativeTransportBridge: _FakeNativeTransportBridge(
        capability: const NativeTransportCapability(
          available: true,
          sendSupported: true,
          receiveSupported: true,
          maxPayloadBytes: 1024,
          notes: 'ready',
        ),
      ),
      secureKeyStorageBridge: secureStorage,
    );

    final snapshot = await loader.load();

    expect(snapshot.allCapabilitiesReady, isTrue);
    expect(snapshot.warnings, isEmpty);
    expect(secureStorage.namespaces, <String>['peerdeal.receipts']);
  });

  test(
    'fails closed with stable warnings when native capabilities are absent',
    () async {
      final loader = AppNativeReadinessLoader(
        captureProtectionBridge: _FakeCaptureProtectionBridge(
          capability: const CaptureProtectionCapability.unavailable(
            warning: 'token leaked from platform',
          ),
        ),
        localNetworkBridge: _FakeLocalNetworkBridge(
          capability: const LocalNetworkCapability.unavailable(
            warning: r'C:\secret\lan.log',
          ),
        ),
        nativeTransportBridge: _FakeNativeTransportBridge(
          capability: const NativeTransportCapability.unavailable(
            warning: 'password from platform',
          ),
        ),
        secureKeyStorageBridge: _FakeSecureKeyStorageBridge(
          snapshot: const SecureKeyStorageSnapshot.unavailable(
            warning: 'secret keychain detail',
          ),
        ),
      );

      final snapshot = await loader.load();

      expect(snapshot.allCapabilitiesReady, isFalse);
      expect(snapshot.captureProtectionReady, isFalse);
      expect(snapshot.localNetworkDiscoveryReady, isFalse);
      expect(snapshot.nativeTransportReady, isFalse);
      expect(snapshot.secureKeyStorageReady, isFalse);
      expect(snapshot.warnings, <String>[
        'native capture protection unavailable',
        'native local-network discovery unavailable',
        'native transport unavailable',
        'native secure-key storage unavailable',
      ]);
    },
  );

  test(
    'converts native bridge exceptions into stable unavailable warnings',
    () async {
      final loader = AppNativeReadinessLoader(
        captureProtectionBridge: _ThrowingCaptureProtectionBridge(),
        localNetworkBridge: _ThrowingLocalNetworkBridge(),
        nativeTransportBridge: _ThrowingNativeTransportBridge(),
        secureKeyStorageBridge: _ThrowingSecureKeyStorageBridge(),
      );

      final snapshot = await loader.load();

      expect(snapshot.allCapabilitiesReady, isFalse);
      expect(snapshot.warnings, <String>[
        'native capture protection unavailable',
        'native local-network discovery unavailable',
        'native transport unavailable',
        'native secure-key storage unavailable',
      ]);
    },
  );

  test(
    'rejects malformed secure-key namespaces before native storage',
    () async {
      for (final namespace in <String>[
        ' peerdeal.receipts',
        'peerdeal.receipts\nsecret',
        'peerdeal::receipts',
      ]) {
        final secureStorage = _FakeSecureKeyStorageBridge(
          snapshot: const SecureKeyStorageSnapshot(available: true, keys: []),
        );
        final loader = AppNativeReadinessLoader(
          captureProtectionBridge: _FakeCaptureProtectionBridge(
            capability: const CaptureProtectionCapability(
              blockingSupported: true,
              obscuringSupported: true,
              notes: 'ready',
            ),
          ),
          localNetworkBridge: _FakeLocalNetworkBridge(
            capability: const LocalNetworkCapability(
              discoverySupported: true,
              permissionPromptSupported: true,
              broadcastSupported: false,
              notes: 'ready',
            ),
          ),
          nativeTransportBridge: _FakeNativeTransportBridge(
            capability: const NativeTransportCapability(
              available: true,
              sendSupported: true,
              receiveSupported: true,
              maxPayloadBytes: 1024,
              notes: 'ready',
            ),
          ),
          secureKeyStorageBridge: secureStorage,
          secureKeyNamespace: namespace,
        );

        final snapshot = await loader.load();

        expect(snapshot.secureKeyStorageReady, isFalse, reason: namespace);
        expect(snapshot.warnings, <String>[
          'native secure-key storage unavailable',
        ], reason: namespace);
        expect(secureStorage.namespaces, isEmpty, reason: namespace);
      }
    },
  );
}

class _FakeCaptureProtectionBridge implements CaptureProtectionBridge {
  const _FakeCaptureProtectionBridge({required this.capability});

  final CaptureProtectionCapability capability;

  @override
  Future<CaptureProtectionCapability> getCapability() async => capability;
}

class _FakeLocalNetworkBridge implements LocalNetworkBridge {
  const _FakeLocalNetworkBridge({required this.capability});

  final LocalNetworkCapability capability;

  @override
  Future<LocalNetworkCapability> getCapability() async => capability;

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async =>
      const LocalNetworkDiscoverySnapshot.unavailable();
}

class _FakeNativeTransportBridge implements NativeTransportBridge {
  const _FakeNativeTransportBridge({required this.capability});

  final NativeTransportCapability capability;

  @override
  Future<NativeTransportCapability> getCapability() async => capability;

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    return const NativeTransportSendResult(isSuccess: true);
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    return const NativeTransportReceiveSnapshot(available: true, frames: []);
  }
}

class _FakeSecureKeyStorageBridge implements SecureKeyStorageBridge {
  _FakeSecureKeyStorageBridge({required this.snapshot});

  final SecureKeyStorageSnapshot snapshot;
  final List<String> namespaces = <String>[];

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    namespaces.add(namespace);
    return snapshot;
  }
}

class _ThrowingCaptureProtectionBridge implements CaptureProtectionBridge {
  @override
  Future<CaptureProtectionCapability> getCapability() async {
    throw StateError('token leaked from platform');
  }
}

class _ThrowingLocalNetworkBridge implements LocalNetworkBridge {
  @override
  Future<LocalNetworkCapability> getCapability() async {
    throw StateError(r'C:\secret\lan.log');
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    throw StateError('unused');
  }
}

class _ThrowingNativeTransportBridge implements NativeTransportBridge {
  @override
  Future<NativeTransportCapability> getCapability() async {
    throw StateError('password from platform');
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    throw StateError('unused');
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    throw StateError('unused');
  }
}

class _ThrowingSecureKeyStorageBridge implements SecureKeyStorageBridge {
  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    throw StateError('secret keychain detail');
  }
}

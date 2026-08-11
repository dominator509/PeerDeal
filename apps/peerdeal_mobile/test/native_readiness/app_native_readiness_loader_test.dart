import 'dart:async';

import 'package:peerdeal_mobile/native_readiness/app_native_readiness_loader.dart';
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

  test('cancels cancellable readiness capability lookups', () async {
    final cancellation = Completer<void>();
    final loader = AppNativeReadinessLoader(
      captureProtectionBridge: _CancellableCaptureProtectionBridge(),
      localNetworkBridge: _CancellableLocalNetworkBridge(),
      nativeTransportBridge: _CancellableNativeTransportBridge(),
      secureKeyStorageBridge: _CancellableSecureKeyStorageBridge(),
    );

    final readiness = loader.load(cancellation: cancellation.future);
    cancellation.complete();
    final snapshot = await readiness;

    expect(snapshot.allCapabilitiesReady, isFalse);
    expect(snapshot.warnings, <String>[
      'native capture protection unavailable',
      'native local-network discovery unavailable',
      'native transport unavailable',
      'native secure-key storage unavailable',
    ]);
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

  test('rejects oversized native transport payload limits', () async {
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
          maxPayloadBytes: 4096,
          notes: 'too-large',
        ),
      ),
      secureKeyStorageBridge: _FakeSecureKeyStorageBridge(
        snapshot: const SecureKeyStorageSnapshot(available: true, keys: []),
      ),
      nativeTransportMaxPayloadBytes: 1024,
    );

    final snapshot = await loader.load();

    expect(snapshot.nativeTransportReady, isFalse);
    expect(snapshot.allCapabilitiesReady, isFalse);
    expect(snapshot.warnings, <String>['native transport unavailable']);
  });

  test(
    'rejects invalid app transport payload limit before native lookup',
    () async {
      final nativeTransport = _FakeNativeTransportBridge();
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
        nativeTransportBridge: nativeTransport,
        secureKeyStorageBridge: _FakeSecureKeyStorageBridge(
          snapshot: const SecureKeyStorageSnapshot(available: true, keys: []),
        ),
        nativeTransportMaxPayloadBytes: 0,
      );

      final snapshot = await loader.load();

      expect(snapshot.nativeTransportReady, isFalse);
      expect(snapshot.allCapabilitiesReady, isFalse);
      expect(snapshot.warnings, <String>['native transport unavailable']);
      expect(nativeTransport.capabilityLookups, 0);
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
  _FakeNativeTransportBridge({
    this.capability = const NativeTransportCapability(
      available: true,
      sendSupported: true,
      receiveSupported: true,
      maxPayloadBytes: 1024,
      notes: 'ready',
    ),
  });

  final NativeTransportCapability capability;
  int capabilityLookups = 0;

  @override
  Future<NativeTransportCapability> getCapability() async {
    capabilityLookups += 1;
    return capability;
  }

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

class _CancellableCaptureProtectionBridge
    implements CaptureProtectionBridge, CancellableCaptureProtectionBridge {
  @override
  Future<CaptureProtectionCapability> getCapability({
    Future<void>? cancellation,
  }) async {
    if (cancellation != null) await cancellation;
    return const CaptureProtectionCapability.unavailable();
  }
}

class _CancellableLocalNetworkBridge
    implements LocalNetworkBridge, CancellableLocalNetworkBridge {
  @override
  Future<LocalNetworkCapability> getCapability({
    Future<void>? cancellation,
  }) async {
    if (cancellation != null) await cancellation;
    return const LocalNetworkCapability.unavailable();
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers({
    Future<void>? cancellation,
  }) async {
    if (cancellation != null) await cancellation;
    return const LocalNetworkDiscoverySnapshot.unavailable();
  }
}

class _CancellableNativeTransportBridge
    implements NativeTransportBridge, CancellableNativeTransportBridge {
  @override
  Future<NativeTransportCapability> getCapability({
    Future<void>? cancellation,
  }) async {
    if (cancellation != null) await cancellation;
    return const NativeTransportCapability.unavailable();
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame, {
    Future<void>? cancellation,
  }) async {
    if (cancellation != null) await cancellation;
    return const NativeTransportSendResult.failure(warning: 'cancelled');
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
    Future<void>? cancellation,
  }) async {
    if (cancellation != null) await cancellation;
    return const NativeTransportReceiveSnapshot.unavailable();
  }
}

class _CancellableSecureKeyStorageBridge
    implements SecureKeyStorageBridge, CancellableSecureKeyStorageBridge {
  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
    Future<void>? cancellation,
  }) async {
    if (cancellation != null) await cancellation;
    return const SecureKeyStorageSnapshot.unavailable();
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

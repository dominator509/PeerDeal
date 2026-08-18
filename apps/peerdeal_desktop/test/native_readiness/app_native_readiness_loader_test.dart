import 'dart:async';

import 'package:peerdeal_desktop/native_readiness/app_native_readiness_loader.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test('copies and freezes readiness warning diagnostics', () {
    final warnings = <String>['warning_1'];
    final result = AppNativeReadinessSnapshot(
      captureProtectionReady: false,
      localNetworkDiscoveryReady: false,
      nativeTransportReady: false,
      secureKeyStorageReady: false,
      warnings: warnings,
    );

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('bounds and scrubs direct readiness warnings', () {
    final result = AppNativeReadinessSnapshot(
      captureProtectionReady: false,
      localNetworkDiscoveryReady: false,
      nativeTransportReady: false,
      secureKeyStorageReady: false,
      warnings: <String>[
        'warning_1',
        ' warning_2',
        'line\nfeed',
        'warning_4',
        'warning_5',
      ],
    );

    expect(result.warnings, [
      'warning_1',
      'Native readiness warning unavailable.',
      'Native readiness warning unavailable.',
      'Native readiness warnings truncated.',
    ]);
  });

  test('reports ready when all native capabilities are available', () async {
    final secureStorage = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
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

  test('rejects malformed secure-key readiness snapshots', () async {
    final snapshots = <SecureKeyStorageSnapshot>[
      SecureKeyStorageSnapshot(available: true, revision: -1, keys: const []),
      SecureKeyStorageSnapshot(
        available: true,
        keys: List<SecureKeyRecord>.filled(
          NativeBridgePayloadLimits.maxSecureKeyRecords + 1,
          const SecureKeyRecord(
            keyId: 'key',
            purpose: 'purpose',
            algorithm: 'algorithm',
            secret: 'secret',
            active: true,
          ),
        ),
      ),
      SecureKeyStorageSnapshot(
        available: true,
        keys: const <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'key',
            purpose: 'purpose',
            algorithm: 'algorithm',
            secret: 'line\nfeed',
            active: true,
          ),
        ],
      ),
    ];

    for (final snapshot in snapshots) {
      final readiness = await _readyLoader(snapshot).load();

      expect(readiness.secureKeyStorageReady, isFalse);
      expect(readiness.allCapabilitiesReady, isFalse);
      expect(readiness.warnings, <String>[
        'native secure-key storage unavailable',
      ]);
    }
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

  test('does not invoke later readiness bridges after cancellation', () async {
    final cancellation = Completer<void>();
    final localNetwork = _CountingLocalNetworkBridge();
    final nativeTransport = _CountingNativeTransportBridge();
    final secureStorage = _CountingSecureKeyStorageBridge();
    final loader = AppNativeReadinessLoader(
      captureProtectionBridge: _CancellingCaptureProtectionBridge(cancellation),
      localNetworkBridge: localNetwork,
      nativeTransportBridge: nativeTransport,
      secureKeyStorageBridge: secureStorage,
    );

    final snapshot = await loader.load(cancellation: cancellation.future);

    expect(snapshot.allCapabilitiesReady, isFalse);
    expect(snapshot.warnings, <String>[
      'native capture protection unavailable',
      'native local-network discovery unavailable',
      'native transport unavailable',
      'native secure-key storage unavailable',
    ]);
    expect(localNetwork.capabilityLookups, 0);
    expect(nativeTransport.capabilityLookups, 0);
    expect(secureStorage.loadLookups, 0);
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
        snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
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
          snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
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
    'rejects app transport payload limits above the native contract',
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
          snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
        ),
        nativeTransportMaxPayloadBytes:
            NativeBridgePayloadLimits.maxTransportPayloadBytes + 1,
      );

      final snapshot = await loader.load();

      expect(snapshot.nativeTransportReady, isFalse);
      expect(snapshot.warnings, <String>['native transport unavailable']);
      expect(nativeTransport.capabilityLookups, 0);
    },
  );

  test(
    'rejects a reported transport payload limit above the native contract',
    () async {
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
            maxPayloadBytes:
                NativeBridgePayloadLimits.maxTransportPayloadBytes + 1,
            notes: 'invalid',
          ),
        ),
        secureKeyStorageBridge: _FakeSecureKeyStorageBridge(
          snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
        ),
      );

      final snapshot = await loader.load();

      expect(snapshot.nativeTransportReady, isFalse);
      expect(snapshot.warnings, <String>['native transport unavailable']);
    },
  );

  test(
    'rejects malformed secure-key namespaces before native storage',
    () async {
      for (final namespace in <String>[
        ' peerdeal.receipts',
        'peerdeal.receipts\nsecret',
        'peerdeal.receipts${String.fromCharCode(0x85)}',
        'x' * 129,
        'peerdeal::receipts',
      ]) {
        final secureStorage = _FakeSecureKeyStorageBridge(
          snapshot: SecureKeyStorageSnapshot(available: true, keys: []),
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

AppNativeReadinessLoader _readyLoader(SecureKeyStorageSnapshot snapshot) {
  return AppNativeReadinessLoader(
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
    secureKeyStorageBridge: _FakeSecureKeyStorageBridge(snapshot: snapshot),
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
    return NativeTransportReceiveSnapshot(available: true, frames: []);
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

class _CancellingCaptureProtectionBridge implements CaptureProtectionBridge {
  _CancellingCaptureProtectionBridge(this.cancellation);

  final Completer<void> cancellation;

  @override
  Future<CaptureProtectionCapability> getCapability() async {
    if (!cancellation.isCompleted) cancellation.complete();
    return const CaptureProtectionCapability(
      blockingSupported: true,
      obscuringSupported: true,
      notes: 'ready',
    );
  }
}

class _CountingLocalNetworkBridge extends _FakeLocalNetworkBridge {
  _CountingLocalNetworkBridge()
    : super(
        capability: const LocalNetworkCapability(
          discoverySupported: true,
          permissionPromptSupported: true,
          broadcastSupported: true,
          notes: 'ready',
        ),
      );

  int capabilityLookups = 0;

  @override
  Future<LocalNetworkCapability> getCapability() async {
    capabilityLookups += 1;
    return super.getCapability();
  }
}

class _CountingNativeTransportBridge extends _FakeNativeTransportBridge {
  _CountingNativeTransportBridge()
    : super(
        capability: const NativeTransportCapability(
          available: true,
          sendSupported: true,
          receiveSupported: true,
          maxPayloadBytes: 1024,
          notes: 'ready',
        ),
      );

  @override
  Future<NativeTransportCapability> getCapability() async {
    capabilityLookups += 1;
    return super.getCapability();
  }
}

class _CountingSecureKeyStorageBridge extends _FakeSecureKeyStorageBridge {
  _CountingSecureKeyStorageBridge()
    : super(snapshot: SecureKeyStorageSnapshot(available: true, keys: []));

  int loadLookups = 0;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    loadLookups += 1;
    return super.loadKeyRing(namespace: namespace);
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

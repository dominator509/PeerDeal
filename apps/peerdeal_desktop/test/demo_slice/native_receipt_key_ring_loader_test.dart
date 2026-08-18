import 'dart:async';

import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  test('copies and freezes receipt key-ring load warnings', () {
    final warnings = <String>['warning_1'];
    final result = ReceiptKeyRingLoadResult(
      keyRing: ReceiptKeyRingSnapshot(),
      warnings: warnings,
    );

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('bounds and scrubs direct receipt key-ring load warnings', () {
    final result = ReceiptKeyRingLoadResult(
      keyRing: ReceiptKeyRingSnapshot(),
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
      'Secure receipt key warning unavailable.',
      'Secure receipt key warning unavailable.',
      'Secure receipt key warnings truncated.',
    ]);
  });

  test('maps native secure key records into receipt key ring', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_0',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_secret_0',
            active: false,
          ),
          SecureKeyRecord(
            keyId: 'receipt_signing_1',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_secret_1',
            active: true,
          ),
          SecureKeyRecord(
            keyId: 'receipt_encryption_1',
            purpose: 'receipt_encryption',
            algorithm: 'external',
            secret: 'encryption_secret_1',
            active: true,
          ),
          SecureKeyRecord(
            keyId: 'ignored',
            purpose: 'network_bootstrap',
            algorithm: 'external',
            secret: 'ignored_secret',
            active: true,
          ),
        ],
      ),
    );

    final result = await NativeReceiptKeyRingLoader(bridge: bridge).load();

    expect(bridge.namespace, 'peerdeal.receipts');
    expect(result.warnings, isEmpty);
    expect(result.hasSigningKey, isTrue);
    expect(result.hasEncryptionKey, isTrue);
    expect(result.keyRing.activeSigningKey()!.keyId, 'receipt_signing_1');
    expect(
      result.keyRing.findSigningKey('receipt_signing_0')!.secret,
      'signing_secret_0',
    );
    expect(result.keyRing.activeEncryptionKey()!.keyId, 'receipt_encryption_1');
    expect(result.keyRing.findEncryptionKey('ignored'), isNull);
  });

  test('fails closed when native secure key storage is unavailable', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: const SecureKeyStorageSnapshot.unavailable(
        warning: 'secure storage locked',
      ),
    );

    final result = await NativeReceiptKeyRingLoader(bridge: bridge).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, [
      'Secure receipt key storage reported a platform warning.',
    ]);
    expect(result.warnings.single, isNot(contains('locked')));
  });

  test('fails closed before native load for invalid namespace', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[],
      ),
    );

    final result = await NativeReceiptKeyRingLoader(
      bridge: bridge,
      namespace: ' peerdeal.receipts',
    ).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key namespace is invalid.',
    ]);
    expect(bridge.namespace, isNull);
  });

  test(
    'fails closed before native load for C1 or byte-oversized namespace',
    () async {
      for (final namespace in <String>[
        'peerdeal${String.fromCharCode(0x85)}receipts',
        'peerdeal::receipts',
        'x' * (NativeBridgePayloadLimits.maxSecureKeyNamespaceBytes + 1),
      ]) {
        final bridge = _FakeSecureKeyStorageBridge(
          snapshot: SecureKeyStorageSnapshot(
            available: true,
            keys: <SecureKeyRecord>[],
          ),
        );

        final result = await NativeReceiptKeyRingLoader(
          bridge: bridge,
          namespace: namespace,
        ).load();

        expect(result.hasSigningKey, isFalse);
        expect(result.hasEncryptionKey, isFalse);
        expect(result.warnings, <String>[
          'Secure receipt key namespace is invalid.',
        ]);
        expect(bridge.namespace, isNull);
      }
    },
  );

  test(
    'fails closed before native load for invalid key record limits',
    () async {
      for (final maxKeyRecords in <int>[
        0,
        NativeBridgePayloadLimits.maxSecureKeyRecords + 1,
      ]) {
        final bridge = _FakeSecureKeyStorageBridge(
          snapshot: SecureKeyStorageSnapshot(
            available: true,
            keys: <SecureKeyRecord>[],
          ),
        );

        final result = await NativeReceiptKeyRingLoader(
          bridge: bridge,
          maxKeyRecords: maxKeyRecords,
        ).load();

        expect(result.hasSigningKey, isFalse);
        expect(result.hasEncryptionKey, isFalse);
        expect(result.warnings, <String>[
          'Secure receipt key record limit is invalid.',
        ]);
        expect(bridge.namespace, isNull);
      }
    },
  );

  test(
    'fails closed before native load for invalid key metadata limit',
    () async {
      final bridge = _FakeSecureKeyStorageBridge(
        snapshot: SecureKeyStorageSnapshot(
          available: true,
          keys: <SecureKeyRecord>[],
        ),
      );

      final result = await NativeReceiptKeyRingLoader(
        bridge: bridge,
        maxKeyIdLength: 0,
      ).load();

      expect(result.hasSigningKey, isFalse);
      expect(result.hasEncryptionKey, isFalse);
      expect(result.warnings, <String>[
        'Secure receipt key metadata limit is invalid.',
      ]);
      expect(bridge.namespace, isNull);
    },
  );

  test(
    'fails closed before native load for invalid key material limit',
    () async {
      final bridge = _FakeSecureKeyStorageBridge(
        snapshot: SecureKeyStorageSnapshot(
          available: true,
          keys: <SecureKeyRecord>[],
        ),
      );

      final result = await NativeReceiptKeyRingLoader(
        bridge: bridge,
        maxKeySecretLength: 0,
      ).load();

      expect(result.hasSigningKey, isFalse);
      expect(result.hasEncryptionKey, isFalse);
      expect(result.warnings, <String>[
        'Secure receipt key material limit is invalid.',
      ]);
      expect(bridge.namespace, isNull);
    },
  );

  test('fails closed when native key snapshot exceeds record limit', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          for (var index = 0; index < 3; index++)
            SecureKeyRecord(
              keyId: 'receipt_signing_$index',
              purpose: 'receipt_signing',
              algorithm: 'hmac-sha256',
              secret: 'signing_secret_$index',
              active: index == 0,
            ),
        ],
      ),
    );

    final result = await NativeReceiptKeyRingLoader(
      bridge: bridge,
      maxKeyRecords: 2,
    ).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key record limit reached.',
    ]);
    expect(bridge.namespace, 'peerdeal.receipts');
  });

  test('fails closed on invalid key snapshot revisions and records', () async {
    final snapshots = <SecureKeyStorageSnapshot>[
      SecureKeyStorageSnapshot(available: true, revision: -1, keys: const []),
      SecureKeyStorageSnapshot(
        available: true,
        keys: const <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_1',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_secret_1',
            active: true,
          ),
          SecureKeyRecord(
            keyId: 'bad:key',
            purpose: 'ignored',
            algorithm: 'external',
            secret: 'ignored_secret',
            active: false,
          ),
        ],
      ),
    ];

    final expectedWarnings = <String>[
      'Secure receipt key storage revision is invalid.',
      'Secure receipt key record metadata is invalid.',
    ];
    for (var index = 0; index < snapshots.length; index++) {
      final snapshot = snapshots[index];
      final result = await NativeReceiptKeyRingLoader(
        bridge: _FakeSecureKeyStorageBridge(snapshot: snapshot),
      ).load();

      expect(result.hasSigningKey, isFalse);
      expect(result.hasEncryptionKey, isFalse);
      expect(result.warnings, <String>[expectedWarnings[index]]);
    }
  });

  test('fails closed when native key snapshot has unsafe metadata', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_\u0001',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_secret_1',
            active: true,
          ),
        ],
      ),
    );

    final result = await NativeReceiptKeyRingLoader(bridge: bridge).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key record metadata is invalid.',
    ]);
    expect(bridge.namespace, 'peerdeal.receipts');
  });

  test('fails closed when native key ids exceed metadata limit', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_oversized',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_secret_1',
            active: true,
          ),
        ],
      ),
    );

    final result = await NativeReceiptKeyRingLoader(
      bridge: bridge,
      maxKeyIdLength: 12,
    ).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key record metadata is invalid.',
    ]);
    expect(bridge.namespace, 'peerdeal.receipts');
  });

  test('fails closed when native key snapshot has unsafe material', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_1',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_secret_\u0001',
            active: true,
          ),
        ],
      ),
    );

    final result = await NativeReceiptKeyRingLoader(bridge: bridge).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key material is invalid.',
    ]);
    expect(bridge.namespace, 'peerdeal.receipts');
  });

  test('fails closed when native key material exceeds limit', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_1',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 's'.padRight(20, 'x'),
            active: true,
          ),
        ],
      ),
    );

    final result = await NativeReceiptKeyRingLoader(
      bridge: bridge,
      maxKeySecretLength: 12,
    ).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key material is invalid.',
    ]);
    expect(bridge.namespace, 'peerdeal.receipts');
  });

  test(
    'fails closed when native storage has multiple active receipt keys',
    () async {
      final bridge = _FakeSecureKeyStorageBridge(
        snapshot: SecureKeyStorageSnapshot(
          available: true,
          keys: <SecureKeyRecord>[
            SecureKeyRecord(
              keyId: 'receipt_signing_1',
              purpose: 'receipt_signing',
              algorithm: 'hmac-sha256',
              secret: 'signing_secret_1',
              active: true,
            ),
            SecureKeyRecord(
              keyId: 'receipt_signing_2',
              purpose: 'receipt_signing',
              algorithm: 'hmac-sha256',
              secret: 'signing_secret_2',
              active: true,
            ),
            SecureKeyRecord(
              keyId: 'receipt_encryption_1',
              purpose: 'receipt_encryption',
              algorithm: 'external',
              secret: 'encryption_secret_1',
              active: true,
            ),
            SecureKeyRecord(
              keyId: 'receipt_encryption_2',
              purpose: 'receipt_encryption',
              algorithm: 'external',
              secret: 'encryption_secret_2',
              active: true,
            ),
          ],
        ),
      );

      final result = await NativeReceiptKeyRingLoader(bridge: bridge).load();

      expect(result.hasSigningKey, isFalse);
      expect(result.hasEncryptionKey, isFalse);
      expect(result.warnings, <String>[
        'Secure receipt key storage contains multiple active signing keys.',
        'Secure receipt key storage contains multiple active encryption keys.',
      ]);
    },
  );

  test('fails closed when native storage has duplicate key ids', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          const SecureKeyRecord(
            keyId: 'receipt_signing_1',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_secret_1',
            active: true,
          ),
          const SecureKeyRecord(
            keyId: 'receipt_signing_1',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'replacement_secret',
            active: false,
          ),
        ],
      ),
    );

    final result = await NativeReceiptKeyRingLoader(bridge: bridge).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key storage contains duplicate key IDs.',
    ]);
  });

  test('fails closed when native secure key storage throws', () async {
    final result = await NativeReceiptKeyRingLoader(
      bridge: _ThrowingSecureKeyStorageBridge(),
    ).load();

    expect(result.hasSigningKey, isFalse);
    expect(result.hasEncryptionKey, isFalse);
    expect(result.warnings, [
      'Secure receipt key storage could not be loaded.',
    ]);
  });

  test('forwards route cancellation to a cancellable native bridge', () async {
    final bridge = _CancellableSecureKeyStorageBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[],
      ),
    );
    final cancellation = Completer<void>();

    final result = await NativeReceiptKeyRingLoader(
      bridge: bridge,
    ).loadCancellable(cancellation: cancellation.future);

    expect(result.warnings, isEmpty);
    expect(bridge.cancellation, same(cancellation.future));
  });
}

class _FakeSecureKeyStorageBridge implements SecureKeyStorageBridge {
  _FakeSecureKeyStorageBridge({required this.snapshot});

  final SecureKeyStorageSnapshot snapshot;
  String? namespace;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    this.namespace = namespace;
    return snapshot;
  }
}

class _ThrowingSecureKeyStorageBridge implements SecureKeyStorageBridge {
  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    throw StateError('secure storage unavailable');
  }
}

class _CancellableSecureKeyStorageBridge
    implements SecureKeyStorageBridge, CancellableSecureKeyStorageBridge {
  _CancellableSecureKeyStorageBridge({required this.snapshot});

  final SecureKeyStorageSnapshot snapshot;
  Future<void>? cancellation;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
    Future<void>? cancellation,
  }) async {
    this.cancellation = cancellation;
    return snapshot;
  }
}

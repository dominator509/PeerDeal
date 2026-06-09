import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test('maps native secure key records into receipt key ring', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: const SecureKeyStorageSnapshot(
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
      snapshot: const SecureKeyStorageSnapshot(
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
    'fails closed before native load for invalid key record limit',
    () async {
      final bridge = _FakeSecureKeyStorageBridge(
        snapshot: const SecureKeyStorageSnapshot(
          available: true,
          keys: <SecureKeyRecord>[],
        ),
      );

      final result = await NativeReceiptKeyRingLoader(
        bridge: bridge,
        maxKeyRecords: 0,
      ).load();

      expect(result.hasSigningKey, isFalse);
      expect(result.hasEncryptionKey, isFalse);
      expect(result.warnings, <String>[
        'Secure receipt key record limit is invalid.',
      ]);
      expect(bridge.namespace, isNull);
    },
  );

  test(
    'fails closed before native load for invalid key metadata limit',
    () async {
      final bridge = _FakeSecureKeyStorageBridge(
        snapshot: const SecureKeyStorageSnapshot(
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
        snapshot: const SecureKeyStorageSnapshot(
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

  test('fails closed when native key snapshot has unsafe metadata', () async {
    final bridge = _FakeSecureKeyStorageBridge(
      snapshot: const SecureKeyStorageSnapshot(
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
      snapshot: const SecureKeyStorageSnapshot(
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
      snapshot: const SecureKeyStorageSnapshot(
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
        snapshot: const SecureKeyStorageSnapshot(
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

import 'dart:async';

import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_key_ring_provisioner.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_key_ring_writer.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test('keeps existing active receipt keys without native writes', () async {
    final bridge = _ProvisioningBridge(
      snapshot: const SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_existing',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing',
            active: true,
          ),
          SecureKeyRecord(
            keyId: 'receipt_encryption_existing',
            purpose: 'receipt_encryption',
            algorithm: 'external',
            secret: 'encryption',
            active: true,
          ),
        ],
      ),
    );
    final provisioner = _provisioner(bridge);

    final result = await provisioner.ensureActiveKeys();

    expect(result.isSuccess, isTrue);
    expect(result.keysCreated, 0);
    expect(bridge.savedKeys, isEmpty);
    expect(
      result.keyRing.activeSigningKey()!.keyId,
      'receipt_signing_existing',
    );
    expect(
      result.keyRing.activeEncryptionKey()!.keyId,
      'receipt_encryption_existing',
    );
  });

  test('creates missing active signing and encryption keys', () async {
    final bridge = _ProvisioningBridge();
    final provisioner = _provisioner(bridge);

    final result = await provisioner.ensureActiveKeys();

    expect(result.isSuccess, isTrue);
    expect(result.keysCreated, 2);
    expect(bridge.savedKeys, hasLength(2));
    expect(bridge.savedKeys[0].key.keyId, 'receipt_signing_test');
    expect(bridge.savedKeys[0].key.secret, 'secret_0');
    expect(bridge.savedKeys[0].key.active, isTrue);
    expect(bridge.savedKeys[1].key.keyId, 'receipt_encryption_test');
    expect(bridge.savedKeys[1].key.secret, 'secret_1');
    expect(result.keyRing.activeSigningKey()!.keyId, 'receipt_signing_test');
    expect(
      result.keyRing.activeEncryptionKey()!.keyId,
      'receipt_encryption_test',
    );
  });

  test('single-flights concurrent key provisioning', () async {
    final gate = Completer<void>();
    final bridge = _ProvisioningBridge(loadGate: gate);
    final provisioner = _provisioner(bridge);

    final first = provisioner.ensureActiveKeys();
    final second = provisioner.ensureActiveKeys();

    expect(identical(first, second), isTrue);
    expect(bridge.loadCalls, 1);

    gate.complete();
    final results = await Future.wait(<Future<ReceiptKeyRingProvisionResult>>[
      first,
      second,
    ]);

    expect(results[0], same(results[1]));
    expect(bridge.savedKeys, hasLength(2));
  });

  test('creates only the missing active encryption key', () async {
    final bridge = _ProvisioningBridge(
      snapshot: const SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_existing',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing',
            active: true,
          ),
        ],
      ),
    );
    final provisioner = _provisioner(bridge);

    final result = await provisioner.ensureActiveKeys();

    expect(result.isSuccess, isTrue);
    expect(result.keysCreated, 1);
    expect(bridge.savedKeys.single.key.purpose, 'receipt_encryption');
    expect(
      result.keyRing.activeSigningKey()!.keyId,
      'receipt_signing_existing',
    );
    expect(
      result.keyRing.activeEncryptionKey()!.keyId,
      'receipt_encryption_test',
    );
  });

  test('fails closed when native key-ring loading is unavailable', () async {
    final bridge = _ProvisioningBridge(
      snapshot: const SecureKeyStorageSnapshot.unavailable(
        warning: 'secure storage locked',
      ),
    );
    final provisioner = _provisioner(bridge);

    final result = await provisioner.ensureActiveKeys();

    expect(result.isSuccess, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key storage reported a platform warning.',
    ]);
    expect(result.keysCreated, 0);
    expect(bridge.savedKeys, isEmpty);
  });

  test('does not provision over ambiguous active native keys', () async {
    final bridge = _ProvisioningBridge(
      snapshot: const SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'receipt_signing_1',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_1',
            active: true,
          ),
          SecureKeyRecord(
            keyId: 'receipt_signing_2',
            purpose: 'receipt_signing',
            algorithm: 'hmac-sha256',
            secret: 'signing_2',
            active: true,
          ),
        ],
      ),
    );
    final provisioner = _provisioner(bridge);

    final result = await provisioner.ensureActiveKeys();

    expect(result.isSuccess, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key storage contains multiple active signing keys.',
    ]);
    expect(result.keysCreated, 0);
    expect(bridge.savedKeys, isEmpty);
  });

  test('fails closed when native key save fails', () async {
    final bridge = _ProvisioningBridge(
      saveResult: const SecureKeyStorageMutationResult.failure(
        warning: 'secure key save denied',
      ),
    );
    final provisioner = _provisioner(bridge);

    final result = await provisioner.ensureActiveKeys();

    expect(result.isSuccess, isFalse);
    expect(result.warnings, <String>[
      'Secure receipt key storage reported a platform warning.',
    ]);
    expect(result.keysCreated, 0);
    expect(bridge.savedKeys.single.key.purpose, 'receipt_signing');
  });

  test('fails closed when signing key factories throw', () async {
    final bridge = _ProvisioningBridge();
    final provisioner = NativeReceiptKeyRingProvisioner(
      loader: NativeReceiptKeyRingLoader(bridge: bridge),
      writer: NativeReceiptKeyRingWriter(bridge: bridge),
      secretFactory: () => throw StateError('secret failed'),
      keyIdFactory: (purpose) => '${purpose}_test',
    );

    final result = await provisioner.ensureActiveKeys();

    expect(result.isSuccess, isFalse);
    expect(result.warnings, <String>[
      'Receipt signing key provisioning failed.',
    ]);
    expect(result.keysCreated, 0);
    expect(bridge.savedKeys, isEmpty);
  });

  test('fails closed when encryption key factories throw', () async {
    var secretIndex = 0;
    final bridge = _ProvisioningBridge();
    final provisioner = NativeReceiptKeyRingProvisioner(
      loader: NativeReceiptKeyRingLoader(bridge: bridge),
      writer: NativeReceiptKeyRingWriter(bridge: bridge),
      secretFactory: () {
        if (secretIndex++ == 0) return 'secret_0';
        throw StateError('secret failed');
      },
      keyIdFactory: (purpose) => '${purpose}_test',
    );

    final result = await provisioner.ensureActiveKeys();

    expect(result.isSuccess, isFalse);
    expect(result.warnings, <String>[
      'Receipt encryption key provisioning failed.',
    ]);
    expect(result.keysCreated, 1);
    expect(bridge.savedKeys.single.key.purpose, 'receipt_signing');
  });
}

NativeReceiptKeyRingProvisioner _provisioner(_ProvisioningBridge bridge) {
  var secretIndex = 0;
  return NativeReceiptKeyRingProvisioner(
    loader: NativeReceiptKeyRingLoader(bridge: bridge),
    writer: NativeReceiptKeyRingWriter(bridge: bridge),
    secretFactory: () => 'secret_${secretIndex++}',
    keyIdFactory: (purpose) => '${purpose}_test',
  );
}

class _ProvisioningBridge implements SecureKeyStorageMutationBridge {
  _ProvisioningBridge({
    this.snapshot = const SecureKeyStorageSnapshot(available: true, keys: []),
    this.saveResult = const SecureKeyStorageMutationResult(isSuccess: true),
    this.loadGate,
  });

  final SecureKeyStorageSnapshot snapshot;
  final SecureKeyStorageMutationResult saveResult;
  final Completer<void>? loadGate;
  final List<_SavedKey> savedKeys = <_SavedKey>[];
  int loadCalls = 0;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    loadCalls += 1;
    final loadGate = this.loadGate;
    if (loadGate != null) await loadGate.future;
    return snapshot;
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
  }) async {
    savedKeys.add(_SavedKey(namespace: namespace, key: key));
    return saveResult;
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
  }) async {
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }
}

class _SavedKey {
  const _SavedKey({required this.namespace, required this.key});

  final String namespace;
  final SecureKeyRecord key;
}

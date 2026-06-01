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
    expect(result.warnings, ['secure storage locked']);
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

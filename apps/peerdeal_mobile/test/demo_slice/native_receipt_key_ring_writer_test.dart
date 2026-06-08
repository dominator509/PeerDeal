import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_key_ring_writer.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  test('maps receipt signing keys into generic secure key records', () async {
    final bridge = _RecordingSecureKeyStorageBridge();
    final writer = NativeReceiptKeyRingWriter(bridge: bridge);

    final result = await writer.saveSigningKey(
      const ReceiptSigningKey(keyId: 'receipt_signing_1', secret: 'signing'),
      active: true,
    );

    expect(result.isSuccess, isTrue);
    expect(bridge.savedKeys.single.namespace, 'peerdeal.receipts');
    expect(bridge.savedKeys.single.key.keyId, 'receipt_signing_1');
    expect(bridge.savedKeys.single.key.purpose, 'receipt_signing');
    expect(bridge.savedKeys.single.key.algorithm, 'hmac-sha256');
    expect(bridge.savedKeys.single.key.secret, 'signing');
    expect(bridge.savedKeys.single.key.active, isTrue);
  });

  test(
    'maps receipt encryption keys into generic secure key records',
    () async {
      final bridge = _RecordingSecureKeyStorageBridge();
      final writer = NativeReceiptKeyRingWriter(bridge: bridge);

      final result = await writer.saveEncryptionKey(
        const ReceiptEncryptionKey(
          keyId: 'receipt_encryption_1',
          secret: 'enc',
        ),
        active: false,
      );

      expect(result.isSuccess, isTrue);
      expect(bridge.savedKeys.single.key.purpose, 'receipt_encryption');
      expect(bridge.savedKeys.single.key.algorithm, 'external');
      expect(bridge.savedKeys.single.key.active, isFalse);
    },
  );

  test('fails closed before native save for invalid receipt keys', () async {
    final bridge = _RecordingSecureKeyStorageBridge();
    final writer = NativeReceiptKeyRingWriter(bridge: bridge);

    final result = await writer.saveSigningKey(
      const ReceiptSigningKey(keyId: 'bad:key', secret: 'signing'),
      active: true,
    );

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Receipt key save request is invalid.');
    expect(bridge.savedKeys, isEmpty);
  });

  test('fails closed before native save for invalid namespace', () async {
    final bridge = _RecordingSecureKeyStorageBridge();
    final writer = NativeReceiptKeyRingWriter(
      bridge: bridge,
      namespace: 'peerdeal.receipts ',
    );

    final result = await writer.saveSigningKey(
      const ReceiptSigningKey(keyId: 'receipt_signing_1', secret: 'signing'),
      active: true,
    );

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Secure receipt key namespace is invalid.');
    expect(bridge.savedKeys, isEmpty);
  });

  test('propagates native mutation failure without throwing', () async {
    final bridge = _RecordingSecureKeyStorageBridge(
      saveResult: const SecureKeyStorageMutationResult.failure(
        warning: 'secure storage locked',
      ),
    );
    final writer = NativeReceiptKeyRingWriter(bridge: bridge);

    final result = await writer.saveEncryptionKey(
      const ReceiptEncryptionKey(keyId: 'receipt_encryption_1', secret: 'enc'),
      active: true,
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.warning,
      'Secure receipt key storage reported a platform warning.',
    );
    expect(result.warning, isNot(contains('locked')));
  });

  test('fails closed when native save throws', () async {
    final writer = NativeReceiptKeyRingWriter(
      bridge: _ThrowingSecureKeyStorageBridge(),
    );

    final result = await writer.saveSigningKey(
      const ReceiptSigningKey(keyId: 'receipt_signing_1', secret: 'signing'),
      active: true,
    );

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Secure receipt key save failed.');
  });

  test('deletes receipt keys through generic secure key mutation', () async {
    final bridge = _RecordingSecureKeyStorageBridge();
    final writer = NativeReceiptKeyRingWriter(bridge: bridge);

    final result = await writer.deleteKey('receipt_signing_1');

    expect(result.isSuccess, isTrue);
    expect(bridge.deletedKeys.single.namespace, 'peerdeal.receipts');
    expect(bridge.deletedKeys.single.keyId, 'receipt_signing_1');
  });

  test('fails closed before native delete for invalid key ids', () async {
    final bridge = _RecordingSecureKeyStorageBridge();
    final writer = NativeReceiptKeyRingWriter(bridge: bridge);

    final result = await writer.deleteKey('bad:key');

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Receipt key delete request is invalid.');
    expect(bridge.deletedKeys, isEmpty);
  });

  test('fails closed before native delete for invalid namespace', () async {
    final bridge = _RecordingSecureKeyStorageBridge();
    final writer = NativeReceiptKeyRingWriter(bridge: bridge, namespace: '');

    final result = await writer.deleteKey('receipt_signing_1');

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Secure receipt key namespace is invalid.');
    expect(bridge.deletedKeys, isEmpty);
  });
}

class _RecordingSecureKeyStorageBridge
    implements SecureKeyStorageMutationBridge {
  _RecordingSecureKeyStorageBridge({
    this.saveResult = const SecureKeyStorageMutationResult(isSuccess: true),
  });

  final SecureKeyStorageMutationResult saveResult;
  final List<_SavedKey> savedKeys = <_SavedKey>[];
  final List<_DeletedKey> deletedKeys = <_DeletedKey>[];

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    return const SecureKeyStorageSnapshot(available: true, keys: []);
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
    deletedKeys.add(_DeletedKey(namespace: namespace, keyId: keyId));
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }
}

class _ThrowingSecureKeyStorageBridge
    implements SecureKeyStorageMutationBridge {
  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    throw StateError('load failed');
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
  }) async {
    throw StateError('save failed');
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
  }) async {
    throw StateError('delete failed');
  }
}

class _SavedKey {
  const _SavedKey({required this.namespace, required this.key});

  final String namespace;
  final SecureKeyRecord key;
}

class _DeletedKey {
  const _DeletedKey({required this.namespace, required this.keyId});

  final String namespace;
  final String keyId;
}

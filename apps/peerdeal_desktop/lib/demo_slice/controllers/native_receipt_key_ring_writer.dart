import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'native_receipt_key_ring_loader.dart';

class ReceiptKeyRingWriteResult {
  const ReceiptKeyRingWriteResult({required this.isSuccess, this.warning});

  const ReceiptKeyRingWriteResult.success() : isSuccess = true, warning = null;

  const ReceiptKeyRingWriteResult.failure({required this.warning})
    : isSuccess = false;

  final bool isSuccess;
  final String? warning;
}

class NativeReceiptKeyRingWriter {
  const NativeReceiptKeyRingWriter({
    required SecureKeyStorageMutationBridge bridge,
    this.namespace = NativeReceiptKeyRingLoader.defaultNamespace,
  }) : _bridge = bridge;

  final SecureKeyStorageMutationBridge _bridge;
  final String namespace;

  Future<ReceiptKeyRingWriteResult> saveSigningKey(
    ReceiptSigningKey key, {
    required bool active,
  }) {
    return _save(
      SecureKeyRecord(
        keyId: key.keyId,
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: key.secret,
        active: active,
      ),
    );
  }

  Future<ReceiptKeyRingWriteResult> saveEncryptionKey(
    ReceiptEncryptionKey key, {
    required bool active,
  }) {
    return _save(
      SecureKeyRecord(
        keyId: key.keyId,
        purpose: 'receipt_encryption',
        algorithm: 'external',
        secret: key.secret,
        active: active,
      ),
    );
  }

  Future<ReceiptKeyRingWriteResult> deleteKey(String keyId) async {
    if (keyId.trim().isEmpty || keyId.contains(':')) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Receipt key delete request is invalid.',
      );
    }

    final SecureKeyStorageMutationResult result;
    try {
      result = await _bridge.deleteKey(namespace: namespace, keyId: keyId);
    } on Object {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Secure receipt key delete failed.',
      );
    }

    return _fromNativeMutation(result);
  }

  Future<ReceiptKeyRingWriteResult> _save(SecureKeyRecord record) async {
    if (!record.isUsable) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Receipt key save request is invalid.',
      );
    }

    final SecureKeyStorageMutationResult result;
    try {
      result = await _bridge.saveKey(namespace: namespace, key: record);
    } on Object {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Secure receipt key save failed.',
      );
    }

    return _fromNativeMutation(result);
  }

  ReceiptKeyRingWriteResult _fromNativeMutation(
    SecureKeyStorageMutationResult result,
  ) {
    if (result.isSuccess) return const ReceiptKeyRingWriteResult.success();
    return ReceiptKeyRingWriteResult.failure(
      warning: result.warning ?? 'Secure receipt key mutation failed.',
    );
  }
}

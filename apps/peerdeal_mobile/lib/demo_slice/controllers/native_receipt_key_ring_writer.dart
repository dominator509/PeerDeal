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
    this.maxKeyIdLength = 96,
    this.maxKeySecretLength = 256,
  }) : _bridge = bridge;

  final SecureKeyStorageMutationBridge _bridge;
  final String namespace;
  final int maxKeyIdLength;
  final int maxKeySecretLength;

  Future<ReceiptKeyRingWriteResult> saveSigningKey(
    ReceiptSigningKey key, {
    required bool active,
    Future<void>? cancellation,
  }) {
    return _save(
      SecureKeyRecord(
        keyId: key.keyId,
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: key.secret,
        active: active,
      ),
      cancellation: cancellation,
    );
  }

  Future<ReceiptKeyRingWriteResult> saveEncryptionKey(
    ReceiptEncryptionKey key, {
    required bool active,
    Future<void>? cancellation,
  }) {
    return _save(
      SecureKeyRecord(
        keyId: key.keyId,
        purpose: 'receipt_encryption',
        algorithm: 'external',
        secret: key.secret,
        active: active,
      ),
      cancellation: cancellation,
    );
  }

  Future<ReceiptKeyRingWriteResult> deleteKey(
    String keyId, {
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace)) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Secure receipt key namespace is invalid.',
      );
    }
    if (!_isValidKeyId(keyId, maxKeyIdLength)) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Receipt key delete request is invalid.',
      );
    }

    final SecureKeyStorageMutationResult result;
    try {
      result = _bridge is CancellableSecureKeyStorageMutationBridge
          ? await (_bridge as CancellableSecureKeyStorageMutationBridge)
                .deleteKey(
                  namespace: namespace,
                  keyId: keyId,
                  cancellation: cancellation,
                )
          : await _bridge.deleteKey(namespace: namespace, keyId: keyId);
    } on Object {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Secure receipt key delete failed.',
      );
    }

    return _fromNativeMutation(result);
  }

  Future<ReceiptKeyRingWriteResult> _save(
    SecureKeyRecord record, {
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace)) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Secure receipt key namespace is invalid.',
      );
    }
    if (!record.isUsable ||
        !_isValidKeyId(record.keyId, maxKeyIdLength) ||
        !_isValidSecret(record.secret, maxKeySecretLength)) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Receipt key save request is invalid.',
      );
    }

    final SecureKeyStorageMutationResult result;
    try {
      result = _bridge is CancellableSecureKeyStorageMutationBridge
          ? await (_bridge as CancellableSecureKeyStorageMutationBridge)
                .saveKey(
                  namespace: namespace,
                  key: record,
                  cancellation: cancellation,
                )
          : await _bridge.saveKey(namespace: namespace, key: record);
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
      warning: _safeNativeWarning(
        result.warning,
        fallback: 'Secure receipt key mutation failed.',
      ),
    );
  }

  static bool _isValidNamespace(String namespace) =>
      namespace.trim().isNotEmpty && namespace.trim() == namespace;

  static bool _isValidKeyId(String keyId, int maxLength) =>
      maxLength > 0 &&
      keyId.length <= maxLength &&
      keyId.trim().isNotEmpty &&
      keyId.trim() == keyId &&
      !keyId.contains(':') &&
      !_hasControlCharacter(keyId);

  static bool _isValidSecret(String secret, int maxLength) =>
      maxLength > 0 &&
      secret.length <= maxLength &&
      secret.trim().isNotEmpty &&
      secret.trim() == secret &&
      !_hasControlCharacter(secret);

  static bool _hasControlCharacter(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit < 0x20 || codeUnit == 0x7F) {
        return true;
      }
    }
    return false;
  }

  static String _safeNativeWarning(
    String? warning, {
    required String fallback,
  }) {
    if (warning == null || warning.trim().isEmpty) {
      return fallback;
    }
    return 'Secure receipt key storage reported a platform warning.';
  }
}

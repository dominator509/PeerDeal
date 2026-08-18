import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'native_receipt_key_ring_loader.dart';

class ReceiptKeyRingWriteResult {
  const ReceiptKeyRingWriteResult({
    required this.isSuccess,
    this.warning,
    this.revision,
    this.isConflict = false,
  });

  const ReceiptKeyRingWriteResult.success({this.revision})
    : isSuccess = true,
      warning = null,
      isConflict = false;

  const ReceiptKeyRingWriteResult.failure({
    required this.warning,
    this.revision,
    this.isConflict = false,
  }) : isSuccess = false;

  final bool isSuccess;
  final String? warning;
  final int? revision;
  final bool isConflict;
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
    int? expectedRevision,
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
      expectedRevision: expectedRevision,
      cancellation: cancellation,
    );
  }

  Future<ReceiptKeyRingWriteResult> saveEncryptionKey(
    ReceiptEncryptionKey key, {
    required bool active,
    int? expectedRevision,
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
      expectedRevision: expectedRevision,
      cancellation: cancellation,
    );
  }

  Future<ReceiptKeyRingWriteResult> deleteKey(
    String keyId, {
    int? expectedRevision,
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
    if (!_isValidRevision(expectedRevision)) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Receipt key delete request is invalid.',
      );
    }

    final usesConditionalMutation =
        expectedRevision != null &&
        _bridge is ConditionalSecureKeyStorageMutationBridge;
    final SecureKeyStorageMutationResult result;
    try {
      result =
          expectedRevision != null &&
              _bridge is CancellableConditionalSecureKeyStorageMutationBridge
          ? await (_bridge
                    as CancellableConditionalSecureKeyStorageMutationBridge)
                .deleteKeyIfRevision(
                  namespace: namespace,
                  keyId: keyId,
                  expectedRevision: expectedRevision,
                  cancellation: cancellation,
                )
          : expectedRevision != null &&
                _bridge is ConditionalSecureKeyStorageMutationBridge
          ? await (_bridge as ConditionalSecureKeyStorageMutationBridge)
                .deleteKeyIfRevision(
                  namespace: namespace,
                  keyId: keyId,
                  expectedRevision: expectedRevision,
                )
          : _bridge is CancellableSecureKeyStorageMutationBridge
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

    return _fromNativeMutation(
      result,
      expectedRevision: usesConditionalMutation ? expectedRevision : null,
    );
  }

  Future<ReceiptKeyRingWriteResult> _save(
    SecureKeyRecord record, {
    int? expectedRevision,
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace)) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Secure receipt key namespace is invalid.',
      );
    }
    if (!record.isUsable ||
        !_isValidKeyId(record.keyId, maxKeyIdLength) ||
        !_isValidSecret(record.secret, maxKeySecretLength) ||
        !_isValidRevision(expectedRevision)) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Receipt key save request is invalid.',
      );
    }

    final usesConditionalMutation =
        expectedRevision != null &&
        _bridge is ConditionalSecureKeyStorageMutationBridge;
    final SecureKeyStorageMutationResult result;
    try {
      result =
          expectedRevision != null &&
              _bridge is CancellableConditionalSecureKeyStorageMutationBridge
          ? await (_bridge
                    as CancellableConditionalSecureKeyStorageMutationBridge)
                .saveKeyIfRevision(
                  namespace: namespace,
                  key: record,
                  expectedRevision: expectedRevision,
                  cancellation: cancellation,
                )
          : expectedRevision != null &&
                _bridge is ConditionalSecureKeyStorageMutationBridge
          ? await (_bridge as ConditionalSecureKeyStorageMutationBridge)
                .saveKeyIfRevision(
                  namespace: namespace,
                  key: record,
                  expectedRevision: expectedRevision,
                )
          : _bridge is CancellableSecureKeyStorageMutationBridge
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

    return _fromNativeMutation(
      result,
      expectedRevision: usesConditionalMutation ? expectedRevision : null,
    );
  }

  ReceiptKeyRingWriteResult _fromNativeMutation(
    SecureKeyStorageMutationResult result, {
    int? expectedRevision,
  }) {
    if (!_isValidRevision(result.revision) ||
        _isRevisionBeforeExpected(result.revision, expectedRevision)) {
      return const ReceiptKeyRingWriteResult.failure(
        warning: 'Secure receipt key mutation failed.',
      );
    }
    if (result.isSuccess) {
      return ReceiptKeyRingWriteResult.success(revision: result.revision);
    }
    return ReceiptKeyRingWriteResult.failure(
      warning: _safeNativeWarning(
        result.warning,
        fallback: 'Secure receipt key mutation failed.',
      ),
      revision: result.revision,
      isConflict: result.isConflict,
    );
  }

  static bool _isValidNamespace(String namespace) =>
      NativeBridgePayloadLimits.isSafeUtf8Text(
        namespace,
        NativeBridgePayloadLimits.maxSecureKeyNamespaceBytes,
      ) &&
      !namespace.contains('::');

  static bool _isValidKeyId(String keyId, int maxLength) =>
      maxLength > 0 &&
      keyId.length <= maxLength &&
      NativeBridgePayloadLimits.isSafeUtf8Text(
        keyId,
        NativeBridgePayloadLimits.maxSecureKeyIdBytes,
      ) &&
      !keyId.contains(':') &&
      keyId.isNotEmpty;

  static bool _isValidSecret(String secret, int maxLength) =>
      maxLength > 0 &&
      secret.length <= maxLength &&
      NativeBridgePayloadLimits.isSafeUtf8Text(
        secret,
        NativeBridgePayloadLimits.maxSecureKeySecretBytes,
      );

  static bool _isValidRevision(int? value) => value == null || value >= 0;

  static bool _isRevisionBeforeExpected(int? revision, int? expectedRevision) {
    return revision != null &&
        expectedRevision != null &&
        revision < expectedRevision;
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

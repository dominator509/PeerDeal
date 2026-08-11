import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

class ReceiptKeyRingLoadResult {
  const ReceiptKeyRingLoadResult({
    required this.keyRing,
    this.warnings = const <String>[],
  });

  final ReceiptKeyRingSnapshot keyRing;
  final List<String> warnings;

  bool get hasSigningKey => keyRing.activeSigningKey() != null;
  bool get hasEncryptionKey => keyRing.activeEncryptionKey() != null;
}

/// Optional route-lifecycle cancellation capability for native key loads.
///
/// The existing [load] method remains unchanged so callers that do not own a
/// cancellation lifecycle keep the same contract.
abstract interface class CancellableNativeReceiptKeyRingLoader {
  Future<ReceiptKeyRingLoadResult> loadCancellable({
    Future<void>? cancellation,
  });
}

class NativeReceiptKeyRingLoader
    implements CancellableNativeReceiptKeyRingLoader {
  static const defaultNamespace = 'peerdeal.receipts';

  const NativeReceiptKeyRingLoader({
    required SecureKeyStorageBridge bridge,
    this.namespace = defaultNamespace,
    this.maxKeyRecords = 64,
    this.maxKeyIdLength = 96,
    this.maxKeySecretLength = 256,
  }) : _bridge = bridge;

  final SecureKeyStorageBridge _bridge;
  final String namespace;
  final int maxKeyRecords;
  final int maxKeyIdLength;
  final int maxKeySecretLength;

  Future<ReceiptKeyRingLoadResult> load() async {
    return _load();
  }

  @override
  Future<ReceiptKeyRingLoadResult> loadCancellable({
    Future<void>? cancellation,
  }) {
    return _load(cancellation: cancellation);
  }

  Future<ReceiptKeyRingLoadResult> _load({Future<void>? cancellation}) async {
    if (!_isValidNamespace(namespace)) {
      return const ReceiptKeyRingLoadResult(
        keyRing: ReceiptKeyRingSnapshot(),
        warnings: <String>['Secure receipt key namespace is invalid.'],
      );
    }
    if (maxKeyRecords < 1) {
      return const ReceiptKeyRingLoadResult(
        keyRing: ReceiptKeyRingSnapshot(),
        warnings: <String>['Secure receipt key record limit is invalid.'],
      );
    }
    if (maxKeyIdLength < 1) {
      return const ReceiptKeyRingLoadResult(
        keyRing: ReceiptKeyRingSnapshot(),
        warnings: <String>['Secure receipt key metadata limit is invalid.'],
      );
    }
    if (maxKeySecretLength < 1) {
      return const ReceiptKeyRingLoadResult(
        keyRing: ReceiptKeyRingSnapshot(),
        warnings: <String>['Secure receipt key material limit is invalid.'],
      );
    }

    final SecureKeyStorageSnapshot snapshot;
    try {
      snapshot = _bridge is CancellableSecureKeyStorageBridge
          ? await (_bridge as CancellableSecureKeyStorageBridge).loadKeyRing(
              namespace: namespace,
              cancellation: cancellation,
            )
          : await _bridge.loadKeyRing(namespace: namespace);
    } on Object {
      return const ReceiptKeyRingLoadResult(
        keyRing: ReceiptKeyRingSnapshot(),
        warnings: <String>['Secure receipt key storage could not be loaded.'],
      );
    }

    if (!snapshot.available) {
      return ReceiptKeyRingLoadResult(
        keyRing: const ReceiptKeyRingSnapshot(),
        warnings: <String>[
          _safeNativeWarning(
            snapshot.warning,
            fallback: 'Secure receipt key storage is unavailable.',
          ),
        ],
      );
    }
    if (snapshot.keys.length > maxKeyRecords) {
      return const ReceiptKeyRingLoadResult(
        keyRing: ReceiptKeyRingSnapshot(),
        warnings: <String>['Secure receipt key record limit reached.'],
      );
    }
    if (snapshot.keys.any((record) => !_isValidKeyId(record.keyId))) {
      return const ReceiptKeyRingLoadResult(
        keyRing: ReceiptKeyRingSnapshot(),
        warnings: <String>['Secure receipt key record metadata is invalid.'],
      );
    }
    if (snapshot.keys.any((record) => !_isValidSecret(record.secret))) {
      return const ReceiptKeyRingLoadResult(
        keyRing: ReceiptKeyRingSnapshot(),
        warnings: <String>['Secure receipt key material is invalid.'],
      );
    }

    final signingRecords = _recordsFor(
      snapshot.keys,
      purpose: 'receipt_signing',
      algorithm: 'hmac-sha256',
    );
    final encryptionRecords = _recordsFor(
      snapshot.keys,
      purpose: 'receipt_encryption',
      algorithm: 'external',
    );
    final warnings = _activeKeyWarnings(
      signingRecords: signingRecords,
      encryptionRecords: encryptionRecords,
    );
    if (warnings.isNotEmpty) {
      return ReceiptKeyRingLoadResult(
        keyRing: const ReceiptKeyRingSnapshot(),
        warnings: warnings,
      );
    }

    return ReceiptKeyRingLoadResult(
      keyRing: ReceiptKeyRingSnapshot(
        activeSigning: _activeSigningKey(signingRecords),
        verificationSigningKeys: _rotatedSigningKeys(signingRecords),
        activeEncryption: _activeEncryptionKey(encryptionRecords),
        decryptionKeys: _rotatedEncryptionKeys(encryptionRecords),
      ),
    );
  }

  List<SecureKeyRecord> _recordsFor(
    List<SecureKeyRecord> records, {
    required String purpose,
    required String algorithm,
  }) {
    final filtered =
        records
            .where(
              (record) =>
                  record.isUsable &&
                  record.purpose == purpose &&
                  record.algorithm == algorithm,
            )
            .toList()
          ..sort((left, right) => left.keyId.compareTo(right.keyId));
    return filtered;
  }

  List<String> _activeKeyWarnings({
    required List<SecureKeyRecord> signingRecords,
    required List<SecureKeyRecord> encryptionRecords,
  }) {
    final warnings = <String>[];
    if (signingRecords.where((record) => record.active).length > 1) {
      warnings.add(
        'Secure receipt key storage contains multiple active signing keys.',
      );
    }
    if (encryptionRecords.where((record) => record.active).length > 1) {
      warnings.add(
        'Secure receipt key storage contains multiple active encryption keys.',
      );
    }
    return warnings;
  }

  static bool _isValidNamespace(String namespace) =>
      namespace.trim().isNotEmpty && namespace.trim() == namespace;

  bool _isValidKeyId(String keyId) =>
      keyId.length <= maxKeyIdLength &&
      keyId.trim().isNotEmpty &&
      keyId.trim() == keyId &&
      !keyId.contains(':') &&
      !_hasControlCharacter(keyId);

  bool _isValidSecret(String secret) =>
      secret.length <= maxKeySecretLength &&
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

  ReceiptSigningKey? _activeSigningKey(List<SecureKeyRecord> records) {
    for (final record in records.where((record) => record.active)) {
      return ReceiptSigningKey(keyId: record.keyId, secret: record.secret);
    }
    return null;
  }

  List<ReceiptSigningKey> _rotatedSigningKeys(List<SecureKeyRecord> records) {
    return records
        .where((record) => !record.active)
        .map(
          (record) =>
              ReceiptSigningKey(keyId: record.keyId, secret: record.secret),
        )
        .toList(growable: false);
  }

  ReceiptEncryptionKey? _activeEncryptionKey(List<SecureKeyRecord> records) {
    for (final record in records.where((record) => record.active)) {
      return ReceiptEncryptionKey(keyId: record.keyId, secret: record.secret);
    }
    return null;
  }

  List<ReceiptEncryptionKey> _rotatedEncryptionKeys(
    List<SecureKeyRecord> records,
  ) {
    return records
        .where((record) => !record.active)
        .map(
          (record) =>
              ReceiptEncryptionKey(keyId: record.keyId, secret: record.secret),
        )
        .toList(growable: false);
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

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

class NativeReceiptKeyRingLoader {
  const NativeReceiptKeyRingLoader({
    required SecureKeyStorageBridge bridge,
    this.namespace = 'peerdeal.receipts',
  }) : _bridge = bridge;

  final SecureKeyStorageBridge _bridge;
  final String namespace;

  Future<ReceiptKeyRingLoadResult> load() async {
    final snapshot = await _bridge.loadKeyRing(namespace: namespace);
    if (!snapshot.available) {
      return ReceiptKeyRingLoadResult(
        keyRing: const ReceiptKeyRingSnapshot(),
        warnings: <String>[
          snapshot.warning ?? 'Secure receipt key storage is unavailable.',
        ],
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
}

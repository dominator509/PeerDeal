import '../contracts/receipt_encryption_key_provider.dart';
import '../contracts/receipt_signing_key_provider.dart';
import '../models/receipt_encryption_key.dart';
import '../models/receipt_signing_key.dart';

class ReceiptKeyRingSnapshot
    implements ReceiptSigningKeyProvider, ReceiptEncryptionKeyProvider {
  const ReceiptKeyRingSnapshot({
    this.activeSigning,
    this.verificationSigningKeys = const <ReceiptSigningKey>[],
    this.activeEncryption,
    this.decryptionKeys = const <ReceiptEncryptionKey>[],
  });

  final ReceiptSigningKey? activeSigning;
  final List<ReceiptSigningKey> verificationSigningKeys;
  final ReceiptEncryptionKey? activeEncryption;
  final List<ReceiptEncryptionKey> decryptionKeys;

  @override
  ReceiptSigningKey? activeSigningKey() {
    final key = activeSigning;
    return key != null && key.isUsable ? key : null;
  }

  @override
  ReceiptSigningKey? findSigningKey(String keyId) {
    final active = activeSigning;
    if (active != null && active.keyId == keyId && active.isUsable) {
      return active;
    }

    for (final key in verificationSigningKeys) {
      if (key.keyId == keyId && key.isUsable) {
        return key;
      }
    }

    return null;
  }

  @override
  ReceiptEncryptionKey? activeEncryptionKey() {
    final key = activeEncryption;
    return key != null && key.isUsable ? key : null;
  }

  @override
  ReceiptEncryptionKey? findEncryptionKey(String keyId) {
    final active = activeEncryption;
    if (active != null && active.keyId == keyId && active.isUsable) {
      return active;
    }

    for (final key in decryptionKeys) {
      if (key.keyId == keyId && key.isUsable) {
        return key;
      }
    }

    return null;
  }
}

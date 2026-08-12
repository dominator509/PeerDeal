import '../contracts/receipt_encryption_key_provider.dart';
import '../contracts/receipt_signing_key_provider.dart';
import '../models/receipt_encryption_key.dart';
import '../models/receipt_key_ring_input_limits.dart';
import '../models/receipt_signing_key.dart';

class ReceiptKeyRingSnapshot
    implements ReceiptSigningKeyProvider, ReceiptEncryptionKeyProvider {
  ReceiptKeyRingSnapshot({
    this.activeSigning,
    List<ReceiptSigningKey> verificationSigningKeys =
        const <ReceiptSigningKey>[],
    this.activeEncryption,
    List<ReceiptEncryptionKey> decryptionKeys = const <ReceiptEncryptionKey>[],
    this.maxVerificationKeys =
        ReceiptKeyRingInputLimits.defaultMaxVerificationKeys,
    this.maxDecryptionKeys = ReceiptKeyRingInputLimits.defaultMaxDecryptionKeys,
  }) : assert(maxVerificationKeys > 0, 'maxVerificationKeys must be positive'),
       assert(maxDecryptionKeys > 0, 'maxDecryptionKeys must be positive'),
       verificationSigningKeys = List<ReceiptSigningKey>.unmodifiable(
         verificationSigningKeys,
       ),
       decryptionKeys = List<ReceiptEncryptionKey>.unmodifiable(decryptionKeys);

  final ReceiptSigningKey? activeSigning;
  final List<ReceiptSigningKey> verificationSigningKeys;
  final ReceiptEncryptionKey? activeEncryption;
  final List<ReceiptEncryptionKey> decryptionKeys;
  final int maxVerificationKeys;
  final int maxDecryptionKeys;

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

    if (verificationSigningKeys.length > maxVerificationKeys) {
      return null;
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

    if (decryptionKeys.length > maxDecryptionKeys) {
      return null;
    }

    for (final key in decryptionKeys) {
      if (key.keyId == keyId && key.isUsable) {
        return key;
      }
    }

    return null;
  }
}

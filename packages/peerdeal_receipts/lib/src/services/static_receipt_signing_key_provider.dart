import '../contracts/receipt_signing_key_provider.dart';
import '../models/receipt_signing_key.dart';

class StaticReceiptSigningKeyProvider implements ReceiptSigningKeyProvider {
  const StaticReceiptSigningKeyProvider({
    required this.activeKey,
    this.verificationKeys = const <ReceiptSigningKey>[],
  });

  final ReceiptSigningKey activeKey;
  final List<ReceiptSigningKey> verificationKeys;

  @override
  ReceiptSigningKey? activeSigningKey() {
    return activeKey.isUsable ? activeKey : null;
  }

  @override
  ReceiptSigningKey? findSigningKey(String keyId) {
    if (activeKey.keyId == keyId && activeKey.isUsable) {
      return activeKey;
    }

    for (final key in verificationKeys) {
      if (key.keyId == keyId && key.isUsable) {
        return key;
      }
    }

    return null;
  }
}

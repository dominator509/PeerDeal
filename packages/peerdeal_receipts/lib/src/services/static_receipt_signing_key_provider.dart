import '../contracts/receipt_signing_key_provider.dart';
import '../models/receipt_key_ring_input_limits.dart';
import '../models/receipt_signing_key.dart';

class StaticReceiptSigningKeyProvider implements ReceiptSigningKeyProvider {
  StaticReceiptSigningKeyProvider({
    required this.activeKey,
    List<ReceiptSigningKey> verificationKeys = const <ReceiptSigningKey>[],
    int maxVerificationKeys =
        ReceiptKeyRingInputLimits.defaultMaxVerificationKeys,
  }) : maxVerificationKeys = _validatePositiveLimit(
         maxVerificationKeys,
         'maxVerificationKeys',
       ),
       verificationKeys = List<ReceiptSigningKey>.unmodifiable(
         verificationKeys,
       );

  final ReceiptSigningKey activeKey;
  final List<ReceiptSigningKey> verificationKeys;
  final int maxVerificationKeys;

  @override
  ReceiptSigningKey? activeSigningKey() {
    return activeKey.isUsable ? activeKey : null;
  }

  @override
  ReceiptSigningKey? findSigningKey(String keyId) {
    if (activeKey.keyId == keyId && activeKey.isUsable) {
      return activeKey;
    }

    if (verificationKeys.length > maxVerificationKeys) {
      return null;
    }

    for (final key in verificationKeys) {
      if (key.keyId == keyId && key.isUsable) {
        return key;
      }
    }

    return null;
  }
}

int _validatePositiveLimit(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
  return value;
}

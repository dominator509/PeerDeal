import '../models/receipt_signing_key.dart';

abstract class ReceiptSigningKeyProvider {
  ReceiptSigningKey? activeSigningKey();
  ReceiptSigningKey? findSigningKey(String keyId);
}

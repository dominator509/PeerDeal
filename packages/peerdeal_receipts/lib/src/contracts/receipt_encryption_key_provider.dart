import '../models/receipt_encryption_key.dart';

abstract class ReceiptEncryptionKeyProvider {
  ReceiptEncryptionKey? activeEncryptionKey();
  ReceiptEncryptionKey? findEncryptionKey(String keyId);
}

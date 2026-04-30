abstract class ReceiptSigner {
  String sign(String payload);
  bool verify({required String payload, required String signature});
}

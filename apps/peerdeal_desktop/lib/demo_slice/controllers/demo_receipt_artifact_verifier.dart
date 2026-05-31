import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'native_receipt_key_ring_loader.dart';

class DemoReceiptArtifactVerifier {
  const DemoReceiptArtifactVerifier({
    required NativeReceiptKeyRingLoader keyRingLoader,
  }) : _keyRingLoader = keyRingLoader;

  final NativeReceiptKeyRingLoader _keyRingLoader;

  Future<ReceiptExportInspectionResult> inspect(
    ReceiptExportArtifact artifact,
  ) async {
    final loadResult = await _keyRingLoader.load();
    if (!loadResult.hasSigningKey) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt signing key is unavailable.',
        diagnostics: loadResult.warnings,
      );
    }

    final signer = HmacSha256ReceiptSigner(keyProvider: loadResult.keyRing);
    return OpaqueExportDecoder(signer: signer).inspect(artifact);
  }
}

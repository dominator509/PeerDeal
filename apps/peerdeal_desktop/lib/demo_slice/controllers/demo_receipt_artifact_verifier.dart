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
    final encrypted = artifact.minimalMetadata['encrypted'] == true;
    if (encrypted && !loadResult.hasEncryptionKey) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt encryption key is unavailable.',
        diagnostics: loadResult.warnings,
      );
    }

    final cipher = loadResult.hasEncryptionKey
        ? HmacSha256ReceiptCipher(keyProvider: loadResult.keyRing)
        : null;
    return OpaqueExportDecoder(
      cipher: cipher,
      signer: signer,
    ).inspect(artifact);
  }
}

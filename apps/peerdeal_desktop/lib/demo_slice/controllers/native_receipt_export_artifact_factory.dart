import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'native_receipt_key_ring_loader.dart';
import 'native_receipt_key_ring_provisioner.dart';
import 'native_receipt_key_ring_writer.dart';

typedef ReceiptExportArtifactBuilder =
    Future<ReceiptExportArtifact> Function(PeerDealReceipt receipt);

class NativeReceiptExportArtifactFactory {
  const NativeReceiptExportArtifactFactory({
    required NativeReceiptKeyRingProvisioner keyRingProvisioner,
    ReceiptCipherNonceFactory? nonceFactory,
  }) : _keyRingProvisioner = keyRingProvisioner,
       _nonceFactory = nonceFactory;

  factory NativeReceiptExportArtifactFactory.methodChannel({
    String namespace = NativeReceiptKeyRingLoader.defaultNamespace,
  }) {
    final bridge = MethodChannelSecureKeyStorageBridge();
    return NativeReceiptExportArtifactFactory(
      keyRingProvisioner: NativeReceiptKeyRingProvisioner(
        loader: NativeReceiptKeyRingLoader(
          bridge: bridge,
          namespace: namespace,
        ),
        writer: NativeReceiptKeyRingWriter(
          bridge: bridge,
          namespace: namespace,
        ),
      ),
    );
  }

  final NativeReceiptKeyRingProvisioner _keyRingProvisioner;
  final ReceiptCipherNonceFactory? _nonceFactory;

  Future<ReceiptExportArtifact> exportSignedEncrypted(
    PeerDealReceipt receipt,
  ) async {
    final ReceiptKeyRingProvisionResult provisionResult;
    try {
      provisionResult = await _keyRingProvisioner.ensureActiveKeys();
    } catch (_) {
      return const ReceiptExportArtifact.unavailable(
        reason: 'Receipt key provisioning failed.',
      );
    }

    if (!provisionResult.isSuccess) {
      return const ReceiptExportArtifact.unavailable(
        reason: 'Receipt key provisioning failed.',
      );
    }

    final keyRing = provisionResult.keyRing;
    final service = DefaultReceiptService(
      authorizer: const DefaultReceiptAuthorizer(),
      exportEncoder: OpaqueExportEncoder(
        cipher: HmacSha256ReceiptCipher(
          keyProvider: keyRing,
          nonceFactory: _nonceFactory,
        ),
        signer: HmacSha256ReceiptSigner(keyProvider: keyRing),
      ),
    );
    return service.exportReceipt(receipt);
  }
}

import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  const receipt = PeerDealReceipt(
    receiptId: 'r_1',
    receiptVersion: '1.0',
    protocolVersion: '1.x',
    modeType: 'tournament',
    sessionId: 'sess_77',
    tableId: 'table_7',
    pseudonymousUserId: 'user_7',
    bindingMode: ReceiptBindingMode.sessionBound,
    wipeState: ReceiptWipeState.live,
    payloadHash: 'hash_77',
    opaquePayload: 'opaque_77',
  );

  test('fails closed when signing throws', () {
    final encoder = OpaqueExportEncoder(signer: _ThrowingReceiptSigner());

    final artifact = encoder.encode(receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.encodedBody, isEmpty);
    expect(artifact.minimalMetadata, isEmpty);
    expect(artifact.reason, 'Receipt export failed.');
  });

  test('fails closed when encryption throws', () {
    final encoder = OpaqueExportEncoder(cipher: _ThrowingReceiptCipher());

    final artifact = encoder.encode(receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.encodedBody, isEmpty);
    expect(artifact.minimalMetadata, isEmpty);
    expect(artifact.reason, 'Receipt export failed.');
  });

  test('fails closed when the encoded artifact exceeds its limit', () {
    final encoder = OpaqueExportEncoder(
      limits: ReceiptExportLimits(maxEncodedBodyLength: 8),
    );

    final artifact = encoder.encode(receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.reason, 'Receipt export failed.');
  });

  test('fails closed when the receipt payload exceeds its limit', () {
    final encoder = OpaqueExportEncoder(
      limits: ReceiptExportLimits(maxPayloadBytes: 8),
    );

    final artifact = encoder.encode(receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.reason, 'Receipt export failed.');
  });
}

class _ThrowingReceiptSigner implements ReceiptSigner {
  const _ThrowingReceiptSigner();

  @override
  String sign(String payload) {
    throw StateError('signing unavailable');
  }

  @override
  bool verify({required String payload, required String signature}) => false;
}

class _ThrowingReceiptCipher implements ReceiptCipher {
  const _ThrowingReceiptCipher();

  @override
  String encrypt(String plaintext) {
    throw StateError('encryption unavailable');
  }

  @override
  String decrypt(String ciphertext) {
    throw StateError('decryption unavailable');
  }
}

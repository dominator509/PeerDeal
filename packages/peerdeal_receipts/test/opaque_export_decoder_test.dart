import 'dart:convert';

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
  final keyProvider = StaticReceiptSigningKeyProvider(
    activeKey: ReceiptSigningKey(
      keyId: 'receipt_key_1',
      secret: 'test_secret_1',
    ),
  );
  final signer = HmacSha256ReceiptSigner(keyProvider: keyProvider);
  final encoder = OpaqueExportEncoder(signer: signer);
  final decoder = OpaqueExportDecoder(signer: signer);

  test('verifies signed opaque export artifact', () {
    final artifact = encoder.encode(receipt);

    final result = decoder.inspect(artifact);

    expect(result.isAccepted, isTrue);
    expect(result.status, 'ok');
    expect(result.message, 'Receipt artifact verified.');
    expect(result.payload['receipt_id'], 'r_1');
    expect(result.payload['payload_hash'], 'hash_77');
    expect(result.payload.containsKey('table_id'), isFalse);
  });

  test('rejects unsigned export artifact by default', () {
    final artifact = const OpaqueExportEncoder().encode(receipt);

    final result = decoder.inspect(artifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact is unsigned.');
  });

  test('can inspect unsigned artifact when explicitly allowed', () {
    final artifact = const OpaqueExportEncoder().encode(receipt);
    const permissiveDecoder = OpaqueExportDecoder(requireSignature: false);

    final result = permissiveDecoder.inspect(artifact);

    expect(result.isAccepted, isTrue);
    expect(result.payload['receipt_id'], 'r_1');
  });

  test('rejects tampered signed payload', () {
    final artifact = encoder.encode(receipt);
    final body = _decodeBody(artifact.encodedBody);
    final tamperedBody = <String, Object?>{
      ...body,
      'payload': '${body['payload']}-tampered',
    };
    final tamperedArtifact = ReceiptExportArtifact(
      artifactType: artifact.artifactType,
      encodedBody: _encodeBody(tamperedBody),
      minimalMetadata: artifact.minimalMetadata,
    );

    final result = decoder.inspect(tamperedArtifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact signature verification failed.');
  });

  test('rejects signed artifact when verifier throws', () {
    final artifact = encoder.encode(receipt);
    const throwingDecoder = OpaqueExportDecoder(
      signer: _ThrowingReceiptSigner(),
    );

    final result = throwingDecoder.inspect(artifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact signature verification failed.');
  });

  test('rejects malformed artifact body', () {
    final result = decoder.inspect(
      ReceiptExportArtifact(
        artifactType: 'file',
        encodedBody: 'not-base64',
        minimalMetadata: <String, Object?>{},
      ),
    );

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact body is malformed.');
  });

  test('rejects oversized encoded artifact bodies before decoding', () {
    final artifact = encoder.encode(receipt);
    final limitedDecoder = OpaqueExportDecoder(
      signer: signer,
      limits: const ReceiptExportLimits(maxEncodedBodyLength: 8),
    );

    final result = limitedDecoder.inspect(artifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact body is malformed.');
  });

  test('rejects oversized decoded artifact bodies before parsing JSON', () {
    final artifact = encoder.encode(receipt);
    final limitedDecoder = OpaqueExportDecoder(
      signer: signer,
      limits: const ReceiptExportLimits(maxDecodedBodyBytes: 8),
    );

    final result = limitedDecoder.inspect(artifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact body is malformed.');
  });

  test('rejects oversized payloads before signature verification', () {
    final artifact = encoder.encode(receipt);
    final limitedDecoder = OpaqueExportDecoder(
      signer: signer,
      limits: const ReceiptExportLimits(maxPayloadBytes: 8),
    );

    final result = limitedDecoder.inspect(artifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact payload is malformed.');
  });

  test('rejects encrypted artifact when cipher is unavailable', () {
    final encryptedEncoder = OpaqueExportEncoder(
      cipher: HmacSha256ReceiptCipher(
        keyProvider: ReceiptKeyRingSnapshot(
          activeEncryption: ReceiptEncryptionKey(
            keyId: 'receipt_encryption_1',
            secret: 'encryption_secret_1',
          ),
        ),
        nonceFactory: () => List<int>.filled(32, 2),
      ),
      signer: signer,
    );
    final artifact = encryptedEncoder.encode(receipt);

    final result = decoder.inspect(artifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact payload cannot be decoded.');
  });

  test('verifies and decrypts encrypted signed export artifact', () {
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: ReceiptKeyRingSnapshot(
        activeEncryption: ReceiptEncryptionKey(
          keyId: 'receipt_encryption_1',
          secret: 'encryption_secret_1',
        ),
      ),
      nonceFactory: () => List<int>.filled(32, 3),
    );
    final encryptedEncoder = OpaqueExportEncoder(
      cipher: cipher,
      signer: signer,
    );
    final encryptedDecoder = OpaqueExportDecoder(
      cipher: cipher,
      signer: signer,
    );
    final artifact = encryptedEncoder.encode(receipt);

    final result = encryptedDecoder.inspect(artifact);

    expect(result.isAccepted, isTrue);
    expect(result.payload['receipt_id'], 'r_1');
    expect(result.payload['opaque_payload'], 'opaque_77');
  });

  test('rejects payload shape that leaks table identity', () {
    final payload = jsonEncode(<String, Object?>{
      'receipt_id': 'r_1',
      'receipt_version': '1.0',
      'protocol_version': '1.x',
      'mode_type': 'tournament',
      'payload_hash': 'hash_77',
      'opaque_payload': 'opaque_77',
      'table_id': 'table_7',
    });
    final signature = signer.sign(payload);
    final artifact = ReceiptExportArtifact(
      artifactType: 'file',
      encodedBody: _encodeBody(<String, Object?>{
        'format_version': '1.0',
        'cipher': 'none',
        'payload': payload,
        'signature': signature,
      }),
      minimalMetadata: const <String, Object?>{},
    );

    final result = decoder.inspect(artifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact payload shape is unsupported.');
  });

  test('rejects structurally oversized decoded payloads', () {
    final payload = <String, Object?>{
      'receipt_id': 'r_1',
      'receipt_version': '1.0',
      'protocol_version': '1.x',
      'mode_type': 'tournament',
      'payload_hash': 'hash_77',
      'opaque_payload': 'opaque_77',
      for (var index = 0; index < 252; index += 1) 'extra_$index': index,
    };
    final payloadText = jsonEncode(payload);
    final artifact = ReceiptExportArtifact(
      artifactType: 'file',
      encodedBody: _encodeBody(<String, Object?>{
        'format_version': '1.0',
        'cipher': 'none',
        'payload': payloadText,
      }),
      minimalMetadata: const <String, Object?>{},
    );

    final result = const OpaqueExportDecoder(
      requireSignature: false,
    ).inspect(artifact);

    expect(result.isAccepted, isFalse);
    expect(result.message, 'Receipt artifact payload shape is unsupported.');
  });
}

Map<String, Object?> _decodeBody(String encodedBody) {
  return jsonDecode(utf8.decode(base64Decode(encodedBody)))
      as Map<String, Object?>;
}

String _encodeBody(Map<String, Object?> body) {
  return base64Encode(utf8.encode(jsonEncode(body)));
}

class _ThrowingReceiptSigner implements ReceiptSigner {
  const _ThrowingReceiptSigner();

  @override
  String sign(String payload) {
    throw StateError('signing unavailable');
  }

  @override
  bool verify({required String payload, required String signature}) {
    throw StateError('verification unavailable');
  }
}

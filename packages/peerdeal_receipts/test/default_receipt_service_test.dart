import 'dart:convert';

import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  const service = DefaultReceiptService(authorizer: DefaultReceiptAuthorizer());

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

  test('exports opaque artifact with minimal metadata', () {
    final artifact = service.exportReceipt(receipt);
    expect(artifact.artifactType, 'file');
    expect(artifact.reason, isNull);
    expect(artifact.minimalMetadata['receipt_id'], 'r_1');
    expect(artifact.minimalMetadata['encrypted'], isFalse);
    expect(artifact.minimalMetadata['signed'], isFalse);
    expect(artifact.minimalMetadata.containsKey('table_id'), isFalse);

    final body = _decodeBody(artifact.encodedBody);
    expect(body['format_version'], '1.0');
    expect(body['cipher'], 'none');
    expect(body.containsKey('signature'), isFalse);

    final payload =
        jsonDecode(body['payload'] as String) as Map<String, Object?>;
    expect(payload['receipt_id'], 'r_1');
    expect(payload['payload_hash'], 'hash_77');
    expect(payload.containsKey('table_id'), isFalse);
  });

  test('exports encrypted and signed artifacts when configured', () {
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: const ReceiptKeyRingSnapshot(
        activeEncryption: ReceiptEncryptionKey(
          keyId: 'receipt_encryption_1',
          secret: 'encryption_secret_1',
        ),
      ),
      nonceFactory: () => List<int>.filled(32, 5),
    );
    final encryptedService = DefaultReceiptService(
      authorizer: const DefaultReceiptAuthorizer(),
      exportEncoder: OpaqueExportEncoder(
        cipher: cipher,
        signer: const _FakeReceiptSigner(),
      ),
    );

    final artifact = encryptedService.exportReceipt(receipt);

    expect(artifact.artifactType, 'encrypted_file');
    expect(artifact.minimalMetadata['encrypted'], isTrue);
    expect(artifact.minimalMetadata['signed'], isTrue);
    expect(artifact.minimalMetadata.containsKey('table_id'), isFalse);

    final body = _decodeBody(artifact.encodedBody);
    expect(body['cipher'], 'external');
    expect(
      body['payload'],
      startsWith(
        '${HmacSha256ReceiptCipher.formatVersion}:'
        '${HmacSha256ReceiptCipher.algorithm}:receipt_encryption_1:',
      ),
    );
    expect(body['signature'], 'sig:${body['payload']}');

    final innerBody = cipher.decrypt(body['payload'] as String);
    final payload = jsonDecode(innerBody) as Map<String, Object?>;
    expect(payload['receipt_id'], 'r_1');
    expect(payload['protocol_version'], '1.x');
    expect(payload['opaque_payload'], 'opaque_77');
    expect(payload.containsKey('table_id'), isFalse);
  });

  test('exports artifacts signed by HMAC receipt signer', () {
    const keyProvider = StaticReceiptSigningKeyProvider(
      activeKey: ReceiptSigningKey(
        keyId: 'receipt_key_1',
        secret: 'test_secret_1',
      ),
    );
    const signer = HmacSha256ReceiptSigner(keyProvider: keyProvider);
    const signedService = DefaultReceiptService(
      authorizer: DefaultReceiptAuthorizer(),
      exportEncoder: OpaqueExportEncoder(signer: signer),
    );

    final artifact = signedService.exportReceipt(receipt);
    final body = _decodeBody(artifact.encodedBody);
    final signature = body['signature'] as String;
    final payload = body['payload'] as String;

    expect(artifact.artifactType, 'file');
    expect(artifact.minimalMetadata['encrypted'], isFalse);
    expect(artifact.minimalMetadata['signed'], isTrue);
    expect(signature, startsWith('hmac-sha256:receipt_key_1:'));
    expect(signer.verify(payload: payload, signature: signature), isTrue);
    expect(
      signer.verify(payload: '$payload-tampered', signature: signature),
      isFalse,
    );
  });

  test('export rejects malformed receipt envelope', () {
    const malformedReceipt = PeerDealReceipt(
      receiptId: 'r_bad',
      receiptVersion: '1.0',
      protocolVersion: '1.x',
      modeType: 'open_table',
      sessionId: 'sess_99',
      tableId: 'table_9',
      pseudonymousUserId: 'user_9',
      bindingMode: ReceiptBindingMode.userBound,
      wipeState: ReceiptWipeState.live,
      payloadHash: '',
      opaquePayload: 'opaque_99',
    );

    final artifact = service.exportReceipt(malformedReceipt);
    expect(artifact.artifactType, 'unavailable');
    expect(artifact.encodedBody, isEmpty);
    expect(artifact.minimalMetadata, isEmpty);
    expect(artifact.reason, 'Receipt envelope is malformed.');
  });

  test('export rejects wiped receipt', () {
    const wipedReceipt = PeerDealReceipt(
      receiptId: 'r_wiped',
      receiptVersion: '1.0',
      protocolVersion: '1.x',
      modeType: 'open_table',
      sessionId: 'sess_88',
      tableId: 'table_8',
      pseudonymousUserId: 'user_8',
      bindingMode: ReceiptBindingMode.userBound,
      wipeState: ReceiptWipeState.wiped,
      payloadHash: 'hash_88',
      opaquePayload: 'opaque_88',
    );

    final artifact = service.exportReceipt(wipedReceipt);
    expect(artifact.artifactType, 'unavailable');
    expect(artifact.encodedBody, isEmpty);
    expect(artifact.minimalMetadata, isEmpty);
    expect(artifact.reason, 'Receipt unavailable.');
  });

  test('export fails closed when signing throws', () {
    const signedService = DefaultReceiptService(
      authorizer: DefaultReceiptAuthorizer(),
      exportEncoder: OpaqueExportEncoder(signer: _ThrowingReceiptSigner()),
    );

    final artifact = signedService.exportReceipt(receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.encodedBody, isEmpty);
    expect(artifact.minimalMetadata, isEmpty);
    expect(artifact.reason, 'Receipt export failed.');
  });

  test('export fails closed when encryption throws', () {
    const encryptedService = DefaultReceiptService(
      authorizer: DefaultReceiptAuthorizer(),
      exportEncoder: OpaqueExportEncoder(cipher: _ThrowingReceiptCipher()),
    );

    final artifact = encryptedService.exportReceipt(receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.encodedBody, isEmpty);
    expect(artifact.minimalMetadata, isEmpty);
    expect(artifact.reason, 'Receipt export failed.');
  });

  test('scan returns ok for non-wiped receipt', () {
    final result = service.scanReceipt(receipt);
    expect(result.status, 'ok');
    expect(result.shareableFields['mode_type'], 'tournament');
  });

  test('scan returns wiped when receipt wiped', () {
    const wipedReceipt = PeerDealReceipt(
      receiptId: 'r_2',
      receiptVersion: '1.0',
      protocolVersion: '1.x',
      modeType: 'open_table',
      sessionId: 'sess_88',
      tableId: 'table_8',
      pseudonymousUserId: 'user_8',
      bindingMode: ReceiptBindingMode.userBound,
      wipeState: ReceiptWipeState.wiped,
      payloadHash: 'hash_88',
      opaquePayload: 'opaque_88',
    );

    final result = service.scanReceipt(wipedReceipt);
    expect(result.status, 'wiped');
  });

  test('scan rejects malformed receipt envelope', () {
    const malformedReceipt = PeerDealReceipt(
      receiptId: 'r_bad',
      receiptVersion: '1.0',
      protocolVersion: '1.x',
      modeType: 'open_table',
      sessionId: 'sess_99',
      tableId: 'table_9',
      pseudonymousUserId: 'user_9',
      bindingMode: ReceiptBindingMode.userBound,
      wipeState: ReceiptWipeState.live,
      payloadHash: '',
      opaquePayload: 'opaque_99',
    );

    final result = service.scanReceipt(malformedReceipt);
    expect(result.status, 'rejected');
    expect(result.message, 'Receipt envelope is malformed.');
    expect(result.shareableFields, isEmpty);
  });
}

Map<String, Object?> _decodeBody(String encodedBody) {
  return jsonDecode(utf8.decode(base64Decode(encodedBody)))
      as Map<String, Object?>;
}

class _FakeReceiptSigner implements ReceiptSigner {
  const _FakeReceiptSigner();

  @override
  String sign(String payload) => 'sig:$payload';

  @override
  bool verify({required String payload, required String signature}) {
    return signature == sign(payload);
  }
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

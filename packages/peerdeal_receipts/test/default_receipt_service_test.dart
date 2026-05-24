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
    expect(artifact.minimalMetadata.containsKey('table_id'), isTrue);
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

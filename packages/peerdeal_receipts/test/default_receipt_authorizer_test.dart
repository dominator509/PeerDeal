import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  const authorizer = DefaultReceiptAuthorizer();

  const liveReceipt = PeerDealReceipt(
    receiptId: 'r_1',
    receiptVersion: '1.0',
    protocolVersion: '1.x',
    modeType: 'open_table',
    sessionId: 'sess_1',
    tableId: 'table_1',
    pseudonymousUserId: 'user_1',
    bindingMode: ReceiptBindingMode.mixed,
    wipeState: ReceiptWipeState.live,
    payloadHash: 'hash_live',
    opaquePayload: 'opaque_live',
  );

  test('allows restore for matching user and session', () {
    const request = ReceiptAuthorizationRequest(
      requestedByUserId: 'user_1',
      requestedSessionId: 'sess_1',
      accessMode: ReceiptAccessMode.restore,
    );

    final result = authorizer.authorize(liveReceipt, request);
    expect(result.allowed, isTrue);
    expect(result.normalizedResultCode, 'OK_RECEIPT_RESTORE_ALLOWED');
  });

  test('rejects wrong-user restore', () {
    const request = ReceiptAuthorizationRequest(
      requestedByUserId: 'user_2',
      requestedSessionId: 'sess_1',
      accessMode: ReceiptAccessMode.restore,
    );

    final result = authorizer.authorize(liveReceipt, request);
    expect(result.allowed, isFalse);
    expect(result.normalizedResultCode, 'ERR_RECEIPT_USER_MISMATCH');
  });

  test('rejects wiped receipt restore', () {
    const wipedReceipt = PeerDealReceipt(
      receiptId: 'r_2',
      receiptVersion: '1.0',
      protocolVersion: '1.x',
      modeType: 'open_table',
      sessionId: 'sess_1',
      tableId: 'table_1',
      pseudonymousUserId: 'user_1',
      bindingMode: ReceiptBindingMode.userBound,
      wipeState: ReceiptWipeState.wiped,
      payloadHash: 'hash_wiped',
      opaquePayload: 'opaque_wiped',
    );

    const request = ReceiptAuthorizationRequest(
      requestedByUserId: 'user_1',
      requestedSessionId: 'sess_1',
      accessMode: ReceiptAccessMode.restore,
    );

    final result = authorizer.authorize(wipedReceipt, request);
    expect(result.allowed, isFalse);
    expect(result.normalizedResultCode, 'ERR_RECEIPT_WIPED');
  });
}

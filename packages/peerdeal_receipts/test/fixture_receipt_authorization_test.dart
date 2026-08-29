import 'dart:io';

import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';

void main() {
  test('loads every receipt fixture through typed decoders', () {
    final receiptFiles = Directory('test/fixtures')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('_receipt.json'))
        .toList(growable: false);

    expect(receiptFiles, hasLength(2));
    for (final file in receiptFiles) {
      final receipt = loadReceiptFixture(file.uri.pathSegments.last);
      expect(receipt.hasRequiredEnvelopeFields, isTrue, reason: file.path);
    }

    final request = loadAuthorizationRequestFixture(
      'wrong_user_restore_request.json',
    );
    expect(request.accessMode, ReceiptAccessMode.restore);
  });

  test('fixture authorization preserves allow and fail-closed outcomes', () {
    const authorizer = DefaultReceiptAuthorizer();
    final liveReceipt = loadReceiptFixture('valid_open_table_receipt.json');
    final matchingRequest = const ReceiptAuthorizationRequest(
      requestedByUserId: 'user_alpha',
      requestedSessionId: 'sess_open_001',
      accessMode: ReceiptAccessMode.restore,
    );
    final wrongUserRequest = loadAuthorizationRequestFixture(
      'wrong_user_restore_request.json',
    );
    final wipedReceipt = loadReceiptFixture('wiped_receipt.json');

    final allowed = authorizer.authorize(liveReceipt, matchingRequest);
    final wrongUser = authorizer.authorize(liveReceipt, wrongUserRequest);
    final wiped = authorizer.authorize(wipedReceipt, matchingRequest);

    expect(allowed.allowed, isTrue);
    expect(allowed.normalizedResultCode, 'OK_RECEIPT_RESTORE_ALLOWED');
    expect(wrongUser.allowed, isFalse);
    expect(wrongUser.normalizedResultCode, 'ERR_RECEIPT_USER_MISMATCH');
    expect(wiped.allowed, isFalse);
    expect(wiped.normalizedResultCode, 'ERR_RECEIPT_WIPED');
  });
}

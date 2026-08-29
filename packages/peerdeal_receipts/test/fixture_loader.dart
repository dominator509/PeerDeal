import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_receipts/peerdeal_receipts.dart';

Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

PeerDealReceipt loadReceiptFixture(String name) {
  final json = loadFixture(name);
  return PeerDealReceipt(
    receiptId: _requiredString(json, 'receipt_id'),
    receiptVersion: _requiredString(json, 'receipt_version'),
    protocolVersion: _requiredString(json, 'protocol_version'),
    modeType: _requiredString(json, 'mode_type'),
    sessionId: _requiredString(json, 'session_id'),
    tableId: _requiredString(json, 'table_id'),
    pseudonymousUserId: _requiredString(json, 'pseudonymous_user_id'),
    bindingMode: _bindingMode(_requiredString(json, 'binding_mode')),
    wipeState: _wipeState(_requiredString(json, 'wipe_state')),
    payloadHash: _requiredString(json, 'payload_hash'),
    opaquePayload: _requiredString(json, 'opaque_payload'),
    closedAt: _optionalString(json, 'closed_at'),
    signature: _optionalString(json, 'signature'),
  );
}

ReceiptAuthorizationRequest loadAuthorizationRequestFixture(String name) {
  final json = loadFixture(name);
  return ReceiptAuthorizationRequest(
    requestedByUserId: _requiredString(json, 'requested_by_user_id'),
    requestedSessionId: _requiredString(json, 'requested_session_id'),
    accessMode: _accessMode(_requiredString(json, 'access_mode')),
  );
}

ReceiptBindingMode _bindingMode(String value) {
  switch (value) {
    case 'session_bound':
      return ReceiptBindingMode.sessionBound;
    case 'user_bound':
      return ReceiptBindingMode.userBound;
    case 'mixed':
      return ReceiptBindingMode.mixed;
    default:
      throw FormatException('Unsupported receipt binding mode: $value.');
  }
}

ReceiptWipeState _wipeState(String value) {
  switch (value) {
    case 'live':
      return ReceiptWipeState.live;
    case 'closed':
      return ReceiptWipeState.closed;
    case 'grace':
      return ReceiptWipeState.grace;
    case 'wiped':
      return ReceiptWipeState.wiped;
    default:
      throw FormatException('Unsupported receipt wipe state: $value.');
  }
}

ReceiptAccessMode _accessMode(String value) {
  switch (value) {
    case 'restore':
      return ReceiptAccessMode.restore;
    case 'view':
      return ReceiptAccessMode.view;
    default:
      throw FormatException('Unsupported receipt access mode: $value.');
  }
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

String? _optionalString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

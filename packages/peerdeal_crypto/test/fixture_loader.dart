import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_crypto/peerdeal_crypto.dart';

Map<String, Object?> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

VerificationRequest loadVerificationRequestFixture(String name) {
  final json = loadFixture(name);
  final rawProof = json['dealProofBundle'];
  if (rawProof != null && rawProof is! Map) {
    throw const FormatException('dealProofBundle must be an object.');
  }

  final proof = rawProof == null
      ? null
      : _proofBundle((rawProof as Map).cast<String, Object?>());
  return VerificationRequest(
    tableId: _requiredString(json, 'tableId'),
    sessionId: _requiredString(json, 'sessionId'),
    handId: _optionalString(json, 'handId'),
    scope: _verificationScope(_requiredString(json, 'scope')),
    protocolVersion: _requiredString(json, 'protocolVersion'),
    eventSeqStart: _optionalInt(json, 'eventSeqStart'),
    eventSeqEnd: _optionalInt(json, 'eventSeqEnd'),
    expectedReplayAnchor: _optionalString(json, 'expectedReplayAnchor'),
    expectedFairDealAnchor: _optionalString(json, 'expectedFairDealAnchor'),
    expectedSettlementAnchor: _optionalString(json, 'expectedSettlementAnchor'),
    dealProofBundle: proof,
    isWiped: _optionalBool(json, 'isWiped'),
  );
}

DealProofBundle _proofBundle(Map<String, Object?> json) {
  final normalizedFields = json['normalizedFields'];
  if (normalizedFields != null && normalizedFields is! Map) {
    throw const FormatException('normalizedFields must be an object.');
  }
  final rawPayload = json['rawPayload'];
  if (rawPayload != null && rawPayload is! Map) {
    throw const FormatException('rawPayload must be an object.');
  }
  return DealProofBundle(
    providerId: _requiredString(json, 'providerId'),
    providerVersion: _requiredString(json, 'providerVersion'),
    proofReference: _requiredString(json, 'proofReference'),
    normalizedFields: normalizedFields == null
        ? const <String, Object?>{}
        : (normalizedFields as Map).cast<String, Object?>(),
    rawPayload: rawPayload == null
        ? null
        : (rawPayload as Map).cast<String, Object?>(),
  );
}

VerificationScope _verificationScope(String value) {
  switch (value) {
    case 'hand':
      return VerificationScope.hand;
    case 'session':
      return VerificationScope.session;
    case 'window':
      return VerificationScope.window;
    default:
      throw FormatException('Unsupported verification scope: $value.');
  }
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

String? _optionalString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

int? _optionalInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('$key must be an integer.');
}

bool _optionalBool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return false;
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}

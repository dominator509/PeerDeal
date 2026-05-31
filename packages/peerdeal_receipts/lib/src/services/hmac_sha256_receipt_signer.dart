import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../contracts/receipt_signer.dart';
import '../contracts/receipt_signing_key_provider.dart';
import '../models/receipt_signing_key.dart';

class HmacSha256ReceiptSigner implements ReceiptSigner {
  const HmacSha256ReceiptSigner({
    required ReceiptSigningKeyProvider keyProvider,
  }) : _keyProvider = keyProvider;

  static const algorithm = 'hmac-sha256';

  final ReceiptSigningKeyProvider _keyProvider;

  @override
  String sign(String payload) {
    final key = _keyProvider.activeSigningKey();
    if (key == null) {
      throw StateError('No usable receipt signing key is available.');
    }

    return _signatureFor(payload: payload, key: key);
  }

  @override
  bool verify({required String payload, required String signature}) {
    final parts = signature.split(':');
    if (parts.length != 3 || parts[0] != algorithm) {
      return false;
    }

    final key = _keyProvider.findSigningKey(parts[1]);
    if (key == null) return false;

    final expected = _signatureFor(payload: payload, key: key);
    return _constantTimeEquals(expected, signature);
  }

  String _signatureFor({
    required String payload,
    required ReceiptSigningKey key,
  }) {
    final mac = Hmac(sha256, utf8.encode(key.secret));
    final digest = mac.convert(utf8.encode(payload)).toString();
    return '$algorithm:${key.keyId}:$digest';
  }

  bool _constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    var diff = aBytes.length ^ bBytes.length;
    final maxLength = aBytes.length > bBytes.length
        ? aBytes.length
        : bBytes.length;

    for (var i = 0; i < maxLength; i++) {
      final aByte = i < aBytes.length ? aBytes[i] : 0;
      final bByte = i < bBytes.length ? bBytes[i] : 0;
      diff |= aByte ^ bByte;
    }

    return diff == 0;
  }
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../contracts/receipt_cipher.dart';
import '../contracts/receipt_encryption_key_provider.dart';
import '../models/receipt_encryption_key.dart';

typedef ReceiptCipherNonceFactory = List<int> Function();

class HmacSha256ReceiptCipher implements ReceiptCipher {
  HmacSha256ReceiptCipher({
    required ReceiptEncryptionKeyProvider keyProvider,
    ReceiptCipherNonceFactory? nonceFactory,
  }) : _keyProvider = keyProvider,
       _nonceFactory = nonceFactory ?? _secureNonce;

  static const formatVersion = 'pdrc-v1';
  static const algorithm = 'hmac-sha256-stream';

  final ReceiptEncryptionKeyProvider _keyProvider;
  final ReceiptCipherNonceFactory _nonceFactory;

  @override
  String encrypt(String plaintext) {
    final key = _keyProvider.activeEncryptionKey();
    if (key == null) {
      throw StateError('No usable receipt encryption key is available.');
    }

    final nonce = _nonceFactory();
    if (nonce.isEmpty) {
      throw StateError('Receipt encryption nonce is unavailable.');
    }

    final payload = _xorWithKeystream(
      data: utf8.encode(plaintext),
      key: key,
      nonce: nonce,
    );
    final nonceText = base64Encode(nonce);
    final payloadText = base64Encode(payload);
    final mac = _mac(
      key: key,
      keyId: key.keyId,
      nonceText: nonceText,
      payloadText: payloadText,
    );

    return [
      formatVersion,
      algorithm,
      key.keyId,
      nonceText,
      payloadText,
      mac,
    ].join(':');
  }

  @override
  String decrypt(String ciphertext) {
    final parts = ciphertext.split(':');
    if (parts.length != 6 ||
        parts[0] != formatVersion ||
        parts[1] != algorithm) {
      throw const FormatException('Unsupported receipt cipher payload.');
    }

    final keyId = parts[2];
    final nonceText = parts[3];
    final payloadText = parts[4];
    final mac = parts[5];
    final key = _keyProvider.findEncryptionKey(keyId);
    if (key == null) {
      throw const FormatException('Receipt decryption key is unavailable.');
    }

    final expectedMac = _mac(
      key: key,
      keyId: keyId,
      nonceText: nonceText,
      payloadText: payloadText,
    );
    if (!_constantTimeEquals(expectedMac, mac)) {
      throw const FormatException('Receipt cipher authentication failed.');
    }

    try {
      final nonce = base64Decode(nonceText);
      final payload = base64Decode(payloadText);
      final plaintext = _xorWithKeystream(
        data: payload,
        key: key,
        nonce: nonce,
      );
      return utf8.decode(plaintext);
    } on FormatException {
      throw const FormatException('Receipt cipher payload is malformed.');
    }
  }

  static List<int> _secureNonce() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  static List<int> _xorWithKeystream({
    required List<int> data,
    required ReceiptEncryptionKey key,
    required List<int> nonce,
  }) {
    final output = Uint8List(data.length);
    var offset = 0;
    var counter = 0;

    while (offset < data.length) {
      final block = _hmacBytes(
        key.secret,
        'stream:${base64Encode(nonce)}:$counter',
      );
      for (var i = 0; i < block.length && offset < data.length; i++) {
        output[offset] = data[offset] ^ block[i];
        offset += 1;
      }
      counter += 1;
    }

    return output;
  }

  static String _mac({
    required ReceiptEncryptionKey key,
    required String keyId,
    required String nonceText,
    required String payloadText,
  }) {
    return sha256
        .convert(
          _hmacBytes(
            key.secret,
            'mac:$formatVersion:$algorithm:$keyId:$nonceText:$payloadText',
          ),
        )
        .toString();
  }

  static List<int> _hmacBytes(String secret, String payload) {
    return Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(payload)).bytes;
  }

  static bool _constantTimeEquals(String a, String b) {
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

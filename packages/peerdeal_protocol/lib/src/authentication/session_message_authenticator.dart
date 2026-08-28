import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The bounded input authenticated by a session message authenticator.
///
/// The transport frame carries the same scope and sequence values outside the
/// payload. Keeping them in this input binds those values to the authenticated
/// bytes without changing the generic native transport channel.
class SessionAuthenticationInput {
  SessionAuthenticationInput({
    required this.sessionId,
    required this.senderPeerId,
    required this.recipientPeerId,
    required this.sequence,
    required List<int> payload,
  }) : payload = List<int>.unmodifiable(payload);

  final String sessionId;
  final String senderPeerId;
  final String recipientPeerId;
  final int sequence;
  final List<int> payload;
}

/// Computes and verifies an authentication tag for one session message.
///
/// Implementations must fail closed for malformed input. The protocol package
/// owns the message contract; key provisioning and session authorization stay
/// with the app/session integration.
abstract interface class SessionMessageAuthenticator {
  int get tagLength;

  List<int> createTag(SessionAuthenticationInput input);

  bool verifyTag(SessionAuthenticationInput input, List<int> tag);
}

/// HMAC-SHA256 authentication for session messages.
///
/// A 256-bit minimum key is required so a production route cannot silently
/// downgrade to a weak or empty shared secret.
class HmacSha256SessionMessageAuthenticator
    implements SessionMessageAuthenticator {
  HmacSha256SessionMessageAuthenticator({required List<int> key})
    : _key = List<int>.unmodifiable(key) {
    if (_key.length < minimumKeyBytes || _key.length > maximumKeyBytes) {
      throw ArgumentError.value(
        key.length,
        'key',
        'Session authentication key must be between 32 and 4096 bytes.',
      );
    }
    if (_key.any((value) => value < 0 || value > 255)) {
      throw ArgumentError.value(
        key,
        'key',
        'Session authentication key must contain byte values.',
      );
    }
  }

  static const minimumKeyBytes = 32;
  static const maximumKeyBytes = 4096;
  static const algorithm = 'hmac-sha256';
  static const _tagLength = 32;

  final List<int> _key;

  @override
  int get tagLength => _tagLength;

  @override
  List<int> createTag(SessionAuthenticationInput input) {
    _validateInput(input);
    return Hmac(sha256, _key).convert(_authenticationBytes(input)).bytes;
  }

  @override
  bool verifyTag(SessionAuthenticationInput input, List<int> tag) {
    if (tag.length != tagLength) return false;
    try {
      final expected = createTag(input);
      var difference = 0;
      for (var index = 0; index < expected.length; index++) {
        difference |= expected[index] ^ tag[index];
      }
      return difference == 0;
    } on Object {
      return false;
    }
  }

  void _validateInput(SessionAuthenticationInput input) {
    _validateIdentity(input.sessionId, 'sessionId');
    _validateIdentity(input.senderPeerId, 'senderPeerId');
    _validateIdentity(input.recipientPeerId, 'recipientPeerId');
    if (input.sequence < 0 || input.sequence > _maximumInt64) {
      throw ArgumentError.value(
        input.sequence,
        'sequence',
        'Session authentication sequence must be a non-negative int64.',
      );
    }
    if (input.payload.isEmpty ||
        input.payload.length >
            SessionAuthenticatedPayloadCodec.maxPayloadBytes ||
        input.payload.any((value) => value < 0 || value > 255)) {
      throw ArgumentError.value(
        input.payload.length,
        'payload',
        'Session authentication payload is outside its byte bounds.',
      );
    }
  }

  static void _validateIdentity(String value, String fieldName) {
    final bytes = utf8.encode(value);
    if (value.isEmpty ||
        value.trim() != value ||
        value.codeUnits.any(
          (unit) => unit <= 0x20 || (unit >= 0x7f && unit <= 0x9f),
        ) ||
        utf8.decode(bytes, allowMalformed: false) != value ||
        bytes.length > SessionAuthenticationLimits.maxIdentityBytes) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Session authentication identity is invalid.',
      );
    }
  }

  static const _maximumInt64 = 0x7fffffffffffffff;

  static List<int> _authenticationBytes(SessionAuthenticationInput input) {
    final output = BytesBuilder(copy: false)
      ..add(const <int>[0x50, 0x65, 0x65, 0x72, 0x44, 0x65, 0x61, 0x6c])
      ..addByte(1);
    _addString(output, input.sessionId);
    _addString(output, input.senderPeerId);
    _addString(output, input.recipientPeerId);
    final sequence = ByteData(8)..setInt64(0, input.sequence, Endian.big);
    output.add(sequence.buffer.asUint8List());
    _addBytes(output, input.payload);
    return output.takeBytes();
  }

  static void _addString(BytesBuilder output, String value) {
    _addBytes(output, utf8.encode(value));
  }

  static void _addBytes(BytesBuilder output, List<int> bytes) {
    final length = ByteData(4)..setUint32(0, bytes.length, Endian.big);
    output.add(length.buffer.asUint8List());
    output.add(bytes);
  }
}

/// Bounded limits shared by the authenticated session payload contract.
class SessionAuthenticationLimits {
  const SessionAuthenticationLimits._();

  static const maxIdentityBytes = 256;
  static const maxTagBytes = 64;
  static const maxEnvelopeBytes = 64 * 1024;
}

/// Wraps an application payload with a versioned authentication tag.
///
/// Wire format: four-byte magic, one-byte version, one-byte tag length,
/// authentication tag, then the original payload. The frame's session and
/// peer fields are authenticated as associated data and are not duplicated in
/// this opaque payload.
class SessionAuthenticatedPayloadCodec {
  const SessionAuthenticatedPayloadCodec._();

  static const maxPayloadBytes =
      SessionAuthenticationLimits.maxEnvelopeBytes -
      6 -
      SessionAuthenticationLimits.maxTagBytes;
  static const _magic = <int>[0x50, 0x44, 0x41, 0x31];
  static const _version = 1;
  static const _headerBytes = 6;

  static List<int> encode({
    required SessionAuthenticationInput input,
    required SessionMessageAuthenticator authenticator,
  }) {
    if (authenticator.tagLength < 1 ||
        authenticator.tagLength > SessionAuthenticationLimits.maxTagBytes) {
      throw ArgumentError.value(
        authenticator.tagLength,
        'authenticator',
        'Session authentication tag length is outside its byte bounds.',
      );
    }
    if (input.payload.length > maxPayloadBytes) {
      throw FormatException('Session authentication payload is too large.');
    }
    final tag = authenticator.createTag(input);
    if (tag.length != authenticator.tagLength ||
        tag.any((value) => value < 0 || value > 255)) {
      throw FormatException('Session authentication tag is malformed.');
    }
    return <int>[..._magic, _version, tag.length, ...tag, ...input.payload];
  }

  static List<int> decode({
    required List<int> encoded,
    required String sessionId,
    required String senderPeerId,
    required String recipientPeerId,
    required int sequence,
    required SessionMessageAuthenticator authenticator,
  }) {
    if (encoded.length < _headerBytes ||
        encoded.length > SessionAuthenticationLimits.maxEnvelopeBytes ||
        encoded.any((value) => value < 0 || value > 255)) {
      throw const FormatException(
        'Session authentication envelope is invalid.',
      );
    }
    for (var index = 0; index < _magic.length; index++) {
      if (encoded[index] != _magic[index]) {
        throw const FormatException(
          'Session authentication version is invalid.',
        );
      }
    }
    if (encoded[4] != _version) {
      throw const FormatException('Session authentication version is invalid.');
    }
    final tagLength = encoded[5];
    if (tagLength != authenticator.tagLength ||
        tagLength < 1 ||
        tagLength > SessionAuthenticationLimits.maxTagBytes ||
        encoded.length <= _headerBytes + tagLength) {
      throw const FormatException('Session authentication tag is invalid.');
    }
    final tag = encoded.sublist(_headerBytes, _headerBytes + tagLength);
    final payload = encoded.sublist(_headerBytes + tagLength);
    if (payload.length > maxPayloadBytes || payload.isEmpty) {
      throw const FormatException('Session authentication payload is invalid.');
    }
    final input = SessionAuthenticationInput(
      sessionId: sessionId,
      senderPeerId: senderPeerId,
      recipientPeerId: recipientPeerId,
      sequence: sequence,
      payload: payload,
    );
    if (!authenticator.verifyTag(input, tag)) {
      throw const FormatException(
        'Session authentication tag verification failed.',
      );
    }
    return List<int>.unmodifiable(payload);
  }
}

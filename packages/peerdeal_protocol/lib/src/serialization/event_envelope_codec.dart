import 'dart:convert';

import '../models/event_envelope.dart';
import 'canonical_json.dart';
import 'canonical_json_limits.dart';

class EventEnvelopeCodec {
  const EventEnvelopeCodec({this.maxBytes = 64 * 1024});

  final int maxBytes;

  List<int> encode(EventEnvelope event) {
    _validateLimit();
    try {
      final bytes = utf8.encode(
        canonicalJsonEncode(
          event.toJson(),
          limits: CanonicalJsonLimits(maxEncodedBytes: maxBytes),
        ),
      );
      _ensureWithinLimit(bytes.length);
      return List<int>.unmodifiable(bytes);
    } on FormatException catch (error) {
      if (error.message == 'Canonical JSON payload is too large.') {
        throw const FormatException(
          'Event envelope wire payload is too large.',
        );
      }
      rethrow;
    } on Object {
      throw const FormatException('Event envelope wire encoding failed.');
    }
  }

  EventEnvelope decode(Iterable<int> bytes) {
    _validateLimit();
    final raw = <int>[];
    for (final byte in bytes) {
      if (raw.length == maxBytes) {
        _ensureWithinLimit(raw.length + 1);
      }
      raw.add(byte);
    }
    if (raw.isEmpty) {
      throw const FormatException('Event envelope wire payload is empty.');
    }
    _ensureWithinLimit(raw.length);

    try {
      final decoded = jsonDecode(utf8.decode(raw, allowMalformed: false));
      if (decoded is! Map) {
        throw const FormatException(
          'Event envelope wire payload is not an object.',
        );
      }
      canonicalJsonEncode(
        decoded,
        limits: CanonicalJsonLimits(maxEncodedBytes: maxBytes),
      );
      return EventEnvelope.fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      throw const FormatException('Event envelope wire payload is malformed.');
    } on Object {
      throw const FormatException('Event envelope wire payload is malformed.');
    }
  }

  void _validateLimit() {
    if (maxBytes < 1) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be positive');
    }
  }

  void _ensureWithinLimit(int length) {
    if (length > maxBytes) {
      throw const FormatException('Event envelope wire payload is too large.');
    }
  }
}

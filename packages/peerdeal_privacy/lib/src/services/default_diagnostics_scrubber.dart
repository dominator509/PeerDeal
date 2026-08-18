import 'dart:convert';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/diagnostics_scrubber.dart';
import '../models/scrubbed_diagnostics.dart';

class DefaultDiagnosticsScrubber implements DiagnosticsScrubber {
  const DefaultDiagnosticsScrubber();

  static const maxMapEntries = 64;
  static const maxListItems = 64;
  static const maxDepth = 8;
  static const maxTextBytes = 512;
  static const maxProtocolDiagnostics = 64;

  static const _truncated = '<truncated>';
  static const _truncationKey = '<truncated>';
  static final _truncationDiagnostic = ProtocolDiagnostic(
    code: 'ERR_DIAGNOSTICS_TRUNCATED',
    message: 'Diagnostics were truncated.',
  );

  static const _redact = <String>{
    'invite_code',
    'receipt_token',
    'private_key',
    'session_secret',
    'ip_address',
    'device_identifier',
  };

  @override
  ScrubbedDiagnostics scrub(Map<String, Object?> input) {
    final redacted = <String>[];
    final payload = _scrubMap(input, redacted, const <String>[], 0);

    return ScrubbedDiagnostics(
      rawKeysRemoved: redacted.length,
      redactedFields: redacted,
      payload: payload,
    );
  }

  @override
  ProtocolDiagnostic scrubProtocolDiagnostic(ProtocolDiagnostic diagnostic) {
    return ProtocolDiagnostic(
      code: _boundedText(diagnostic.code),
      message: _boundedText(diagnostic.message),
      expected: diagnostic.expected == null ? null : '<redacted>',
      actual: diagnostic.actual == null ? null : '<redacted>',
    );
  }

  @override
  List<ProtocolDiagnostic> scrubProtocolDiagnostics(
    Iterable<ProtocolDiagnostic> diagnostics,
  ) {
    final scrubbed = <ProtocolDiagnostic>[];
    final iterator = diagnostics.iterator;
    while (iterator.moveNext()) {
      if (scrubbed.length == maxProtocolDiagnostics - 1) {
        if (iterator.moveNext()) {
          scrubbed.add(_truncationDiagnostic);
        } else {
          scrubbed.add(scrubProtocolDiagnostic(iterator.current));
        }
        break;
      }
      scrubbed.add(scrubProtocolDiagnostic(iterator.current));
    }
    return scrubbed.toList(growable: false);
  }

  Map<String, Object?> _scrubMap(
    Map<Object?, Object?> input,
    List<String> redacted,
    List<String> path,
    int depth,
  ) {
    final payload = <String, Object?>{};
    final dataEntryLimit = input.length > maxMapEntries
        ? maxMapEntries - 1
        : maxMapEntries;
    var entriesSeen = 0;

    for (final entry in input.entries) {
      if (entriesSeen == dataEntryLimit) {
        payload[_truncationKey] = _truncated;
        break;
      }
      entriesSeen += 1;

      final rawField = entry.key is String ? entry.key as String : '';
      final safeField = _isSafeField(rawField);
      final field = safeField ? rawField : _truncated;
      final nextPath = <String>[...path, field];

      if (!safeField || _redact.contains(rawField.toLowerCase())) {
        payload[field] = '<redacted>';
        if (redacted.length < maxMapEntries) {
          redacted.add(_boundedText(nextPath.join('.')));
        }
      } else {
        payload[field] = _scrubValue(entry.value, redacted, nextPath, depth);
      }
    }

    return payload;
  }

  Object? _scrubValue(
    Object? value,
    List<String> redacted,
    List<String> path,
    int depth,
  ) {
    if (depth >= maxDepth &&
        (value is Map<Object?, Object?> || value is Iterable<Object?>)) {
      return _truncated;
    }

    if (value is Map<Object?, Object?>) {
      return _scrubMap(value, redacted, path, depth + 1);
    }

    if (value is Iterable<Object?>) {
      final scrubbed = <Object?>[];
      final iterator = value.iterator;
      while (iterator.moveNext()) {
        if (scrubbed.length == maxListItems - 1) {
          if (iterator.moveNext()) {
            scrubbed.add(_truncated);
          } else {
            scrubbed.add(
              _scrubValue(iterator.current, redacted, <String>[
                ...path,
                '[]',
              ], depth + 1),
            );
          }
          break;
        }
        scrubbed.add(
          _scrubValue(iterator.current, redacted, <String>[
            ...path,
            '[]',
          ], depth + 1),
        );
      }
      return scrubbed.toList(growable: false);
    }

    if (value is String) return _boundedText(value);
    return value;
  }

  String _boundedText(String value) {
    return utf8.encode(value).length <= maxTextBytes &&
            !_containsControlCharacter(value)
        ? value
        : _truncated;
  }

  bool _isSafeField(String value) {
    return value.isNotEmpty &&
        value.trim() == value &&
        utf8.encode(value).length <= maxTextBytes &&
        !_containsControlCharacter(value);
  }

  bool _containsControlCharacter(String value) {
    return value.codeUnits.any(
      (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
    );
  }
}

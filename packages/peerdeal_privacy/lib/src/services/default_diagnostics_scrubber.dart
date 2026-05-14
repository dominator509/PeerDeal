import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/diagnostics_scrubber.dart';
import '../models/scrubbed_diagnostics.dart';

class DefaultDiagnosticsScrubber implements DiagnosticsScrubber {
  const DefaultDiagnosticsScrubber();

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
    final payload = _scrubMap(input, redacted, const <String>[]);

    return ScrubbedDiagnostics(
      rawKeysRemoved: redacted.length,
      redactedFields: redacted,
      payload: payload,
    );
  }

  @override
  ProtocolDiagnostic scrubProtocolDiagnostic(ProtocolDiagnostic diagnostic) {
    return ProtocolDiagnostic(
      code: diagnostic.code,
      message: diagnostic.message,
      expected: diagnostic.expected == null ? null : '<redacted>',
      actual: diagnostic.actual == null ? null : '<redacted>',
    );
  }

  @override
  List<ProtocolDiagnostic> scrubProtocolDiagnostics(
    Iterable<ProtocolDiagnostic> diagnostics,
  ) {
    return diagnostics.map(scrubProtocolDiagnostic).toList(growable: false);
  }

  Map<String, Object?> _scrubMap(
    Map<Object?, Object?> input,
    List<String> redacted,
    List<String> path,
  ) {
    final payload = <String, Object?>{};

    input.forEach((key, value) {
      final field = key.toString();
      final nextPath = <String>[...path, field];

      if (_redact.contains(field)) {
        payload[field] = '<redacted>';
        redacted.add(nextPath.join('.'));
      } else {
        payload[field] = _scrubValue(value, redacted, nextPath);
      }
    });

    return payload;
  }

  Object? _scrubValue(Object? value, List<String> redacted, List<String> path) {
    if (value is Map<Object?, Object?>) {
      return _scrubMap(value, redacted, path);
    }

    if (value is Iterable<Object?>) {
      return value
          .map((item) => _scrubValue(item, redacted, <String>[...path, '[]']))
          .toList(growable: false);
    }

    return value;
  }
}

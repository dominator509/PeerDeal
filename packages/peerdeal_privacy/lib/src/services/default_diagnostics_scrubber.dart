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
    final payload = <String, Object?>{};
    final redacted = <String>[];
    var removed = 0;

    input.forEach((key, value) {
      if (_redact.contains(key)) {
        payload[key] = '<redacted>';
        redacted.add(key);
        removed += 1;
      } else {
        payload[key] = value;
      }
    });

    return ScrubbedDiagnostics(
      rawKeysRemoved: removed,
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
}

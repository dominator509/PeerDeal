import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';

void main() {
  test('DefaultDiagnosticsScrubber redacts sensitive operational fields', () {
    const scrubber = DefaultDiagnosticsScrubber();

    final result = scrubber.scrub({
      'error_code': 'ERR_CAPTURE_UNSUPPORTED',
      'receipt_token': 'abc',
      'session_secret': 'def',
      'device_identifier': 'ghi',
    });

    expect(result.rawKeysRemoved, 3);
    expect(result.payload['receipt_token'], '<redacted>');
    expect(result.payload['session_secret'], '<redacted>');
    expect(result.payload['device_identifier'], '<redacted>');
    expect(result.payload['error_code'], 'ERR_CAPTURE_UNSUPPORTED');
  });

  test('DefaultDiagnosticsScrubber redacts nested sensitive fields', () {
    const scrubber = DefaultDiagnosticsScrubber();

    final result = scrubber.scrub(loadFixture('diagnostics_sample.json'));

    expect(result.rawKeysRemoved, 4);
    expect(result.redactedFields, [
      'receipt.receipt_token',
      'peers.[].device_identifier',
      'peers.[].session_secret',
      'peers.[].ip_address',
    ]);
    expect(result.payload, {
      'error_code': 'ERR_RECEIPT_RESTORE_DENIED',
      'receipt': {'receipt_token': '<redacted>', 'status': 'wiped'},
      'peers': [
        {'device_identifier': '<redacted>', 'route': 'lan'},
        {
          'session_secret': '<redacted>',
          'ip_address': '<redacted>',
          'route': 'relay',
        },
      ],
    });
  });

  test('DefaultDiagnosticsScrubber redacts protocol diagnostic details', () {
    const scrubber = DefaultDiagnosticsScrubber();

    final result = scrubber.scrubProtocolDiagnostic(
      const ProtocolDiagnostic(
        code: ProtocolResultCodes.errProtocolIncompatible,
        message: 'Invite protocol version is not supported.',
        expected: '1.0.0',
        actual: '2.0.0',
      ),
    );

    expect(result.toJson(), {
      'code': 'ERR_PROTOCOL_INCOMPATIBLE',
      'message': 'Invite protocol version is not supported.',
      'expected': '<redacted>',
      'actual': '<redacted>',
    });
  });

  test('DefaultDiagnosticsScrubber redacts protocol diagnostic lists', () {
    const scrubber = DefaultDiagnosticsScrubber();

    final result = scrubber.scrubProtocolDiagnostics([
      const ProtocolDiagnostic(
        code: ProtocolResultCodes.errProtocolIncompatible,
        message: 'Invite protocol version is not supported.',
        expected: '1.0.0',
        actual: '2.0.0',
      ),
      const ProtocolDiagnostic(
        code: ProtocolResultCodes.errProtocolIncompatible,
        message: 'No details are still safe.',
      ),
    ]);

    expect(result, hasLength(2));
    expect(result.first.toJson(), {
      'code': 'ERR_PROTOCOL_INCOMPATIBLE',
      'message': 'Invite protocol version is not supported.',
      'expected': '<redacted>',
      'actual': '<redacted>',
    });
    expect(result.last.toJson(), {
      'code': 'ERR_PROTOCOL_INCOMPATIBLE',
      'message': 'No details are still safe.',
    });
  });
}

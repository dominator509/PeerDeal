import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

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

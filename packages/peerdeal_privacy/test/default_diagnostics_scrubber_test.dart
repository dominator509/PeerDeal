import 'package:peerdeal_privacy/peerdeal_privacy.dart';
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
}

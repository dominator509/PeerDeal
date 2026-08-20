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

  test('DefaultDiagnosticsScrubber redacts case-variant sensitive fields', () {
    const scrubber = DefaultDiagnosticsScrubber();

    final result = scrubber.scrub({
      'RECEIPT_TOKEN': 'abc',
      'Session_Secret': 'def',
      'Device_Identifier': 'ghi',
      'IP_ADDRESS': 'jkl',
    });

    expect(result.rawKeysRemoved, 4);
    expect(result.payload['RECEIPT_TOKEN'], '<redacted>');
    expect(result.payload['Session_Secret'], '<redacted>');
    expect(result.payload['Device_Identifier'], '<redacted>');
    expect(result.payload['IP_ADDRESS'], '<redacted>');
  });

  test('DefaultDiagnosticsScrubber redacts common credential field names', () {
    const scrubber = DefaultDiagnosticsScrubber();

    final result = scrubber.scrub({
      'password': 'pw',
      'Authorization': 'Bearer token',
      'access_token': 'access',
      'api_key': 'key',
      'client_secret': 'secret',
      'safe_label': 'diagnostic',
    });

    expect(result.rawKeysRemoved, 5);
    expect(result.payload['password'], '<redacted>');
    expect(result.payload['Authorization'], '<redacted>');
    expect(result.payload['access_token'], '<redacted>');
    expect(result.payload['api_key'], '<redacted>');
    expect(result.payload['client_secret'], '<redacted>');
    expect(result.payload['safe_label'], 'diagnostic');
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
      ProtocolDiagnostic(
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
      ProtocolDiagnostic(
        code: ProtocolResultCodes.errProtocolIncompatible,
        message: 'Invite protocol version is not supported.',
        expected: '1.0.0',
        actual: '2.0.0',
      ),
      ProtocolDiagnostic(
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

  test('DefaultDiagnosticsScrubber redacts unsafe keys and text', () {
    const scrubber = DefaultDiagnosticsScrubber();

    final result = scrubber.scrub({
      'receipt_token\u0000suffix': 'secret-token',
      'message': 'line\nwith-control',
    });

    expect(result.payload['<truncated>'], '<redacted>');
    expect(result.payload['message'], '<truncated>');
    expect(result.rawKeysRemoved, 1);

    final diagnostic = scrubber.scrubProtocolDiagnostic(
      ProtocolDiagnostic(code: 'ERR\u0001CODE', message: 'unsafe\nmessage'),
    );
    expect(diagnostic.code, '<truncated>');
    expect(diagnostic.message, '<truncated>');
  });

  test('DefaultDiagnosticsScrubber bounds maps, lists, depth, and text', () {
    const scrubber = DefaultDiagnosticsScrubber();
    final wideMap = <String, Object?>{
      for (var index = 0; index < 65; index++) 'field_$index': index,
    };
    final wideList = List<Object?>.generate(65, (index) => index);
    final longText = String.fromCharCodes(
      List<int>.filled(DefaultDiagnosticsScrubber.maxTextBytes + 1, 120),
    );
    final malformedText = String.fromCharCode(0xd800);
    Map<String, Object?> nested = <String, Object?>{'leaf': 'value'};
    for (var index = 0; index < DefaultDiagnosticsScrubber.maxDepth; index++) {
      nested = <String, Object?>{'nested': nested};
    }

    final result = scrubber.scrub({
      'wide_map': wideMap,
      'wide_list': wideList,
      'nested': nested,
      'long_text': longText,
      'malformed_text': malformedText,
    });

    expect(result.payload['wide_map'], isA<Map<Object?, Object?>>());
    expect(
      (result.payload['wide_map']! as Map<Object?, Object?>).length,
      DefaultDiagnosticsScrubber.maxMapEntries,
    );
    expect(
      (result.payload['wide_map']! as Map<Object?, Object?>)['<truncated>'],
      '<truncated>',
    );
    expect(result.payload['wide_list'], isA<List<Object?>>());
    expect(
      (result.payload['wide_list']! as List<Object?>).length,
      DefaultDiagnosticsScrubber.maxListItems,
    );
    expect((result.payload['wide_list']! as List<Object?>).last, '<truncated>');
    expect(result.payload['long_text'], '<truncated>');
    expect(result.payload['malformed_text'], '<truncated>');
    expect(result.payload['nested'], isA<Map<Object?, Object?>>());
    expect(result.payload['nested'].toString(), contains('<truncated>'));
  });

  test('DefaultDiagnosticsScrubber bounds protocol diagnostic lists', () {
    const scrubber = DefaultDiagnosticsScrubber();
    final result = scrubber.scrubProtocolDiagnostics(
      List<ProtocolDiagnostic>.generate(
        DefaultDiagnosticsScrubber.maxProtocolDiagnostics + 1,
        (index) => ProtocolDiagnostic(
          code: 'ERR_$index',
          message: 'Diagnostic $index',
        ),
      ),
    );

    expect(
      result,
      hasLength(DefaultDiagnosticsScrubber.maxProtocolDiagnostics),
    );
    expect(result.last.code, 'ERR_DIAGNOSTICS_TRUNCATED');
  });
}

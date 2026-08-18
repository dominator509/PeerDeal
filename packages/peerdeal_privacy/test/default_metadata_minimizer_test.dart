import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:test/test.dart';

void main() {
  test('DefaultMetadataMinimizer strips device and ip fields when disabled', () {
    const minimizer = DefaultMetadataMinimizer();
    const profile = MetadataMinimizationProfile(
      minimizeMetadata: true,
      exportMinimalIdentity: true,
      allowPseudonymousAliases: true,
      allowDeviceIdentifiers: false,
      allowIpAddressCapture: false,
    );

    final output = minimizer.minimize({
      'pseudonymous_user_id': 'user_123',
      'device_identifier': 'device_abc',
      'ip_address': '10.0.0.1',
      'session_id': 'sess_1',
      'legal_name': 'Dominic Example',
    }, profile);

    expect(output.containsKey('device_identifier'), isFalse);
    expect(output.containsKey('ip_address'), isFalse);
    expect(output.containsKey('legal_name'), isFalse);
    expect(output['session_id'], 'sess_1');
  });

  test('strips case-variant sensitive metadata keys', () {
    const minimizer = DefaultMetadataMinimizer();
    const profile = MetadataMinimizationProfile(
      minimizeMetadata: true,
      exportMinimalIdentity: true,
      allowPseudonymousAliases: true,
      allowDeviceIdentifiers: false,
      allowIpAddressCapture: false,
    );

    final output = minimizer.minimize({
      'Device_Identifier': 'device_abc',
      'IP_ADDRESS': '10.0.0.1',
      'EMAIL': 'person@example.test',
      'safe_label': 'table',
    }, profile);

    expect(output, <String, Object?>{'safe_label': 'table'});
  });
}

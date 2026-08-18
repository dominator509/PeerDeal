import '../contracts/metadata_minimizer.dart';
import '../models/metadata_minimization_profile.dart';

class DefaultMetadataMinimizer implements MetadataMinimizer {
  const DefaultMetadataMinimizer();

  static const _alwaysStrip = <String>{
    'legal_name',
    'email',
    'phone',
    'raw_private_ledger',
  };

  @override
  Map<String, Object?> minimize(
    Map<String, Object?> input,
    MetadataMinimizationProfile profile,
  ) {
    final output = <String, Object?>{};
    for (final entry in input.entries) {
      final key = entry.key;
      final normalizedKey = key.toLowerCase();
      if (_alwaysStrip.contains(normalizedKey)) {
        continue;
      }
      if (!profile.allowDeviceIdentifiers && normalizedKey.contains('device')) {
        continue;
      }
      if (!profile.allowIpAddressCapture && normalizedKey.contains('ip')) {
        continue;
      }
      output[key] = entry.value;
    }
    return output;
  }
}

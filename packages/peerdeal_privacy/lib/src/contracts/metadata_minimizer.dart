import '../models/metadata_minimization_profile.dart';

abstract interface class MetadataMinimizer {
  Map<String, Object?> minimize(
    Map<String, Object?> input,
    MetadataMinimizationProfile profile,
  );
}

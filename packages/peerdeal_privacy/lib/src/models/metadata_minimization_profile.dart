class MetadataMinimizationProfile {
  const MetadataMinimizationProfile({
    required this.minimizeMetadata,
    required this.exportMinimalIdentity,
    required this.allowPseudonymousAliases,
    required this.allowDeviceIdentifiers,
    required this.allowIpAddressCapture,
  });

  final bool minimizeMetadata;
  final bool exportMinimalIdentity;
  final bool allowPseudonymousAliases;
  final bool allowDeviceIdentifiers;
  final bool allowIpAddressCapture;
}

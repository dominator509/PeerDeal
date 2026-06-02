class LocalNetworkCapability {
  const LocalNetworkCapability({
    required this.discoverySupported,
    required this.permissionPromptSupported,
    required this.broadcastSupported,
    required this.notes,
    this.warning,
  });

  const LocalNetworkCapability.unavailable({this.warning})
    : discoverySupported = false,
      permissionPromptSupported = false,
      broadcastSupported = false,
      notes = 'unavailable';

  final bool discoverySupported;
  final bool permissionPromptSupported;
  final bool broadcastSupported;
  final String notes;
  final String? warning;
}

class LocalNetworkDiscoverySnapshot {
  const LocalNetworkDiscoverySnapshot({
    required this.permissionGranted,
    required this.foundEndpoints,
    required this.interfaceHints,
    this.warning,
  });

  const LocalNetworkDiscoverySnapshot.unavailable({this.warning})
    : permissionGranted = false,
      foundEndpoints = const <String>[],
      interfaceHints = const <String>[];

  final bool permissionGranted;
  final List<String> foundEndpoints;
  final List<String> interfaceHints;
  final String? warning;
}

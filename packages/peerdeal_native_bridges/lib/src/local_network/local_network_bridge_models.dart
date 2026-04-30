class LocalNetworkCapability {
  const LocalNetworkCapability({
    required this.discoverySupported,
    required this.permissionPromptSupported,
    required this.broadcastSupported,
    required this.notes,
  });

  final bool discoverySupported;
  final bool permissionPromptSupported;
  final bool broadcastSupported;
  final String notes;
}

class LocalNetworkDiscoverySnapshot {
  const LocalNetworkDiscoverySnapshot({
    required this.permissionGranted,
    required this.foundEndpoints,
    required this.interfaceHints,
    required this.warning,
  });

  final bool permissionGranted;
  final List<String> foundEndpoints;
  final List<String> interfaceHints;
  final String? warning;
}

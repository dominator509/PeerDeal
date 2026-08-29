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
  LocalNetworkDiscoverySnapshot({
    required this.permissionGranted,
    required List<String> foundEndpoints,
    required List<String> interfaceHints,
    this.warning,
  }) : foundEndpoints = List<String>.unmodifiable(foundEndpoints),
       interfaceHints = List<String>.unmodifiable(interfaceHints);

  const LocalNetworkDiscoverySnapshot.unavailable({this.warning})
    : permissionGranted = false,
      foundEndpoints = const <String>[],
      interfaceHints = const <String>[];

  final bool permissionGranted;
  final List<String> foundEndpoints;
  final List<String> interfaceHints;
  final String? warning;
}

class LocalNetworkAnnouncementResult {
  const LocalNetworkAnnouncementResult({required this.published, this.warning});

  const LocalNetworkAnnouncementResult.unavailable({this.warning})
    : published = false;

  final bool published;
  final String? warning;
}

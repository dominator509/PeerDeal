class LanDiscoveryResult {
  LanDiscoveryResult({
    required this.discoveryEnabled,
    required List<String> foundPeerIds,
    required List<String> interfaceHints,
    required this.permissionSatisfied,
    this.warning,
  }) : foundPeerIds = List<String>.unmodifiable(foundPeerIds),
       interfaceHints = List<String>.unmodifiable(interfaceHints);

  final bool discoveryEnabled;
  final List<String> foundPeerIds;
  final List<String> interfaceHints;
  final bool permissionSatisfied;
  final String? warning;
}

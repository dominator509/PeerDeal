class LanDiscoveryResult {
  const LanDiscoveryResult({
    required this.discoveryEnabled,
    required this.foundPeerIds,
    required this.interfaceHints,
    required this.permissionSatisfied,
    this.warning,
  });

  final bool discoveryEnabled;
  final List<String> foundPeerIds;
  final List<String> interfaceHints;
  final bool permissionSatisfied;
  final String? warning;
}

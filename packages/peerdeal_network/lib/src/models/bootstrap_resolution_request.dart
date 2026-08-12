class BootstrapResolutionRequest {
  BootstrapResolutionRequest({
    required this.sessionId,
    required this.tableId,
    required this.preferLan,
    required this.relayAllowed,
    required List<String> peerIds,
  }) : peerIds = List<String>.unmodifiable(peerIds);

  final String sessionId;
  final String tableId;
  final bool preferLan;
  final bool relayAllowed;
  final List<String> peerIds;
}

class BootstrapResolutionRequest {
  const BootstrapResolutionRequest({
    required this.sessionId,
    required this.tableId,
    required this.preferLan,
    required this.relayAllowed,
    required this.peerIds,
  });

  final String sessionId;
  final String tableId;
  final bool preferLan;
  final bool relayAllowed;
  final List<String> peerIds;
}

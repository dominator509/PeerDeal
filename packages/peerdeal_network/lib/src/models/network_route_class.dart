enum NetworkRouteClass {
  lanDirect,
  remoteDirect,
  relayFallback,
  p2pRemote,
  relay,
}

extension NetworkRouteClassSemantics on NetworkRouteClass {
  bool get isLanDirect => this == NetworkRouteClass.lanDirect;

  bool get isRemoteDirect =>
      this == NetworkRouteClass.remoteDirect ||
      this == NetworkRouteClass.p2pRemote;

  bool get isRelay =>
      this == NetworkRouteClass.relayFallback ||
      this == NetworkRouteClass.relay;

  int get selectionRank {
    if (isLanDirect) return 0;
    if (isRemoteDirect) return 1;
    return 2;
  }
}

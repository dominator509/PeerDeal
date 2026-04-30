import 'network_route_class.dart';

class BootstrapCandidate {
  const BootstrapCandidate({
    required this.peerId,
    required this.routeClass,
    required this.reachable,
    required this.priority,
    this.host,
    this.port,
    this.reason,
  });

  final String peerId;
  final NetworkRouteClass routeClass;
  final bool reachable;
  final int priority;
  final String? host;
  final int? port;
  final String? reason;
}

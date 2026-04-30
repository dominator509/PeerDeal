import 'network_route_class.dart';

class SessionPathDescriptor {
  const SessionPathDescriptor({
    required this.routeClass,
    required this.primaryPeerId,
    required this.usesRelay,
    required this.transportAgnostic,
    required this.reason,
  });

  final NetworkRouteClass routeClass;
  final String primaryPeerId;
  final bool usesRelay;
  final bool transportAgnostic;
  final String reason;
}

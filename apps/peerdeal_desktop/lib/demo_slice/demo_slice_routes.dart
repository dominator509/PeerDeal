class DemoSliceRoutes {
  static const home = '/demo';
  static const table = '/demo/table';
  static const chat = '/demo/chat';
  static const receipt = '/demo/receipt';
  static const join = '/demo/join';
  static const setup = '/demo/setup';

  static const homeRoute = DemoSliceRouteDefinition(
    path: home,
    label: 'Home',
    surface: 'Demo home',
  );
  static const tableRoute = DemoSliceRouteDefinition(
    path: table,
    label: 'Table',
    surface: 'Table',
  );
  static const chatRoute = DemoSliceRouteDefinition(
    path: chat,
    label: 'Chat',
    surface: 'Chat',
  );
  static const receiptRoute = DemoSliceRouteDefinition(
    path: receipt,
    label: 'Receipt',
    surface: 'Receipt',
  );
  static const joinRoute = DemoSliceRouteDefinition(
    path: join,
    label: 'Join',
    surface: 'Join flow',
  );
  static const setupRoute = DemoSliceRouteDefinition(
    path: setup,
    label: 'Setup',
    surface: 'Setup flow',
  );

  static const mountedRoutes = <DemoSliceRouteDefinition>[
    homeRoute,
    tableRoute,
    chatRoute,
    receiptRoute,
    joinRoute,
    setupRoute,
  ];

  static const primaryNavigation = <DemoSliceRouteDefinition>[
    tableRoute,
    chatRoute,
    receiptRoute,
    joinRoute,
    setupRoute,
  ];

  static DemoSliceRouteDefinition? tryByPath(String path) {
    for (final route in mountedRoutes) {
      if (route.path == path) return route;
    }
    return null;
  }

  static Map<String, T> requireMountedRouteMap<T>(
    Map<String, T> routes, {
    Set<String> allowedExtraPaths = const <String>{},
  }) {
    final mountedPaths = mountedRoutes.map((route) => route.path).toSet();
    final routePaths = routes.keys.toSet();
    final missingPaths = mountedPaths.difference(routePaths).toList()..sort();
    final extraPaths =
        routePaths
            .difference(mountedPaths)
            .difference(allowedExtraPaths)
            .toList()
          ..sort();

    if (missingPaths.isNotEmpty || extraPaths.isNotEmpty) {
      throw StateError(
        'Mounted demo route map drifted from route registry. '
        'Missing: ${missingPaths.join(', ')}. '
        'Extra: ${extraPaths.join(', ')}.',
      );
    }

    return Map<String, T>.unmodifiable(routes);
  }
}

class DemoSliceRouteDefinition {
  const DemoSliceRouteDefinition({
    required this.path,
    required this.label,
    required this.surface,
  });

  final String path;
  final String label;
  final String surface;
}

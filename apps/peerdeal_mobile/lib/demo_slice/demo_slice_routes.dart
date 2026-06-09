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

  static List<DemoSliceRouteDefinition> enabledMountedRoutes(
    Set<String>? enabledRoutePaths,
  ) {
    _validateRouteRegistry();
    if (enabledRoutePaths == null) return mountedRoutes;

    final malformedPaths = enabledRoutePaths
        .where((path) => path.trim().isEmpty || path.trim() != path)
        .toList(growable: false);

    if (malformedPaths.isNotEmpty) {
      throw StateError('Enabled demo route paths contain malformed routes.');
    }

    final requestedPaths = enabledRoutePaths.toSet();
    final mountedPaths = mountedRoutes.map((route) => route.path).toSet();
    final unknownPaths = requestedPaths.difference(mountedPaths).toList()
      ..sort();

    if (unknownPaths.isNotEmpty) {
      throw StateError(
        'Enabled demo route paths contain unknown routes: '
        '${unknownPaths.join(', ')}.',
      );
    }
    if (!requestedPaths.contains(home)) {
      throw StateError('Enabled demo route paths must include the home route.');
    }

    return mountedRoutes
        .where((route) => requestedPaths.contains(route.path))
        .toList(growable: false);
  }

  static List<DemoSliceRouteDefinition> enabledPrimaryNavigation(
    Set<String>? enabledRoutePaths,
  ) {
    final enabledPaths = enabledMountedRoutes(
      enabledRoutePaths,
    ).map((route) => route.path).toSet();
    return primaryNavigation
        .where((route) => enabledPaths.contains(route.path))
        .toList(growable: false);
  }

  static Map<String, T> requireMountedRouteMap<T>(
    Map<String, T> routes, {
    List<DemoSliceRouteDefinition>? expectedRoutes,
    Set<String> allowedExtraPaths = const <String>{},
  }) {
    _validateRouteRegistry();

    final mountedPaths = (expectedRoutes ?? mountedRoutes)
        .map((route) => route.path)
        .toSet();
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

  static void _validateRouteRegistry() {
    final registryError = _routeRegistryError();
    if (registryError != null) {
      throw StateError(registryError);
    }
  }

  static String? _routeRegistryError() {
    if (mountedRoutes.isEmpty || mountedRoutes.first.path != home) {
      return 'Mounted demo route registry must start with the home route.';
    }

    final mountedPaths = <String>{};
    final labels = <String>{};
    final surfaces = <String>{};
    for (final route in mountedRoutes) {
      final path = route.path;
      if (!_isCanonicalMountedPath(path)) {
        return 'Mounted demo route registry contains a non-canonical path.';
      }
      if (route.label.trim().isEmpty || route.surface.trim().isEmpty) {
        return 'Mounted demo route registry contains empty route metadata.';
      }
      if (!mountedPaths.add(path) ||
          !labels.add(route.label) ||
          !surfaces.add(route.surface)) {
        return 'Mounted demo route registry contains duplicate metadata.';
      }
    }

    for (final route in primaryNavigation) {
      if (route.path == home || !mountedPaths.contains(route.path)) {
        return 'Primary demo navigation must reference mounted non-home routes.';
      }
    }

    return null;
  }

  static bool _isCanonicalMountedPath(String path) {
    return path.startsWith('/demo') &&
        !path.endsWith('/') &&
        !path.contains('?') &&
        !path.contains('#') &&
        !path.contains('//');
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
